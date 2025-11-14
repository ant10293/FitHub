import SwiftUI
import FirebaseAuth
import FirebaseFunctions

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    var onSuccess: () -> Void
    var onFailure: (Error) -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var isPasswordVisible = false
    
    private enum FlowStep {
        case emailEntry
        case existingAccount
        case newAccount
        
        var buttonTitle: String {
            switch self {
            case .emailEntry: return "Continue"
            case .existingAccount: return "Sign In"
            case .newAccount: return "Create Account"
            }
        }
        
        var showsAlternateEmailOption: Bool {
            self != .emailEntry
        }
    }
    
    @State private var flowStep: FlowStep = .emailEntry
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email, password, confirmPassword, firstName, lastName
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch flowStep {
                case .emailEntry:
                    emailEntrySection
                case .existingAccount:
                    existingAccountSection
                case .newAccount:
                    newAccountSection
                }
                
                Spacer()
                
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
                    .padding(.top, 8)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                }
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .overlay { if isProcessing { ProgressView() } }
        .navigationTitle(navigationTitle)
    }
    
    private var navigationTitle: String {
        switch flowStep {
        case .emailEntry, .existingAccount:
            return "Sign In"
        case .newAccount:
            return "Create Account"
        }
    }
    
    private var emailEntrySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Email")
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .email)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var existingAccountSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Email")
                Text(email)
                    .font(.headline)
            }
            
            passwordField
            
            Button("Forgot password?") {
                sendPasswordReset()
            }
            .font(.footnote)
            .foregroundStyle(Color.accentColor)
        }
    }
    
    private var newAccountSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Email")
                Text(email)
                    .font(.headline)
            }
            
            passwordField
            
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Confirm Password")
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.password)
                    .focused($focusedField, equals: .confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Profile (optional)")
                    .font(.headline)
                
                fieldLabel("First Name")
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .focused($focusedField, equals: .firstName)
                    .textFieldStyle(.roundedBorder)
                
                fieldLabel("Last Name")
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .focused($focusedField, equals: .lastName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
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
    
    @ViewBuilder
    private func fieldLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.secondary)
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Password")
            ZStack {
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .overlay(alignment: .trailing) {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Color.secondary)
                }
                .padding(.trailing, 12)
            }
        }
    }
}

