import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct WelcomeView: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAuthError = false
    @State private var showEmailFlow = false
    @State private var authErrorMessage: String?

    var body: some View {
        GeometryReader { geo in
            let maxW  = geo.size.width
            let maxH  = geo.size.height
            let logoW = maxW * 0.50          // 50 % of screen width
            let btnW  = maxW * 0.75          // 75 % of screen width
            let btnH  = maxH * 0.075         // ≈ 7.5 % of screen height

            ZStack {
                Color(UIColor.secondarySystemBackground)
                    .ignoresSafeArea()

                VStack {
                    Spacer(minLength: 0)

                    // ─────────── Logo ───────────
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: logoW)
                    
                    Spacer(minLength: 30)

                    AuthProviderButtons(
                        userData: ctx.userData,
                        buttonWidth: btnW,
                        buttonHeight: btnH,
                        onSuccess: { handleNavigation() },
                        onFailure: { error in
                            authErrorMessage = error.localizedDescription
                            showAuthError = true
                        }
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Welcome")
        .alert("Sign-in Failed", isPresented: $showAuthError, presenting: authErrorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }

    // MARK: – Navigation / persistence
    private func handleNavigation() {
        let accountID = AuthService.getUid() ?? ""

        Task {
            do {
                let restored = try AccountDataStore.shared.restoreDataIfAvailable(for: accountID)
                await MainActor.run {
                    if restored {
                        ctx.reloadDataFromDisk()
                    } else {
                        ctx.userData.setup.setupState = .healthKitView
                    }
                }
            } catch {
                await MainActor.run {
                    authErrorMessage = error.localizedDescription
                    showAuthError = true
                    ctx.userData.setup.setupState = .healthKitView
                }
            }

            // 1. Check if user has created a referral code and set it in profile
            if let referralCode = try? await ReferralRetriever.getCreatedCode() {
                await MainActor.run {
                    ctx.userData.profile.referralCode = referralCode
                }
            }

            // 2. Get device fingerprint once (shared by both attributors to avoid duplicate work)
            let deviceFingerprint = await BaseAttributor.getBrowserFingerprint()

            // 3. Claim pending referral code if user came from referral link
            await ReferralAttributor().claimIfNeeded(deviceFingerprint: deviceFingerprint)
            // 4. Claim pending affiliate link if user came from affiliate link (grants premium)
            await AffiliateAttributor().claimIfNeeded(deviceFingerprint: deviceFingerprint)
        }
        
        ctx.userData.saveToFile()
    }
}
