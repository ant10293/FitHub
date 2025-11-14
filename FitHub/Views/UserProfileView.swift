import SwiftUI
import AuthenticationServices
import FirebaseAuth

// FIXME: sign-in success closes this view
struct UserProfileView: View {
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var authService = AuthService.shared
    @StateObject private var kbd = KeyboardManager.shared
    @State private var alertMessage: String = ""
    @State private var showingDeleteConfirmation: Bool = false

    // MARK: – Local draft state for each editable field
    @State private var draftUserName: String = ""
    @State private var draftFirstName: String = ""
    @State private var draftLastName: String = ""
    
    // MARK: – FocusState flags
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ZStack {
            Color(isAuthenticated
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
                
                if isAuthenticated  {
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
                                
                                RectangularButton(title: "Logout", bgColor: .blue, action: handleSignOut)
                                RectangularButton(title: "Delete Account", bgColor: .red, action: {
                                    showingDeleteConfirmation = true
                                })
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
                        
                        AuthProviderButtons(
                            userData: ctx.userData,
                            buttonHeight: UIScreen.main.bounds.height * 0.08,
                            onSuccess: {
                                alertMessage = "Sign in successful"
                                ctx.toast.showSaveConfirmation(duration: 2.0)
                            },
                            onFailure: { error in
                                alertMessage = "Sign in failed: \(error.localizedDescription)"
                                ctx.toast.showSaveConfirmation(duration: 2.0)
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .alert(
            "Delete Account?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                handleDeletion()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove all of your data from FitHub and log you out on this device. This action cannot be undone.")
        }
    }
    
    private var isAuthenticated: Bool {
        authService.isAuthenticated && !AuthService.isAnonymous()
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
        
        alertMessage = "First name updated"
        ctx.toast.showSaveConfirmation(duration: 2.0)
    }
    
    /// Commit lastName locally only, then show a banner.
    private func commitLastName() {
        let trimmed = draftLastName.trimmingTrailingSpaces()
        guard trimmed != ctx.userData.profile.lastName else { return }
        
        ctx.userData.profile.lastName = trimmed
        
        alertMessage = "Last name updated"
        ctx.toast.showSaveConfirmation(duration: 2.0)
    }
    
    // MARK: — Handle Logout/Login Button
    
    private func handleSignOut() {
        kbd.dismiss()
        let accountID = Auth.auth().currentUser?.uid ?? "guest"
        
        do {
            try AccountDataStore.shared.backupActiveData(for: accountID)
            try AccountDataStore.shared.clearActiveData()
        } catch {
            alertMessage = "Failed to back up data: \(error.localizedDescription)"
            ctx.toast.showSaveConfirmation(duration: 2.0)
            return
        }
        
        AuthService.shared.signOut(userData: ctx.userData) { result in
            switch result {
            case .success:
                Task { @MainActor in
                    ctx.resetForSignOut()
                    alertMessage = "Logged out successfully"
                }
            case .failure(let error):
                alertMessage = "Failed to log out: \(error.localizedDescription)"
            }
            ctx.toast.showSaveConfirmation(duration: 2.0)
        }
    }
    
    private func handleDeletion() {
        kbd.dismiss()
        let accountID = Auth.auth().currentUser?.uid ?? "guest"
        AuthService.shared.deleteCurrentAccount(userData: ctx.userData) { result in
            switch result {
            case .success:
                Task { @MainActor in
                    try? AccountDataStore.shared.clearActiveData()
                    try? AccountDataStore.shared.deleteBackup(for: accountID)
                    ctx.resetForSignOut()
                    alertMessage = "Account deleted successfully"
                }
            case .failure(let error):
                alertMessage = "Failed to delete account: \(error.localizedDescription)"
            }
            ctx.toast.showSaveConfirmation(duration: 2.0)
        }
    }
}

