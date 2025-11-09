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
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @StateObject private var admin = ReferralCodeAdmin()
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""
    @State private var payoutMethod: String = ""
    @State private var payoutFrequency: PaymentFrequency = .monthly
    @State private var isGenerating: Bool = false
    @State private var generatedCode: String?
    @State private var customCode: String = ""
    @State private var errorMessage: ReferralError?
    @State private var showSuccess: Bool = false
    @State private var codeStats: CodeStats?
    @State private var isLoadingStats: Bool = false
    @State private var linkCopied: Bool = false
    @State private var codeCopied: Bool = false
    
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
                            payoutMethod: $payoutMethod,
                            payoutFrequency: $payoutFrequency,
                            allowEditFullName: true,
                            allowEditEmail: true,
                            allowEditNotes: true,
                            allowEditPayoutMethod: true,
                            allowEditPayoutFrequency: true,
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
                            bold: true,
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
                                payoutMethod: $payoutMethod,
                                payoutFrequency: $payoutFrequency,
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
        if !ctx.userData.profile.userName.isEmpty {
            fullName = ctx.userData.profile.userName
        } else {
            let firstName = ctx.userData.profile.firstName
            let lastName = ctx.userData.profile.lastName
            fullName = (firstName + " " + lastName).trimmed
        }
        email = ctx.userData.profile.email
        
        // Load referral code from profile (already loaded after sign-in)
        if let existingCode = ctx.userData.profile.referralCode, !existingCode.isEmpty {
            generatedCode = existingCode
            // Load email from Firestore for this code
            loadEmailForCode(existingCode)
            loadCodeStats()
        }
    }
    
    private func loadEmailForCode(_ code: String) {
        Task {
            do {
                let stats = try await admin.getCodeStats(code)
                if let emailValue = stats?["influencerEmail"] as? String {
                    await MainActor.run {
                        email = emailValue
                    }
                }
                if let payoutValue = stats?["payoutMethod"] as? String {
                    await MainActor.run {
                        payoutMethod = payoutValue
                    }
                }
                if let frequencyValue = stats?["payoutFrequency"] as? String,
                   let frequency = PaymentFrequency(rawValue: frequencyValue) {
                    await MainActor.run {
                        payoutFrequency = frequency
                    }
                }
                // Also load notes if available
                if let notesValue = stats?["notes"] as? String {
                    await MainActor.run {
                        notes = notesValue
                    }
                }
            } catch {
                print("Failed to load email for code: \(error)")
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
    
    private func generateCode() {
        let emailResult = validateAndTrimEmail(email)
        guard let trimmedEmail = emailResult.email else {
            errorMessage = ReferralError.invalidEmailFormat
            return
        }
        
        let trimmedCustomCode = customCode.trimmed
        let trimmedName = fullName.trimmed
        let trimmedNotes = notes.trimmed.isEmpty ? nil : notes.trimmed
        let trimmedPayoutMethod = payoutMethod.trimmed.isEmpty ? nil : payoutMethod.trimmed
        let payoutFrequencyValue = payoutFrequency.rawValue
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let code: String
                
                if !trimmedCustomCode.isEmpty {
                    try await admin.createReferralCode(
                        code: trimmedCustomCode,
                        influencerName: trimmedName,
                        influencerEmail: trimmedEmail,
                        notes: trimmedNotes,
                        payoutMethod: trimmedPayoutMethod,
                        payoutFrequency: payoutFrequencyValue
                    )
                    code = trimmedCustomCode.uppercased()
                } else {
                    code = try await admin.createAutoGeneratedCode(
                        influencerName: trimmedName,
                        influencerEmail: trimmedEmail,
                        notes: trimmedNotes,
                        payoutMethod: trimmedPayoutMethod,
                        payoutFrequency: payoutFrequencyValue
                    )
                }
                
                await MainActor.run {
                    generatedCode = code
                    ctx.userData.profile.referralCode = code
                    loadCodeStats()
                    isGenerating = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = referralError(from: error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods

    
    private func loadCodeStats() {
        guard let code = generatedCode else { return }
        
        isLoadingStats = true
        Task {
            do {
                let stats = try await admin.getCodeStats(code)
                
                await MainActor.run {
                    if let data = stats {
                        // Filter out empty strings before counting
                        let usedBy = (data["usedBy"] as? [String] ?? []).filter { !$0.isEmpty }
                        let monthlyPurchasedBy = (data["monthlyPurchasedBy"] as? [String] ?? []).filter { !$0.isEmpty }
                        let annualPurchasedBy = (data["annualPurchasedBy"] as? [String] ?? []).filter { !$0.isEmpty }
                        let lifetimePurchasedBy = (data["lifetimePurchasedBy"] as? [String] ?? []).filter { !$0.isEmpty }
                        
                        codeStats = CodeStats(
                            signUps: usedBy.count,
                            monthlyPurchases: monthlyPurchasedBy.count,
                            annualPurchases: annualPurchasedBy.count,
                            lifetimePurchases: lifetimePurchasedBy.count,
                            lastUsedAt: (data["lastUsedAt"] as? Timestamp)?.dateValue(),
                            lastPurchaseAt: (data["lastPurchaseAt"] as? Timestamp)?.dateValue()
                        )
                    }
                    isLoadingStats = false
                }
            } catch {
                await MainActor.run {
                    isLoadingStats = false
                    print("Failed to load stats: \(error)")
                }
            }
        }
    }
    
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
