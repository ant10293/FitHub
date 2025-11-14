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
        VStack(spacing: 12) {
            appleButton
            
            #if canImport(GoogleSignIn)
            googleButton
            #endif
            
            emailButton
            
            // ───────── OR divider ───────
            HStack { Line(); Text("or").bold(); Line() }
                .frame(maxWidth: buttonWidth)
                .padding(.vertical, 4)
            
            guestButton
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
            GuestAuthView(userData: userData, onSuccess: {
                showGuestFlow = false
                onSuccess()
            })
        }
    }
    
    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            guard !isProcessing else { return }
            isProcessing = true
            AuthService.shared.signInWithApple(with: result, into: userData) { response in
                DispatchQueue.main.async {
                    isProcessing = false
                    switch response {
                    case .success:
                        onSuccess()
                    case .failure(let error):
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
    
    #if canImport(GoogleSignIn)
    private var googleButton: some View {
        Button {
            guard !isProcessing else { return }
            guard let presenter = AuthProviderButtons.presentingViewController() else {
                let error = NSError(
                    domain: "AuthProviderButtons",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to find a view controller to present Google Sign-In."]
                )
                onFailure(error)
                return
            }
            isProcessing = true
            AuthService.shared.signInWithGoogle(presenting: presenter, into: userData) { result in
                DispatchQueue.main.async {
                    isProcessing = false
                    switch result {
                    case .success:
                        onSuccess()
                    case .failure(let error):
                        onFailure(error)
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "globe")
                Text("Sign in with Google")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            .frame(maxWidth: .infinity)
        }
        .frame(width: buttonWidth, height: buttonHeight)
        .frame(maxWidth: buttonWidth == nil ? .infinity : nil)
        .background(colorScheme == .dark ? Color.white : Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    #endif
    
    private var emailButton: some View {
        let fontSize = buttonHeight * 0.38

        return Button {
            showEmailFlow = true
        } label: {
            HStack {
                Image(systemName: "envelope.fill")
                    .font(.system(size: max(fontSize, 1)))  // never request size 0
                Text("Sign in with Email")
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
        .background(.blue)
        .foregroundStyle(Color.primary) // keep contrast on blue background
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .dynamicTypeSize(.medium ... .accessibility3) // respects Dynamic Type like Apple’s
    }
    
    private var guestButton: some View {
        Button("Continue without Account") {
            showGuestFlow = true
        }
        .frame(width: buttonWidth, height: buttonHeight)
        .frame(maxWidth: buttonWidth == nil ? .infinity : nil)
        .background(.black)
        .foregroundStyle(Color.primary) // keep contrast on blue background
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct GuestAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isProcessing = false
    let onSuccess: () -> Void

    var body: some View {
        Form {
            Section {
                Text("Profile (optional)")
                    .font(.headline)
                
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .textFieldStyle(.roundedBorder)
            } footer: {
                RectangularButton(title: "Continue", action: {
                    signIn(firstName: firstName.trimmed, lastName: lastName.trimmed)
                })
            }
        }
        .overlay { if isProcessing { ProgressView() } }
    }
    
    private func signIn(firstName: String, lastName: String) {
        isProcessing = true
        AuthService.shared.signInAnonymously(into: userData, firstName: firstName, lastName: lastName, completion: { result in
            isProcessing = false
            switch result {
            case .success:
                onSuccess()
                dismiss()
            case .failure(let error):
                print(error)
            }
        })
    }
}
