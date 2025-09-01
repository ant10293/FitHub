import SwiftUI
import StoreKit
import UIKit

struct SubscriptionView: View {
    @EnvironmentObject var ctx: AppContext
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedProductID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                //ctx.store.statusLabel
                Spacer()
                
                plansSection     // ← combined Monthly / Annual / Lifetime with selection + footnote

                // Actions
                VStack(spacing: 12) {
                    if isCurrentSelection {
                        Text("You’re already on this plan.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    ActionButton(
                        title: "Continue",
                        systemImage: "arrow.forward.circle.fill",
                        enabled: (selectedProductID != nil) && !ctx.store.purchaseInFlight && !isCurrentSelection,
                        action: purchaseSelected
                    )

                    HStack(spacing: 12) {
                        Button("Restore Purchases") { Task { await ctx.store.restore() } }
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
        .navigationBarTitle("FitHub Pro", displayMode: .inline)
        .background(Color(.systemGray6))
        .task {
            if ctx.store.products.isEmpty { await ctx.store.configure() }
            maybeSelectDefault()
        }
        .alert("Purchase Error", isPresented:
            Binding(
                get: { ctx.store.errorMessage != nil },
                set: { _ in ctx.store.errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ctx.store.errorMessage ?? "")
        }
        .overlay {
            if ctx.store.isLoading || ctx.store.purchaseInFlight {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func maybeSelectDefault() {
        guard selectedProductID == nil else { return }
        if ctx.store.products.contains(where: { $0.id == PremiumStore.ID.yearly }) {
            selectedProductID = PremiumStore.ID.yearly
        } else if ctx.store.products.contains(where: { $0.id == PremiumStore.ID.monthly }) {
            selectedProductID = PremiumStore.ID.monthly
        } else if ctx.store.products.contains(where: { $0.id == PremiumStore.ID.lifetime }) {
            selectedProductID = PremiumStore.ID.lifetime
        }
    }

    // MARK: - Plans (Monthly / Annual / Lifetime) + footnote

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your plan").font(.headline)

            if orderedProducts.isEmpty {
                // Placeholder while loading
                VStack(spacing: 10) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 56)
                    }
                }
                .redacted(reason: .placeholder)
            } else {
                VStack(spacing: 10) {
                    ForEach(orderedProducts, id: \.id) { p in
                        PlanCard(
                            title: displayTitle(for: p.id),
                            priceTrailing: trailingPriceText(for: p),
                            badge: badge(for: p.id),
                            selected: selectedProductID == p.id,
                            isCurrent: currentProductID == p.id,
                            onTap: { selectedProductID = p.id }
                        )
                    }
                }

                // ⤵️ Auto-renew footnote for Monthly / Annual
                if let note = autoRenewFootnote {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers

    private var orderedProducts: [Product] {
        var out: [Product] = []
        if let m = ctx.store.products.first(where: { $0.id == PremiumStore.ID.monthly })  { out.append(m) }
        if let y = ctx.store.products.first(where: { $0.id == PremiumStore.ID.yearly })   { out.append(y) }
        if let l = ctx.store.products.first(where: { $0.id == PremiumStore.ID.lifetime }) { out.append(l) }
        return out
    }

    private var selectedProduct: Product? {
        guard let id = selectedProductID else { return nil }
        return ctx.store.products.first(where: { $0.id == id })
    }

    // Footnote text when a subscription is selected
    private var autoRenewFootnote: String? {
        guard let p = selectedProduct, let sub = p.subscription else { return nil }
        let unit = sub.subscriptionPeriod.unit
        let cycle: String = {
            switch unit {
            case .month: return "mo"
            case .year:  return "yr"
            default: return "period"
            }
        }()
        return "Plan auto-renews for \(p.displayPrice)/\(cycle) until canceled."
    }

    private func purchaseSelected() {
        guard let id = selectedProductID,
            let product = ctx.store.products.first(where: { $0.id == id }) else { return }
        Task { await ctx.store.buy(product: product) }
    }

    private func trailingPriceText(for p: Product) -> String {
        if p.id == PremiumStore.ID.lifetime { return p.displayPrice }
        if let sub = p.subscription {
            let unit = sub.subscriptionPeriod.unit
            let suffix = (unit == .month ? "/mo" : unit == .year ? "/yr" : unit == .week ? "/wk" : "")
            return "\(p.displayPrice) \(suffix)"
        }
        return p.displayPrice
    }

    private func displayTitle(for id: String) -> String {
        switch id {
        case PremiumStore.ID.monthly:  return "Monthly"
        case PremiumStore.ID.yearly:   return "Annual"
        case PremiumStore.ID.lifetime: return "Lifetime"
        default: return "Plan"
        }
    }

    private func badge(for id: String) -> String? {
        switch id {
        case PremiumStore.ID.yearly:   return "Best Value"
        case PremiumStore.ID.lifetime: return "One-Time"
        default: return nil
        }
    }
    
    private var currentProductID: String? {
        switch ctx.store.membershipType {
        case .monthly:  return PremiumStore.ID.monthly
        case .yearly:   return PremiumStore.ID.yearly
        case .lifetime: return PremiumStore.ID.lifetime
        case .free:     return nil
        }
    }

    private var isCurrentSelection: Bool {
        guard let sel = selectedProductID else { return false }
        return sel == currentProductID
    }

    private var showsManageButton: Bool {
        if case .subscription = ctx.store.entitlement.source { return true }
        return false
    }

    @MainActor
    func manageSubscriptions(openURL: OpenURLAction) {
        Task {
            do {
                if #available(iOS 16.0, *) {
                    if let scene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first(where: { $0.activationState == .foregroundActive }) {
                        try await AppStore.showManageSubscriptions(in: scene)
                    }
                } else {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        openURL(url)
                    }
                }
            } catch {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    openURL(url)
                }
            }
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
    var onTap: () -> Void

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
