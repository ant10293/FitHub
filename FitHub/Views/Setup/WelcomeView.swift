import SwiftUI
import AuthenticationServices



struct WelcomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var userData: UserData
    @StateObject private var authService = AuthService.shared

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

                    // ─── Sign-in with Apple ─────
                    SignInWithAppleButton(.signIn) { req in
                        req.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        authService.signIn(with: result, into: userData) { res in
                            switch res {
                            case .success:
                                handleNavigation(saveSingleVar: true)
                            case .failure(let err):
                                print("Sign-in failed:", err)
                            }
                        }
                    }
                    .frame(width: btnW, height: btnH)

                    // ───────── OR divider ───────
                    HStack { Line(); Text("or").bold(); Line() }
                        .frame(maxWidth: btnW)
                        .padding(.vertical, 4)

                    // ───── Guest button ─────────
                    Button("Continue without Account") {
                        userData.settings.allowedCredentials = false
                        handleNavigation(saveSingleVar: false)
                    }
                    .bold()
                    .frame(width: btnW, height: btnH)
                    .foregroundStyle(.white)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Welcome")
    }

    // MARK: – thin separator line
    struct Line: View {
        var body: some View {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: – Navigation / persistence
    private func handleNavigation(saveSingleVar: Bool) {
        userData.setup.setupState = .healthKitView
        if saveSingleVar {
            //userData.saveSingleStructToFile(\.setup, for: .setup)
        } else {
            //userData.saveToFile()
        }
    }
}
