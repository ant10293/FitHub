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
    @StateObject private var admin = ReferralCodeAdmin()
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""
    @State private var isGenerating: Bool = false
    @State private var generatedCode: String?
    @State private var errorMessage: String?
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
                            
                            // big code
                            Text(code)
                                 .font(.system(size: 30, weight: .bold, design: .monospaced))
                                 .foregroundStyle(.blue)
                                 .frame(maxWidth: .infinity)
                                 .padding()
                                 .background(Color.blue.opacity(0.08))
                                 .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            
                            Button {
                                UIPasteboard.general.string = code
                                codeCopied = true
                                // Reset after 2 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    codeCopied = false
                                }
                            } label: {
                                Label(codeCopied ? "Copied!" : "Copy Code", systemImage: codeCopied ? "checkmark" : "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .animation(.easeInOut(duration: 0.2), value: codeCopied)
                            
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
                            .buttonStyle(.bordered)
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
                        Text("Enter Information")
                            .font(.headline)
                        
                        TextField("Full Name", text: $fullName)
                              .textContentType(.name)
                              .autocapitalization(.words)
                              .inputStyle()

                          TextField("Email (Optional)", text: $email)
                              .textContentType(.emailAddress)
                              .keyboardType(.emailAddress)
                              .autocapitalization(.none)
                              .autocorrectionDisabled()
                              .inputStyle()

                          TextField("Notes (Optional)", text: $notes, axis: .vertical)
                              .lineLimit(3...6)
                              .inputStyle()
                        
                        Spacer()
                        
                        Group {
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            
                            if isGenerating { ProgressView() }
                        }
                        .centerHorizontally()
                        
                        RectangularButton(
                            title: isGenerating ? "Generating…" : "Generate My Referral Code",
                            enabled: !isGenerating && !fullName.trimmingCharacters(in: .whitespaces).isEmpty,
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
            .navigationBarTitle("Influencer Registration", displayMode: .inline)
            .onAppear(perform: initializeFromUserData)
            .alert("Code Generated!", isPresented: $showSuccess) {
                Button("OK") { }
            } message: {
                Text("Your referral code has been created successfully!")
            }
        }
    }
    
    private func initializeFromUserData() {
        // Initialize full name: use userName if not empty, else firstName + lastName
        if !ctx.userData.profile.userName.isEmpty {
            fullName = ctx.userData.profile.userName
        } else {
            let firstName = ctx.userData.profile.firstName
            let lastName = ctx.userData.profile.lastName
            fullName = (firstName + " " + lastName).trimmingCharacters(in: .whitespaces)
        }
        
        // Initialize email
        email = ctx.userData.profile.email
        
        // Initialize generated code if user already has one
        if let existingCode = ctx.userData.profile.referralCode, !existingCode.isEmpty {
            generatedCode = existingCode
            loadCodeStats()
        }
    }
    
    private func generateCode() {
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                // Auto-generate code from name (will check email and automatically retry with random numbers if code exists)
                let code = try await admin.createAutoGeneratedCode(
                    influencerName: fullName.trimmingCharacters(in: .whitespaces),
                    influencerEmail: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
                    notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
                )
                
                await MainActor.run {
                    generatedCode = code
                    // Save to userData
                    ctx.userData.profile.referralCode = code
                    loadCodeStats()
                    isGenerating = false
                    showSuccess = true
                }
            } catch {
                isGenerating = false
                await handleError(error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setEmailUsedError() {
        errorMessage = "This email is already registered with another referral code. Please use a different email or contact support."
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            if let nsError = error as NSError? {
                // Check for email already used error
                if nsError.code == -4 {
                    setEmailUsedError()
                    return
                }
                errorMessage = "Failed to generate code: \(getErrorMessage(for: nsError))"
            } else {
                errorMessage = "Failed to generate code: \(error.localizedDescription)"
            }
        }
    }
    
    private func getErrorMessage(for nsError: NSError) -> String {
        switch nsError.code {
        case -2:
            return "Code generation failed. Please try again."
        case -3:
            return "Unable to generate unique code. Please try again."
        case -4:
            return "Email is already registered with another referral code."
        default:
            return nsError.localizedDescription
        }
    }
    
    private func loadCodeStats() {
        guard let code = generatedCode else { return }
        
        isLoadingStats = true
        Task {
            do {
                let stats = try await admin.getCodeStats(code)
                
                await MainActor.run {
                    if let data = stats {
                        codeStats = CodeStats(
                            signUps: (data["usedBy"] as? [String] ?? []).count,
                            monthlyPurchases: (data["monthlyPurchasedBy"] as? [String] ?? []).count,
                            annualPurchases: (data["annualPurchasedBy"] as? [String] ?? []).count,
                            lifetimePurchases: (data["lifetimePurchasedBy"] as? [String] ?? []).count,
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
        // Format: https://fithub.web.app/r/CODE
        // The ReferralURLHandler will extract the code and store it in UserDefaults
        // When the user signs in, ReferralAttributor will claim the code (like in WelcomeView)
        return "https://fithub.web.app/r/\(code)"
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
