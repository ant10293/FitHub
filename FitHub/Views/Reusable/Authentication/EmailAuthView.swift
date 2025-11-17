import SwiftUI
import FirebaseAuth
import FirebaseFunctions

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var isPasswordVisible = false
    @State private var flowStep: FlowStep = .emailEntry
    @FocusState private var focusedField: Field?
    let onSuccess: () -> Void
    let onFailure: (Error) -> Void
    
    var body: some View {
        Form {
            switch flowStep {
            case .emailEntry:
                emailEntrySection
            case .existingAccount:
                existingAccountSection
            case .newAccount:
                newAccountSection
            }
        }
        .navigationTitle(flowStep.navBarTitle)
        .disabled(isProcessing)
        .overlay { if isProcessing { ProgressView() } }
    }
    
    // MARK: - Shared footer
    
    private var footerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            
            RectangularButton(
                title: flowStep.buttonTitle,
                enabled: !isProcessing,
                action: handlePrimaryAction
            )
            
            if flowStep.showsAlternateEmailOption {
                Button("Use a different email") {
                    resetToEmailEntry()
                }
                .font(.system(.footnote, weight: .bold))
                .foregroundStyle(Color.secondary)
                .padding(.top, 8)
            }
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Sections
    
    private var emailEntrySection: some View {
        Section {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .email)
        } header: {
            Text("EMAIL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        } footer: {
            footerContent
        }
    }
    
    private var existingAccountSection: some View {
        Group {
            emailSection
            
            Section {
                passwordField
                
                Button("Forgot password?") {
                    sendPasswordReset()
                }
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
            } header: {
                Text("PASSWORD")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            } footer: {
                footerContent
            }
        }
    }
    
    private var newAccountSection: some View {
        Group {
            emailSection
            
            Section {
                passwordField
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.password)
                    .focused($focusedField, equals: .confirmPassword)
            } header: {
                Text("PASSWORD")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .focused($focusedField, equals: .firstName)
                
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .focused($focusedField, equals: .lastName)
            } header: {
                Text("PROFILE (OPTIONAL)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            } footer: {
                footerContent
            }
        }
    }
    
    // MARK: - Actions (unchanged)
    
    private func handlePrimaryAction() {
        switch flowStep {
        case .emailEntry:
            handleEmailContinue()
        case .existingAccount:
            handleSignIn()
        case .newAccount:
            handleCreateAccount()
        }
    }
    
    private func handleEmailContinue() {
        focusedField = nil
        errorMessage = nil
        
        let normalizedEmail = email.trimmed.lowercased()
        guard !normalizedEmail.isEmpty else {
            errorMessage = "Email is required."
            focusedField = .email
            return
        }
        guard normalizedEmail.contains("@") else {
            errorMessage = "Enter a valid email address."
            focusedField = .email
            return
        }
        
        isProcessing = true
        Task {
            do {
                let callable = Functions.functions(region: "us-central1").httpsCallable("checkUserExists")
                let result = try await callable.call(["email": normalizedEmail])
                let data = result.data as? [String: Any]
                let exists = data?["exists"] as? Bool ?? false
                
                await MainActor.run {
                    isProcessing = false
                    email = normalizedEmail
                    password = ""
                    confirmPassword = ""
                    firstName = ""
                    lastName = ""
                    errorMessage = nil
                    
                    if exists {
                        flowStep = .existingAccount
                        focusedField = .password
                    } else {
                        flowStep = .newAccount
                        focusedField = .password
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = (error as NSError).localizedDescription
                }
            }
        }
    }
    
    private func handleSignIn() {
        focusedField = nil
        errorMessage = nil
        
        let normalizedEmail = email.trimmed.lowercased()
        let trimmedPassword = password.trimmed
        
        guard !trimmedPassword.isEmpty else {
            errorMessage = "Password is required."
            focusedField = .password
            return
        }
        
        isProcessing = true
        signIn(email: normalizedEmail, password: trimmedPassword)
    }
    
    private func handleCreateAccount() {
        focusedField = nil
        errorMessage = nil
        
        let normalizedEmail = email.trimmed.lowercased()
        let trimmedPassword = password.trimmed
        let trimmedConfirm = confirmPassword.trimmed
        let trimmedFirst = firstName.trimmed
        let trimmedLast = lastName.trimmed
        
        guard trimmedPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            focusedField = .password
            return
        }
        
        guard trimmedPassword == trimmedConfirm else {
            errorMessage = "Passwords do not match."
            focusedField = .confirmPassword
            return
        }
        
        isProcessing = true
        register(
            email: normalizedEmail,
            password: trimmedPassword,
            firstName: trimmedFirst,
            lastName: trimmedLast
        )
    }
    
    private func resetToEmailEntry() {
        flowStep = .emailEntry
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        errorMessage = nil
        focusedField = .email
    }
    
    private func signIn(email: String, password: String) {
        AuthService.shared.signInWithEmail(email: email, password: password, into: userData) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success:
                    onSuccess()
                    dismiss()
                case .failure(let error):
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case AuthErrorCode.userNotFound.rawValue:
                            flowStep = .newAccount
                            confirmPassword = password
                            errorMessage = "No account found for that email. Add a name (optional) and tap Create Account."
                            focusedField = .password
                        case AuthErrorCode.invalidEmail.rawValue:
                            errorMessage = "Enter a valid email address."
                            resetToEmailEntry()
                        case AuthErrorCode.wrongPassword.rawValue:
                            errorMessage = "Incorrect password. Please try again."
                        case AuthErrorCode.invalidCredential.rawValue:
                            errorMessage = "Email or password is incorrect. Please try again."
                        default:
                            errorMessage = error.localizedDescription
                            onFailure(error)
                        }
                    } else {
                        errorMessage = error.localizedDescription
                        onFailure(error)
                    }
                }
            }
        }
    }
    
    private func register(email: String, password: String, firstName: String, lastName: String) {
        AuthService.shared.registerWithEmail(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            into: userData
        ) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success:
                    onSuccess()
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    onFailure(error)
                }
            }
        }
    }
    
    private func sendPasswordReset() {
        let normalizedEmail = email.trimmed.lowercased()
        guard !normalizedEmail.isEmpty else {
            errorMessage = "Enter an email before requesting a reset."
            focusedField = .email
            return
        }
        
        isProcessing = true
        Auth.auth().sendPasswordReset(withEmail: normalizedEmail) { error in
            DispatchQueue.main.async {
                isProcessing = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    resetToEmailEntry()
                    errorMessage = "Password reset email sent to \(normalizedEmail)."
                }
            }
        }
    }
    
    private var emailSection: some View {
        Section {
            Text(email)
                .font(.headline)
                .textSelection(.disabled)
                .trailingIconButton(
                    systemName: "lock.fill",
                    action: { isPasswordVisible.toggle() }
                )
        } header: {
            Text("EMAIL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Password field (no label now; label is Section header)
    
    private var passwordField: some View {
        Group {
            if isPasswordVisible {
                TextField("Password", text: $password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
            } else {
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
            }
        }
        .trailingIconButton(
            systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill"
        )
    }
    
    // MARK: - Types
    
    private enum FlowStep {
        case emailEntry, existingAccount, newAccount
        
        var buttonTitle: String {
            switch self {
            case .emailEntry: return "Continue"
            case .existingAccount: return "Sign In"
            case .newAccount: return "Create Account"
            }
        }
        
        var navBarTitle: String {
            switch self {
            case .emailEntry, .existingAccount:
                return "Sign In"
            case .newAccount:
                return "Create Account"
            }
        }
        
        var showsAlternateEmailOption: Bool {
            self != .emailEntry
        }
    }
    
    private enum Field {
        case email, password, confirmPassword, firstName, lastName
    }
}
