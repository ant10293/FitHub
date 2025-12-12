import SwiftUI
import AuthenticationServices
import UIKit

struct AuthProviderButtons: View {
    @ObservedObject var userData: UserData
    var buttonWidth: CGFloat? = nil
    var buttonHeight: CGFloat = 50
    var onSuccess: () -> Void
    var onFailure: (Error) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showGuestFlow = false
    @State private var showEmailFlow = false
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                appleButton

                emailButton

                if showGuestButton {
                    // ───────── OR divider ───────
                    HStack { Line(); Text("or").bold(); Line() }
                        .frame(maxWidth: buttonWidth)
                        .padding(.vertical, 4)

                    guestButton
                }
            }
            .disabled(isProcessing)
            .overlay {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .navigationDestination(isPresented: $showEmailFlow) {
                EmailAuthView(
                    userData: userData,
                    onSuccess: {
                        showEmailFlow = false
                        onSuccess()
                    },
                    onFailure: { error in
                        showEmailFlow = false
                        onFailure(error)
                    }
                )
            }
            .navigationDestination(isPresented: $showGuestFlow) {
                GuestAuthView(
                    userData: userData,
                    onSuccess: {
                        showGuestFlow = false
                        onSuccess()
                    },
                    onFailure: { error in
                        showGuestFlow = false
                        onFailure(error)
                    }
                )
            }
        }
    }

    private var showGuestButton: Bool {
        if userData.setup.setupState == .welcomeView {
            return true
        }
        return !AuthService.isAnonymous()
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            // Show progress view immediately when button is pressed
            isProcessing = true
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            AuthService.shared.signInWithApple(with: result, into: userData) { response in
                DispatchQueue.main.async {
                    isProcessing = false
                    switch response {
                    case .success:
                        onSuccess()
                    case .failure(let error):
                        // Don't show error for user cancellation - it's not an error
                        if let authError = error as? AuthServiceError,
                           case .userCancelled = authError {
                            // Silently handle cancellation - user intentionally cancelled
                            return
                        }
                        onFailure(error)
                    }
                }
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(width: buttonWidth, height: buttonHeight)
        .frame(maxWidth: buttonWidth == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var emailButton: some View {
        AppleButton(
            title: "Sign in with Email",
            imageName: "envelope.fill",
            buttonWidth: buttonWidth,
            buttonHeight: buttonHeight,
            bgColor: .blue,
            buttonAction: {
                showEmailFlow = true
            }
        )
    }

    private var guestButton: some View {
        AppleButton(
            title: "Continue without Account",
            buttonWidth: buttonWidth,
            buttonHeight: buttonHeight,
            bgColor: colorScheme == .dark ? .black : .white,
            buttonAction: {
                showGuestFlow = true
            }
        )
    }
}

private struct AppleButton: View {
    let title: String
    let imageName: String?
    let buttonWidth: CGFloat?
    let buttonHeight: CGFloat
    let bgColor: Color
    let fgColor: Color
    let buttonAction: () -> Void

    init(
        title: String,
        imageName: String? = nil,
        buttonWidth: CGFloat? = nil,
        buttonHeight: CGFloat,
        bgColor: Color,
        fgColor: Color = Color.primary,
        buttonAction: @escaping () -> Void
    ) {
        self.title = title
        self.imageName = imageName
        self.buttonWidth = buttonWidth
        self.buttonHeight = buttonHeight
        self.bgColor = bgColor
        self.fgColor = fgColor
        self.buttonAction = buttonAction
    }

    var body: some View {
        let fontSize = buttonHeight * 0.38

         return Button {
             buttonAction()
         } label: {
             HStack {
                 if let imageName {
                     Image(systemName: imageName)
                         .font(.system(size: max(fontSize, 1)))  // never request size 0
                 }
                 Text(title)
                     .font(.system(size: fontSize))
                     .lineLimit(1)                 // single line
                     .minimumScaleFactor(0.6)      // allow shrink like Apple’s
                     .allowsTightening(true)       // tighter kerning when compressed
             }
             .contentShape(Rectangle())            // keep tap target full width
             .frame(maxWidth: .infinity, maxHeight: .infinity)
         }
         .frame(width: buttonWidth, height: buttonHeight)
         .frame(maxWidth: buttonWidth == nil ? .infinity : nil)
         .background(bgColor)
         .foregroundStyle(fgColor) // keep contrast on blue background
         .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
         .dynamicTypeSize(.medium ... .accessibility3) // respects Dynamic Type like Apple’s
    }
}
