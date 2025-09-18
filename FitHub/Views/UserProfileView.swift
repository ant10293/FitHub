import SwiftUI
import AuthenticationServices


struct UserProfileView: View {
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var authService = AuthService.shared
    @StateObject private var kbd = KeyboardManager.shared
    @State private var alertMessage: String = ""

    // MARK: – Local draft state for each editable field
    @State private var draftUserName: String = ""
    @State private var draftFirstName: String = ""
    @State private var draftLastName: String = ""
    
    // MARK: – FocusState flags
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ZStack {
            Color(authService.isAuthenticated
                  ? UIColor.clear
                  : UIColor.secondarySystemBackground
            )
            .ignoresSafeArea()
            
            VStack {
                // 1) Show any banner (for username/first/last update)
                if ctx.toast.showingSaveConfirmation {
                    InfoBanner(
                        text: alertMessage,
                        bgColor: !alertMessage.contains("failed")
                            ? Color.green
                            : Color.red
                    )
                }
                
                if authService.isAuthenticated  {
                    Form {
                        // MARK: — Username Section
                        Section {
                            TextField("Enter username", text: $draftUserName)
                                .focused($focusedField, equals: .userName)
                                .onSubmit(commitUserName)
                                .onChange(of: focusedField) { oldFocus, newFocus in
                                    if newFocus != .userName {
                                        commitUserName()
                                    }
                                }
                        } header: {
                            Text("FitHub Username")
                        }
                        
                        // MARK: — Personal Info Section
                        Section {
                            TextField("First Name", text: $draftFirstName)
                                .focused($focusedField, equals: .firstName)
                                .onSubmit(commitFirstName)
                                .onChange(of: focusedField) { oldFocus, newFocus in
                                    if newFocus != .firstName {
                                        commitFirstName()
                                    }
                                }
                            
                            TextField("Last Name", text: $draftLastName)
                                .focused($focusedField, equals: .lastName)
                                .onSubmit(commitLastName)
                                .onChange(of: focusedField) { oldFocus, newFocus in
                                    if newFocus != .lastName {
                                        commitLastName()
                                    }
                                }
                        } header: {
                            Text("Personal Information")
                        }
                        
                        if ctx.userData.settings.allowedCredentials {
                            Section {
                                HStack {
                                    Text(ctx.userData.profile.email)
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                }
                                .foregroundStyle(Color.secondary)
                                .textSelection(.disabled)
                            } header: {
                                Text("Email")
                            }
                        }
                        
                        // MARK: — Footer Section with Account Creation and Logout
                        Section {
                            EmptyView()
                        } footer: {
                            VStack(spacing: 12) {
                                if let creationDate = ctx.userData.profile.accountCreationDate {
                                    Text("Account Created: \(Format.formatDate(creationDate))")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                Button(action: handleSignOut) {
                                    Text("Logout")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .onAppear(perform: populateDrafts)
                } else {
                    // MARK: — Not logged in
                    VStack {
                        Text("Please sign in to continue")
                            .font(.title)
                            .padding()
                        
                        SignInWithAppleButton(.signIn) { req in
                            req.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            authService.signIn(with: result, into: ctx.userData) { res in
                                switch res {
                                case .success:
                                    // After successful sign-in, Auth listener will fire
                                    alertMessage = "Sign in successful"
                                    ctx.toast.showSaveConfirmation(duration: 2.0)
                                    break
                                case .failure(let err):
                                    alertMessage = "Sign in failed: \(err)"
                                    ctx.toast.showSaveConfirmation(duration: 2.0)
                                }
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.08)
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }
    
    private enum Field: Hashable { case userName, firstName, lastName }
    
    // MARK: – Populate drafts from userData
    private func populateDrafts() {
        draftUserName  = ctx.userData.profile.userName
        draftFirstName = ctx.userData.profile.firstName
        draftLastName  = ctx.userData.profile.lastName
    }
    
    // MARK: – Commit Helpers
    
    /// Commit username both locally and to Firebase displayName, then show a success/failure banner.
    private func commitUserName() {
        let trimmed = draftUserName.trimmingTrailingSpaces()
        guard trimmed != ctx.userData.profile.userName else { return }
        
        // 1) Update local userData
        ctx.userData.profile.userName = trimmed
        ctx.userData.saveSingleStructToFile(\.profile, for: .profile)
        
        // 2) Update Firebase displayName
        authService.updateDisplayName(to: trimmed) { result in
            switch result {
            case .success:
                alertMessage = "Username updated successfully"
            case .failure(let error):
                alertMessage = "Failed to update username: \(error.localizedDescription)"
            }
            ctx.toast.showSaveConfirmation(duration: 2.0)
        }
    }
    
    /// Commit firstName locally only, then show a banner.
    private func commitFirstName() {
        let trimmed = draftFirstName.trimmingTrailingSpaces()
        guard trimmed != ctx.userData.profile.firstName else { return }
        
        ctx.userData.profile.firstName = trimmed
        ctx.userData.saveSingleStructToFile(\.profile, for: .profile)
        
        alertMessage = "First name updated"
        ctx.toast.showSaveConfirmation(duration: 2.0)
    }
    
    /// Commit lastName locally only, then show a banner.
    private func commitLastName() {
        let trimmed = draftLastName.trimmingTrailingSpaces()
        guard trimmed != ctx.userData.profile.lastName else { return }
        
        ctx.userData.profile.lastName = trimmed
        ctx.userData.saveSingleStructToFile(\.profile, for: .profile)
        
        alertMessage = "Last name updated"
        ctx.toast.showSaveConfirmation(duration: 2.0)
    }
    
    // MARK: — Handle Logout/Login Button
    
    private func handleSignOut() {
        AuthService.shared.signOut(userData: ctx.userData) { result in
            switch result {
            case .success:
                alertMessage = "Logged out successfully"
            case .failure(let error):
                alertMessage = "Failed to log out: \(error.localizedDescription)"
            }
            ctx.toast.showSaveConfirmation(duration: 2.0)
        }
    }
}

