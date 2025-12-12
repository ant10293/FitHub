//
//  AffiliateRegistrationView.swift
//  FitHub
//
//  View for influencers to generate their own referral codes
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AffiliateRegistrationView: View {
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @StateObject private var admin = ReferralCodeAdmin()

    @State private var anonAcctBlocker: Bool = false
    @State private var fullName: String = ""
    @State private var email: String = ""
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
    @State private var codeNotFound: Bool = false
    @State private var stripeConnectKey: Int = 0

    @State private var acceptedTerms: Bool = false
    @State private var showingTerms: Bool = false
    @State private var acceptedTermsVersion: String? = nil
    @State private var currentTermsVersion: String? = nil
    @State private var needsTermsAcceptance: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let code = generatedCode {
                        if needsTermsAcceptance {
                            // BLOCKING VIEW - Terms need re-acceptance
                            VStack(spacing: 20) {
                                Text("Terms and Conditions Update")
                                    .font(.title2.bold())

                                Text("The Affiliate Program Terms and Conditions have been updated. Please review and accept the new terms to continue.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                termsAcceptanceButton(action: {
                                    acceptedTerms.toggle()
                                    if acceptedTerms {
                                        Task { await updateTermsAcceptance(code: code) }
                                    }
                                })
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if codeNotFound {
                            // CODE NOT FOUND WARNING STATE
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Code Not Found")
                                    .font(.headline)

                                Text("Referral code '\(code)' not found in our servers. Please generate a new code or contact support.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                RectangularButton(
                                    title: "Start Over",
                                    enabled: true,
                                    fontWeight: .bold,
                                    action: startOver
                                )
                            }
                            .cardContainer(cornerRadius: 12, backgroundColor: Color(UIColor.secondarySystemBackground))
                        } else {
                            // SUCCESS STATE
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Referral Code")
                                    .font(.headline)

                                ZStack {
                                    Text(code)
                                        .font(.system(.title, design: .monospaced, weight: .bold))
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

                                StripeConnect(stripeStatus: $stripeStatus, referralCode: code, refreshStripeStatus: refreshStripeStatus)
                                    .id(stripeConnectKey) // Force reset by changing key

                                ReferralStats(isLoadingStats: isLoadingStats, codeStats: codeStats)
                            }
                        }
                    } else {
                        if anonAcctBlocker {
                            EmptyState(
                                systemName: "nosign",
                                title: "Affiliate Registration Requires Account",
                                subtitle: "Please navigate to 'Home' → 'Profile' and then Sign-In or create an account."
                            )
                        } else {
                            // INPUT STATE
                            AffiliateInfoForm(
                                fullName: $fullName,
                                email: $email,
                                allowEditFullName: true,
                                allowEditEmail: true,
                                emailErrorMessage: emailValidationError(email)
                            )

                            Text("Create Custom Code")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Custom code (optional)", text: $customCode)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled(true)
                                    .inputStyle()
                                    .onChange(of: customCode) { _, _ in
                                        if errorMessage?.forCustomCode == true {
                                            errorMessage = nil
                                        }
                                    }

                                ErrorFooter(message: customCodeValidationError(customCode))
                            }

                            // Terms acceptance for new users
                            if needsTermsAcceptance {
                                Text("Terms and Conditions")
                                    .font(.headline)

                                termsAcceptanceButton(action: {
                                    acceptedTerms.toggle()
                                })
                            }

                            Spacer()

                            Group {
                                if let error = errorMessage {
                                    ErrorFooter(message: error.localizedDescription)
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
                    }

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationBarTitle("Affiliate Registration", displayMode: .inline)
            .onAppear(perform: initializeFromUserData)
            .alert("Code Generated!", isPresented: $showSuccess) {
                Button("OK") { }
            } message: {
                Text("Your referral code has been created successfully!")
            }
            .sheet(isPresented: $showingTerms) {
                if let url = URL(string: LegalURL.affiliateTerms.rawURL) {
                    SafariDocumentView(url: url)
                }
            }
        }
    }

    private func termsAcceptanceButton(action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                action()
            } label: {
                Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(acceptedTerms ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                (Text("I have read and agree to the ")
                 + Text("Affiliate Terms and Conditions")
                    .foregroundStyle(.blue)
                    .underline())
                    .font(.subheadline)
                    .onTapGesture { showingTerms = true }
            }
        }
        .frame(maxWidth: .infinity)
        .inputStyle()
    }

    private func initializeFromUserData() {
        fullName = ctx.userData.profile.displayName(.full)
        email = ctx.userData.profile.email

        // only initialize data if account is not anonymous
        guard !AuthService.isAnonymous() else {
            anonAcctBlocker = true
            return
        }

        Task {
            currentTermsVersion = await AffiliateTermsConstants.getCurrentVersion()
            if let existingCode = ctx.userData.profile.referralCode, !existingCode.isEmpty {
                generatedCode = existingCode
                await loadAffiliateInfo()
            } else {
                checkTermsAcceptance()
            }
        }
    }

    private func checkTermsAcceptance() {
        guard let currentVersion = currentTermsVersion else {
            needsTermsAcceptance = true
            return
        }

        if let acceptedVersion = acceptedTermsVersion {
            needsTermsAcceptance = acceptedVersion != currentVersion
        } else {
            needsTermsAcceptance = true
        }

        if !needsTermsAcceptance {
            acceptedTerms = true
        }
    }

    private func updateTermsAcceptance(code: String) async {
        guard let currentVersion = currentTermsVersion else { return }
        do {
            try await admin.updateAcceptedTerms(code: code, version: currentVersion)
            await MainActor.run {
                acceptedTermsVersion = currentVersion
                needsTermsAcceptance = false
                acceptedTerms = true
            }
        } catch {
            await MainActor.run {
                acceptedTerms = false
                errorMessage = referralError(from: error)
            }
        }
    }

    private func loadAffiliateInfo(showStatsLoader: Bool = true) async {
        func resetStatsForError(codeNotFound: Bool) {
            isLoadingStats = false
            codeStats      = nil
            stripeStatus   = .empty
            self.codeNotFound = codeNotFound
        }

        guard let code = generatedCode else { return }

        if showStatsLoader { isLoadingStats = true }
        codeNotFound = false

        do {
            let result = try await admin.getData(code)

            await MainActor.run {
                self.email = result.email
                self.codeStats = result.stats
                self.stripeStatus = result.stripe
                self.acceptedTermsVersion = result.acceptedTermsVersion
                self.isLoadingStats = false
                self.codeNotFound = false
                self.checkTermsAcceptance()
            }
        } catch let error as ReferralAdminError {
            await MainActor.run {
                switch error {
                case .codeNotFound:
                    resetStatsForError(codeNotFound: true)
                    self.stripeConnectKey += 1

                case .databaseUnavailable, .malformedDocument:
                    resetStatsForError(codeNotFound: false)
                }
            }
        } catch {
            await MainActor.run {
                resetStatsForError(codeNotFound: false)
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
        if needsTermsAcceptance { guard acceptedTerms else { return false } }
        if !customCode.trimmed.isEmpty {
            return customCodeValidationError(customCode) == nil
        }
        return true
    }

    private func refreshStripeStatus() {
        Task { await loadAffiliateInfo(showStatsLoader: false) }
    }

    private func startOver() {
        // Clear referral code from user data
        ctx.userData.profile.referralCode = nil
        ctx.userData.saveToFile()

        // Reset state to allow access to input state
        generatedCode = nil
        codeNotFound = false
        codeStats = nil
        stripeStatus = .empty
        isLoadingStats = false
        acceptedTermsVersion = nil
        acceptedTerms = false

        // Reset StripeConnect internal state by changing its key
        stripeConnectKey += 1

        // Recheck terms acceptance for new user flow
        checkTermsAcceptance()
    }

    private func generateCode() {
        let emailResult = validateAndTrimEmail(email)
        guard let trimmedEmail = emailResult.email else {
            errorMessage = ReferralError.invalidEmailFormat
            return
        }

        let trimmedCustomCode = customCode.trimmed
        let trimmedName = fullName.trimmed

        isGenerating = true
        errorMessage = nil
        stripeStatus = .empty

        stripeConnectKey += 1

        guard let currentVersion = currentTermsVersion else { return }

        Task {
            do {
                let code: String

                if !trimmedCustomCode.isEmpty {
                    try await admin.createReferralCode(
                        code: trimmedCustomCode,
                        influencerName: trimmedName,
                        influencerEmail: trimmedEmail,
                        acceptedTermsVersion: currentVersion
                    )
                    code = trimmedCustomCode.uppercased()
                } else {
                    code = try await admin.createAutoGeneratedCode(
                        influencerName: trimmedName,
                        influencerEmail: trimmedEmail,
                        acceptedTermsVersion: currentVersion
                    )
                }

                await MainActor.run {
                    generatedCode = code
                    ctx.userData.profile.referralCode = code
                    acceptedTermsVersion = currentVersion
                    needsTermsAcceptance = false
                    isGenerating = false
                    showSuccess = true
                }

                await loadAffiliateInfo(showStatsLoader: true)

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
