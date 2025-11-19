//
//  InfluencerRegistrationView.swift
//  FitHub
//
//  View for influencers to generate their own referral codes
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InfluencerRegistrationView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @StateObject private var admin = ReferralCodeAdmin()
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""
    @State private var isGenerating: Bool = false
    @State private var generatedCode: String?
    @State private var customCode: String = ""
    @State private var errorMessage: ReferralError?
    @State private var showSuccess: Bool = false
    @State private var codeStats: CodeStats?
    @State private var isLoadingStats: Bool = false
    @State private var linkCopied: Bool = false
    @State private var codeCopied: Bool = false
    @State private var stripeStatus: StripeAffiliateStatus = .empty
    @State private var isRequestingStripeOnboardingLink: Bool = false
    @State private var isRequestingStripeDashboardLink: Bool = false
    @State private var stripeErrorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    
                    if let code = generatedCode {
                        // SUCCESS STATE
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Referral Code")
                                .font(.headline)
                            
                            ZStack {
                                Text(code)
                                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.blue)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                    .background(Color.blue.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            }
                            .overlay(alignment: .trailing) {
                                Button {
                                    UIPasteboard.general.string = code
                                    codeCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        codeCopied = false
                                    }
                                } label: {
                                    Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                        .font(.title3)
                                        .foregroundStyle(codeCopied ? .green : .blue)
                                        .padding()   // system padding, not fixed
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.2), value: codeCopied)
                            }
                            
                            Button {
                                UIPasteboard.general.string = generateAppStoreLink(with: code)
                                linkCopied = true
                                // Reset after 2 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    linkCopied = false
                                }
                            } label: {
                                Label(linkCopied ? "Link Copied!" : "Copy App Link", systemImage: linkCopied ? "checkmark" : "link")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .animation(.easeInOut(duration: 0.2), value: linkCopied)
                            
                            ShareLink(item: generateShareText(code: code)) {
                                Label("Share Referral Code", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            stripeSection(for: code)
                            
                            // Statistics
                            if isLoadingStats {
                                ProgressView()
                                    .centerHorizontally()
                            } else if let stats = codeStats {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Statistics")
                                        .font(.headline)
                                    
                                    StatRow(label: "Sign-ups", value: "\(stats.signUps)")
                                    StatRow(label: "Monthly Purchases", value: "\(stats.monthlyPurchases)")
                                    StatRow(label: "Annual Purchases", value: "\(stats.annualPurchases)")
                                    StatRow(label: "Lifetime Purchases", value: "\(stats.lifetimePurchases)")
                                    
                                    if let lastUsed = stats.lastUsedAt {
                                        StatRow(label: "Last Sign-up", value: Format.formatDate(lastUsed, dateStyle: .medium, timeStyle: .short))
                                    }
                                    
                                    if let lastPurchase = stats.lastPurchaseAt {
                                        StatRow(label: "Last Purchase", value: Format.formatDate(lastPurchase, dateStyle: .medium, timeStyle: .short))
                                    }
                                }
                                .cardContainer(cornerRadius: 12, backgroundColor: Color(UIColor.secondarySystemBackground))
                            }
                        }
                    } else {
                        // INPUT STATE
                        InfluencerInfoForm(
                            fullName: $fullName,
                            email: $email,
                            notes: $notes,
                            allowEditFullName: true,
                            allowEditEmail: true,
                            allowEditNotes: true,
                            emailErrorMessage: emailValidationError(email)
                        )
                        
                        Text("Create Custom Code")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Custom code", text: $customCode)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled(true)
                                .inputStyle()
                                .onChange(of: customCode) { _, _ in
                                    if errorMessage?.forCustomCode == true {
                                        errorMessage = nil
                                    }
                                }
                            
                            if let customCodeError = customCodeValidationError(customCode) {
                                Text(customCodeError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        Spacer()
                        
                        Group {
                            if let error = errorMessage {
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            
                            if isGenerating { ProgressView() }
                        }
                        .centerHorizontally()
                        
                        RectangularButton(
                            title: buttonTitle,
                            enabled: isButtonEnabled,
                            fontWeight: .bold,
                            action: generateCode
                        )
                        
                        Text("Your referral code will be generated from your name and stored so signups can be attributed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding()
            }
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationBarTitle("Influencer Registration", displayMode: .inline)
            .toolbar {
                if let code = generatedCode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: LazyDestination {
                            InfluencerSettingsView(
                                fullName: $fullName,
                                email: $email,
                                notes: $notes,
                                referralCode: code
                            )
                        }) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .onAppear(perform: initializeFromUserData)
            .alert("Code Generated!", isPresented: $showSuccess) {
                Button("OK") { }
            } message: {
                Text("Your referral code has been created successfully!")
            }
        }
    }
    
    private func initializeFromUserData() {
        fullName = ctx.userData.profile.displayName(.full)
        email = ctx.userData.profile.email
        
        // Load referral code from profile (already loaded after sign-in)
        if let existingCode = ctx.userData.profile.referralCode, !existingCode.isEmpty {
            generatedCode = existingCode
            // Load affiliate info, stats, and Stripe status
            Task {
                await loadAffiliateInfo()
                await loadCodeStats()
                await loadStripeStatus()
            }
        }
    }
    
    private func loadAffiliateInfo() async {
        guard let code = generatedCode else { return }

        do {
            let codeData = try await admin.getCodeData(code)
            let (_, email, _, notes) = admin.loadAffiliateInfo(from: codeData)

            await MainActor.run {
                self.email = email
                self.notes = notes
            }
        } catch {
            print("Failed to load affiliate info for code \(code): \(error)")
        }
    }
    
    private func loadCodeStats() async {
        guard let code = generatedCode else { return }

        await MainActor.run {
            isLoadingStats = true
        }

        do {
            let codeData = try await admin.getCodeData(code)
            let stats = try await admin.loadReferralInfo(codeData: codeData)

            await MainActor.run {
                self.codeStats = stats
                self.isLoadingStats = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingStats = false
                print("Failed to load stats: \(error)")
            }
        }
    }
    
    private func loadStripeStatus() async {
        guard let code = generatedCode else { return }

        do {
            let codeData = try await admin.getCodeData(code)
            let stripe = admin.loadStripeStatus(from: codeData)

            await MainActor.run {
                self.stripeStatus = stripe
            }
        } catch {
            await MainActor.run {
                self.stripeStatus = .empty
                print("Failed to load Stripe status: \(error)")
            }
        }
    }
    
    
    // MARK: - Computed Properties
    
    private var buttonTitle: String {
        if isGenerating { return "Generating…" }
        return customCode.trimmed.isEmpty ? "Generate My Referral Code" : "Create Referral Code"
    }
    
    private var isButtonEnabled: Bool {
        guard !isGenerating else { return false }
        guard !fullName.trimmed.isEmpty else { return false }
        guard isEmailValidForSubmission(email) else { return false }
        
        if !customCode.trimmed.isEmpty {
            return customCodeValidationError(customCode) == nil
        }
        return true
    }
    
    // MARK: - Stripe Management

    @ViewBuilder
    private func stripeSection(for code: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stripe Payouts")
                .font(.headline)

            Text(stripeStatus.statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if stripeStatus.needsAction {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Needed")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(stripeStatus.requirementsDue, id: \.self) { requirement in
                        Text("• \(requirement.formattedRequirement)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let errorMessage = stripeErrorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if isRequestingStripeOnboardingLink {
                ProgressView()
                    .centerHorizontally()
            } else {
                RectangularButton(
                    title: stripeStatus.primaryButtonTitle,
                    enabled: true,
                    fontWeight: .bold,
                    action: { connectStripe(for: code) }
                )
            }

            if stripeStatus.isConnected {
                if isRequestingStripeDashboardLink {
                    ProgressView()
                        .centerHorizontally()
                } else {
                    RectangularButton(
                        title: "Open Stripe Dashboard",
                        enabled: true,
                        action: { openStripeDashboard(for: code) }
                    )
                }
            }

            Button {
                refreshStripeStatus()
            } label: {
                Text("Refresh Stripe Status")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .tint(.blue)
        }
        .cardContainer(cornerRadius: 12, backgroundColor: Color(UIColor.secondarySystemBackground))
    }

    private func connectStripe(for code: String) {
        guard !isRequestingStripeOnboardingLink else { return }
        isRequestingStripeOnboardingLink = true
        stripeErrorMessage = nil

        Task {
            do {
                let onboardingLink = try await StripeAffiliateService.shared.createOnboardingLink(referralCode: code)
                await MainActor.run {
                    isRequestingStripeOnboardingLink = false
                    stripeStatus.accountId = onboardingLink.accountId
                    if let detailsSubmitted = onboardingLink.detailsSubmitted {
                        stripeStatus.detailsSubmitted = detailsSubmitted
                    }
                    if let payoutsEnabled = onboardingLink.payoutsEnabled {
                        stripeStatus.payoutsEnabled = payoutsEnabled
                    }

                    guard let linkURL = URL(string: onboardingLink.url) else {
                        stripeErrorMessage = "Received an invalid onboarding link."
                        return
                    }

                    openURL(linkURL)
                }
            } catch {
                await MainActor.run {
                    isRequestingStripeOnboardingLink = false
                    stripeErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func openStripeDashboard(for code: String) {
        guard stripeStatus.isConnected else {
            stripeErrorMessage = "Connect your Stripe account before opening the dashboard."
            return
        }
        guard !isRequestingStripeDashboardLink else { return }

        isRequestingStripeDashboardLink = true
        stripeErrorMessage = nil

        Task {
            do {
                let dashboardLink = try await StripeAffiliateService.shared.createDashboardLink(referralCode: code)
                await MainActor.run {
                    isRequestingStripeDashboardLink = false
                    stripeStatus.accountId = dashboardLink.accountId
                    if let payoutsEnabled = dashboardLink.payoutsEnabled {
                        stripeStatus.payoutsEnabled = payoutsEnabled
                    }

                    guard let linkURL = URL(string: dashboardLink.url) else {
                        stripeErrorMessage = "Received an invalid dashboard link."
                        return
                    }

                    openURL(linkURL)
                }
            } catch {
                await MainActor.run {
                    isRequestingStripeDashboardLink = false
                    stripeErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func refreshStripeStatus() {
        Task {
            await loadStripeStatus()
        }
    }

    private func generateCode() {
        let emailResult = validateAndTrimEmail(email)
        guard let trimmedEmail = emailResult.email else {
            errorMessage = ReferralError.invalidEmailFormat
            return
        }
        
        let trimmedCustomCode = customCode.trimmed
        let trimmedName = fullName.trimmed
        let trimmedNotes = notes.trimmed.isEmpty ? nil : notes.trimmed
        
        isGenerating = true
        errorMessage = nil
        stripeStatus = .empty
        stripeErrorMessage = nil
        isRequestingStripeOnboardingLink = false
        isRequestingStripeDashboardLink = false
        
        Task {
            do {
                let code: String
                
                if !trimmedCustomCode.isEmpty {
                    try await admin.createReferralCode(
                        code: trimmedCustomCode,
                        influencerName: trimmedName,
                        influencerEmail: trimmedEmail,
                        notes: trimmedNotes
                    )
                    code = trimmedCustomCode.uppercased()
                } else {
                    code = try await admin.createAutoGeneratedCode(
                        influencerName: trimmedName,
                        influencerEmail: trimmedEmail,
                        notes: trimmedNotes
                    )
                }
                
                await MainActor.run {
                    generatedCode = code
                    ctx.userData.profile.referralCode = code
                    isGenerating = false
                    showSuccess = true
                }
                
                // Load affiliate info first
                await loadAffiliateInfo()
                
                // Then load stats and Stripe status
                await loadCodeStats()
                await loadStripeStatus()
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = referralError(from: error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateShareText(code: String) -> String {
        let appStoreLink = generateAppStoreLink(with: code)
        return """
        Join me on FitHub! Use my referral code: \(code)
        
        Download FitHub: \(appStoreLink)
        """
    }
    
    /// Generates an App Store link with referral code
    /// Format: Universal link that captures referral code when app opens
    /// This link will:
    /// - If app is installed: Open the app directly and the referral code is automatically captured
    /// - If app not installed: Opens App Store (you may want to set up a landing page that stores the code and redirects)
    private func generateAppStoreLink(with code: String) -> String {
        // Use universal link format that works with ReferralURLHandler
        // Format: https://fithubv1-d3c91.web.app/r/CODE
        // The ReferralURLHandler will extract the code and store it in UserDefaults
        // When the user signs in, ReferralAttributor will claim the code (like in WelcomeView)
        return "https://fithubv1-d3c91.web.app/r/\(code)"
    }
}

// MARK: - Supporting Types
struct CodeStats {
    let signUps: Int
    let monthlyPurchases: Int
    let annualPurchases: Int
    let lifetimePurchases: Int
    let lastUsedAt: Date?
    let lastPurchaseAt: Date?
    
    static var blankStats: CodeStats = .init(
        signUps: 0,
        monthlyPurchases: 0,
        annualPurchases: 0,
        lifetimePurchases: 0,
        lastUsedAt: nil,
        lastPurchaseAt: nil
    )
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}
