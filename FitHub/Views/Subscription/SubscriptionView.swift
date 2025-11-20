import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var ctx: AppContext
    @Environment(\.openURL) private var openURL
    @StateObject private var kbd = KeyboardManager.shared
    @State private var selectedProductID: String?
    @State private var referralCode: String = ""
    @State private var hasClaimedCode: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                
                if let banner = lifetimeCancellationBannerConfig {
                    SubscriptionWarningBanner(message: banner.message) {
                        manageSubscriptions(openURL: openURL)
                    }
                }
                    
                referralCodeSection

                plansSection
                
                if let note = autoRenewFootnote {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    if isCurrentSelection {
                        Text("You’re already on this plan.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    RectangularButton(
                        title: "Continue",
                        systemImage: "arrow.forward.circle.fill",
                        enabled: isCheckoutEnabled,
                        action: purchaseSelected
                    )

                    HStack(spacing: 12) {
                        // FIXME: this doesnt even do anything. this is likely because we're working with a dev version
                        Button("Restore") { Task { await ctx.store.restore() } }
                            .buttonStyle(.bordered)

                        if showsManageButton {
                            Button("Manage") { manageSubscriptions(openURL: openURL) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
                    
                Spacer()
            }
            .padding()
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("FitHub Pro", displayMode: .inline)
        .task {
            if ctx.store.products.isEmpty { await ctx.store.configure() }
            selectCurrentOrDefault()
        }
        .alert("Purchase Error",
               isPresented: Binding(
                get: { ctx.store.errorMessage != nil },
                set: { _ in ctx.store.errorMessage = nil }
               ),
               actions: { Button("OK", role: .cancel) {} },
               message: { Text(ctx.store.errorMessage ?? "") }
        )
        .overlay {
            if ctx.store.isLoading || ctx.store.purchaseInFlight {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Sections
    
    private var referralCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Referral Code")
                .font(.headline)
            
        TextField("Referral Code (Optional)", text: $referralCode)
            .textContentType(.none)
            .autocapitalization(.allCharacters)
            .autocorrectionDisabled()
            .trailingIconButton(systemName: "lock.fill", isShowing: hasClaimedCode)
            .inputStyle()
            .disabled(hasClaimedCode)
            .task {
                if let claimed = await ReferralRetriever.getClaimedCode() {
                    referralCode = claimed
                    hasClaimedCode = true
                } else {
                    hasClaimedCode = false
                }
            }
            .onChange(of: referralCode) { _, newValue in
                guard !hasClaimedCode else { return }
                let trimmed = newValue.trimmed.uppercased()
                if trimmed.isEmpty {
                    UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                } else if ReferralCodeGenerator.isValidCode(trimmed) {
                    UserDefaults.standard.set(trimmed, forKey: "pendingReferralCode")
                }
            }
        }
    }

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose a plan")
                .font(.headline)
            
            ForEach(orderedProducts, id: \.id) { p in
                let mt = PremiumStore.MembershipType.from(productID: p.id)

                PlanCard(
                    title: PremiumStore.ID.displayTitle(for: p.id),
                    priceTrailing: mt.trailingPriceText(for: p),
                    badge: PremiumStore.ID.badge(for: p.id),
                    selected: selectedProductID == p.id,
                    isCurrent: currentProductID == p.id,
                    onTap: { selectedProductID = p.id }   // tappable regardless of tier
                )
            }
        }
    }

    // MARK: - Derived

    private var orderedProducts: [Product] {
        PremiumStore.ID.displayOrder.compactMap { id in
            ctx.store.products.first(where: { $0.id == id })
        }
    }

    private var selectedProduct: Product? {
        guard let id = selectedProductID else { return nil }
        return ctx.store.products.first(where: { $0.id == id })
    }

    private var currentMembership: PremiumStore.MembershipType { ctx.store.membershipType }

    private var currentProductID: String? { currentMembership.productID }

    private var isCurrentSelection: Bool {
        guard let sel = selectedProductID else { return false }
        return sel == currentProductID
    }

    private var showsManageButton: Bool { currentMembership.isSubscription }

    private var autoRenewFootnote: String? {
        guard let product = selectedProduct else { return nil }
        return ctx.store.autoRenewFootnote(for: product)
    }

    private var lifetimeCancellationBannerConfig: LifetimeCancellationBannerConfig? {
        guard ctx.store.membershipType == .lifetime,
              let overlap = ctx.store.overlappingSubscriptionInfo else { return nil }
       
        guard let willRenew = overlap.willAutoRenew, willRenew else { return nil }

        let planName = overlap.type.displayName
        let message: String
        if let expiration = overlap.expiration {
            let formatted = Format.formatDate(expiration, dateStyle: .medium, timeStyle: .short)
            message = "Your \(planName) subscription is still scheduled to renew on \(formatted). Tap Manage to cancel it and avoid future charges."
        } else {
            message = "Your \(planName) subscription is still set to auto-renew. Tap Manage to cancel it and avoid future charges."
        }
        return LifetimeCancellationBannerConfig(message: message)
    }

    private var isCheckoutEnabled: Bool {
        guard let sel = selectedProductID else { return false }
        let selType = PremiumStore.MembershipType.from(productID: sel)
        return !ctx.store.purchaseInFlight
            && !isCurrentSelection
            && selType >= currentMembership        // block downgrades here
    }

    // MARK: - Actions

    /// Prefer selecting the user's current membership if available.
    /// Otherwise, select the first plan whose rank >= current membership.
    /// Finally, fall back to the first available product.
    private func selectCurrentOrDefault() {
        // 1) select exact current product if visible
        if let curr = currentProductID,
           ctx.store.products.contains(where: { $0.id == curr }) {
            selectedProductID = curr
            return
        }

        // 2) pick first product that is same-or-higher rank than current
        for p in orderedProducts {
            let mt = PremiumStore.MembershipType.from(productID: p.id)
            if mt >= currentMembership {
                selectedProductID = p.id
                return
            }
        }

        // 3) fallback to the first available
        selectedProductID = orderedProducts.first?.id
    }

    private func purchaseSelected() {
        guard let id = selectedProductID,
              let product = ctx.store.products.first(where: { $0.id == id }) else { return }

        // Double-guard: never allow downgrades
        guard PremiumStore.MembershipType.from(productID: id) >= currentMembership else { return }

        // Ensure purchase is called on main actor with proper view context
        Task { @MainActor in
            await ctx.store.buy(product: product)
        }
    }

    private func manageSubscriptions(openURL: OpenURLAction) {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            openURL(url)
        }
    }
}

// MARK: - PlanCard (button shows visual selection)

private struct PlanCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let priceTrailing: String
    let badge: String?
    let selected: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .imageScale(.large)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title).fontWeight(.semibold)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.15)))
                        }
                        if isCurrent {
                            Text("Current")
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.18)))
                        }
                    }
                    Text(priceTrailing)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "chevron.right")
                        .opacity(0.25)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected
                          ? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.blue.opacity(0.08))
                          : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }
}

private struct LifetimeCancellationBannerConfig {
    let message: String
}

private struct SubscriptionWarningBanner: View {
    let message: String
    let manageAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.orange)
                    .imageScale(.large)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Button {
                manageAction()
            } label: {
                Label("Manage Subscription", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
}


/*
// MARK: - FeatureRow (unchanged)

private var featuresSection: some View {
    VStack(alignment: .leading, spacing: 10) {
        FeatureRow(icon: "chart.bar", title: "Automatic Progressive Overloading", description: "Automatically increase weights based on performance.")
        FeatureRow(icon: "wand.and.stars", title: "Automated Workout Generation", description: "Personalized plans tailored to your goals.")
        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Charts", description: "Visualize strength and volume trends.")
        FeatureRow(icon: "ruler", title: "Body Measurements", description: "Track your physique changes.")
        //vFeatureRow(icon: "figure.wave", title: "Recovery Visualization", description: "Manage fatigue across muscle groups.")
        Text("And much more…").fontWeight(.semibold)
    }
    .padding()
    .background(.background, in: RoundedRectangle(cornerRadius: 12))
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(.blue)
                .imageScale(.medium).padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}
*/
