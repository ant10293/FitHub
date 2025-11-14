//
//  AuthService.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

/// A self-contained service for “Sign in with Apple → Firebase → UserData” logic.
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published private(set) var isAuthenticated: Bool = (Auth.auth().currentUser != nil)
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    enum FlowKind {
            case signInExisting      // user is logging into an existing account
            case createAccount       // user is creating a new account / upgrading guest
    }
    
    private init() {
        // Start listening right away
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = (user != nil)
            }
        }
    }
    
    deinit {
        if let handle = authListenerHandle { Auth.auth().removeStateDidChangeListener(handle) }
    }
    
    static func getUid() -> String? { return Auth.auth().currentUser?.uid }
        
    /// Returns the primary authentication provider ID for the current user.
    /// Common values: "password" (email/password), "google.com", "apple.com"
    /// Returns `nil` if no user is signed in.
    static func getProviderID() -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        return user.providerData.first?.providerID
    }
    
    static func isAnonymous() -> Bool {
        return Auth.auth().currentUser?.isAnonymous ?? false
    }
    
    /// Delete current user if anonymous, then call completion.
    private func deleteAnonymousIfPresent(completion: @escaping () -> Void) {
        guard let current = Auth.auth().currentUser, current.isAnonymous else {
            completion()
            return
        }
        
        current.delete { error in
            if let error = error {
                print("⚠️ Failed to delete anonymous user: \(error.localizedDescription)")
                // We keep going regardless.
            }
            completion()
        }
    }
    
    /// Sign-in flow that *first* deletes any anonymous user, then runs `performSignIn`.
    private func signInReplacingAnonymous(
        _ performSignIn: @escaping (@escaping (AuthDataResult?, Error?) -> Void) -> Void,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        let finish: (AuthDataResult?, Error?) -> Void = { result, error in
            if let error = error as NSError? {
                let code  = AuthErrorCode.Code(rawValue: error.code)
                let domain = error.domain
                print("❌ [AuthService] signInReplacingAnonymous: performSignIn failed. domain=\(domain) code=\(String(describing: code)) msg=\(error.localizedDescription)")
                
                // Optional: special-case duplicate credential so you can see it clearly
                if error.localizedDescription.contains("Duplicate credential received") {
                    print("⚠️ [AuthService] Duplicate credential error – Apple/Firebase is rejecting reuse of this credential. User must retry Apple sign-in to get a fresh credential.")
                }
                
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                print("❌ [AuthService] signInReplacingAnonymous: AuthDataResult had no user")
                completion(.failure(AuthServiceError.firebaseSignInFailed("No user in auth result")))
                return
            }
            print("✅ [AuthService] signInReplacingAnonymous: sign-in success, uid=\(user.uid) isAnonymous=\(user.isAnonymous)")
            completion(.success(user))
        }
        
        print("ℹ️ [AuthService] signInReplacingAnonymous: calling deleteAnonymousIfPresent()")
        deleteAnonymousIfPresent {
            print("ℹ️ [AuthService] signInReplacingAnonymous: deleteAnonymousIfPresent() finished, calling performSignIn")
            performSignIn(finish)
        }
    }

    /// Upgrade an anonymous user using `link(with:)`. If no anon user, or if the
    /// credential is already in use, falls back to `fallbackSignIn`.
    private func upgradeAnonymousUser(
        with credential: AuthCredential,
        fallbackSignIn: @escaping (@escaping (AuthDataResult?, Error?) -> Void) -> Void,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        guard let current = Auth.auth().currentUser, current.isAnonymous else {
            print("ℹ️ [AuthService] upgradeAnonymousUser: no anonymous user, delegating to signInReplacingAnonymous")
            // No anonymous user → just behave like a normal sign-in (and delete any anon first).
            signInReplacingAnonymous(fallbackSignIn, completion: completion)
            return
        }
        
        print("🔗 [AuthService] upgradeAnonymousUser: attempting link(for anonymous user uid=\(current.uid))")
        current.link(with: credential) { [weak self] result, error in
            guard let self = self else {
                print("⚠️ [AuthService] upgradeAnonymousUser: self deallocated before link completion")
                return
            }
            
            if let error = error as NSError? {
                let code = AuthErrorCode.Code(rawValue: error.code)
                print("❌ [AuthService] upgradeAnonymousUser: link failed with code=\(String(describing: code)) error=\(error.localizedDescription)")
                
                if let code = code,
                   code == .credentialAlreadyInUse ||
                   code == .emailAlreadyInUse ||
                   code == .accountExistsWithDifferentCredential {
                    
                    // 🔁 IMPORTANT PART:
                    // Firebase may give us a *new* credential to use for sign-in.
                    if let updated = error.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential {
                        print("ℹ️ [AuthService] upgradeAnonymousUser: using updatedCredential from error for fallback sign-in")
                        self.signInReplacingAnonymous(
                            { handler in Auth.auth().signIn(with: updated, completion: handler) },
                            completion: completion
                        )
                    } else {
                        print("ℹ️ [AuthService] upgradeAnonymousUser: no updatedCredential in error, using provided fallbackSignIn")
                        self.signInReplacingAnonymous(fallbackSignIn, completion: completion)
                    }
                    return
                }
                
                // Some other link error (including 'Duplicate credential' if it ever happens here)
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                print("❌ [AuthService] upgradeAnonymousUser: link result had no user")
                completion(.failure(AuthServiceError.firebaseSignInFailed("No user in link result")))
                return
            }
            
            print("✅ [AuthService] upgradeAnonymousUser: link succeeded, upgraded uid=\(user.uid) isAnonymous=\(user.isAnonymous)")
            completion(.success(user))
        }
    }

    
    private func updateUserData(
        for user: User,
        userData: UserData,
        emailFallback: String?,
        nameComponents: PersonNameComponents?,
        displayName: String?
    ) {
        let names = parseName(
            preferredFirstName: nameComponents?.givenName,
            preferredLastName: nameComponents?.familyName,
            fallbackDisplayName: displayName,
            firebaseDisplayName: user.displayName
        )
        let resolvedEmail = emailFallback ?? user.email

        Task { @MainActor in
            userData.settings.allowedCredentials = true
            userData.profile.accountCreationDate = user.metadata.creationDate ?? Date()
            userData.profile.userId = user.uid
            let finalEmail = resolvedEmail ?? userData.profile.email
            if !finalEmail.isEmpty {
                userData.profile.email = finalEmail
            }

            if !names.firstName.isEmpty {
                userData.profile.firstName = names.firstName
            }
            if !names.lastName.isEmpty {
                userData.profile.lastName = names.lastName
            }
            if !names.userName.isEmpty {
                userData.profile.userName = names.userName
            }
        }
    }

    func deleteCurrentAccount(userData: UserData, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthServiceError.noCurrentUser))
            return
        }
        
        let db = Firestore.firestore()
        let referralCode = userData.profile.referralCode?.trimmed.uppercased()
        
        func deleteAuthUser() {
            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                DispatchQueue.main.async {
                    userData.profile = Profile()
                    userData.settings.allowedCredentials = false
                }
                completion(.success(()))
            }
        }
        
        func deleteReferralCodeIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
            guard let code = referralCode, !code.isEmpty else {
                completion(.success(()))
                return
            }
            
            db.collection("referralCodes").document(code).delete { error in
                if let error = error as NSError? {
                    if error.domain == FirestoreErrorDomain, error.code == FirestoreErrorCode.notFound.rawValue {
                        completion(.success(()))
                    } else {
                        completion(.failure(error))
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
        
        deleteReferralCodeIfNeeded { referralResult in
            switch referralResult {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                deleteAuthUser()
            }
        }
    }
    
    // MARK: — Update only the Firebase displayName
    
    /// Updates the current Firebase user's displayName to the given `newName`.
    /// Calls `completion(Result<Void,Error>)` when done.
    func updateDisplayName(to newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        UIApplication.shared.endEditing()
        guard let user = Auth.auth().currentUser else {
            let err = NSError(
                domain: "AuthService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user to update"]
            )
            completion(.failure(err))
            return
        }
        
        setDisplayName(for: user, to: newName) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func setDisplayName(
        for user: User,
        to newName: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        let request = user.createProfileChangeRequest()
        request.displayName = newName
        request.commitChanges { error in
            completion?(error)
        }
    }
    
    // MARK: — Sign out
    
    /// Signs out the current Firebase user. Clears local `UserData` fields as needed.
    func signOut(userData: UserData, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            // Clear out local userData
            userData.profile.accountCreationDate = nil
            userData.profile.firstName = ""
            userData.profile.lastName = ""
            userData.profile.email = ""
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: — Auth state listener
    
    /// Starts a Firebase AuthStateDidChangeListener. Returns the listener handle.
    /// `onChange` is called whenever auth state changes, passing the optional new `User`.
    private func addStateDidChangeListener(onChange: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return Auth.auth().addStateDidChangeListener { _, user in
            onChange(user)
        }
    }
    
    /// Removes the given listener handle.
    private func removeStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}

extension AuthService {
    /// Signs in the user with Firebase Anonymous Auth.
    /// This creates a guest account with a stable uid that can later be upgraded
    /// to a real account (Apple, Google, email/password) via `link(with:)`.
    func signInAnonymously(into userData: UserData, firstName: String, lastName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("❌ Anonymous sign-in failed: \(error.localizedDescription)")
                completion(.failure(AuthServiceError.firebaseSignInFailed(error.localizedDescription)))
                return
            }
            
            guard let user = authResult?.user else {
                print("❌ Anonymous sign-in returned no user")
                completion(.failure(AuthServiceError.firebaseSignInFailed("No user in auth result")))
                return
            }
            
            print("✅ Anonymous sign-in successful. uid=\(user.uid)")
            
            // Minimal userData wiring for a guest/anonymous user
            Task { @MainActor in
                // Guest – credentials not yet set up
                userData.settings.allowedCredentials = false
                userData.profile.firstName = firstName
                userData.profile.lastName = lastName
                if let displayName = getDisplayName(firstName: firstName, lastName: lastName) {
                    userData.profile.userName = displayName
                }
                userData.profile.accountCreationDate = user.metadata.creationDate ?? Date()
                userData.profile.userId = user.uid
                // Do NOT touch name/email here; those will be set when they upgrade
            }
            
            completion(.success(()))
        }
    }
}

extension AuthService {
    func signInWithApple(with result: Result<ASAuthorization, Error>, into userData: UserData, completion: @escaping (Result<Void, Error>) -> Void) {
        switch result {
        case .failure(let err):
            let ns = err as NSError
            print("❌ Apple auth failed: domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)")

            if ns.domain == ASAuthorizationError.errorDomain {
                if ns.code == ASAuthorizationError.canceled.rawValue {
                    print("ℹ️ User canceled Apple sign-in.")
                    completion(.failure(AuthServiceError.userCancelled))
                    return
                }
                if ns.code == ASAuthorizationError.unknown.rawValue {
                    print("⚠️ Apple sign-in unknown error (1000). Suggest retry/reboot.")
                    completion(.failure(AuthServiceError.systemIssue))
                    return
                }
            }
            completion(.failure(err))

        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
               print("❌ Missing ASAuthorizationAppleIDCredential")
               completion(.failure(AuthServiceError.missingIdentityToken))
               return
            }
            
            guard let identityToken = appleIDCredential.identityToken else {
                print("❌ Unable to fetch identity token")
                completion(.failure(AuthServiceError.missingIdentityToken))
                return
            }
            guard let tokenString = String(data: identityToken, encoding: .utf8) else {
                print("❌ Unable to serialize token string from data")
                completion(.failure(AuthServiceError.tokenSerializationFailed))
                return
            }

            // Firebase Authentication
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nil)
            /*
            Auth.auth().signIn(with: credential) { [self] (authResult, error) in
                if let error = error {
                    print("❌ Firebase Authentication error: \(error.localizedDescription)")
                    completion(.failure(AuthServiceError.firebaseSignInFailed(error.localizedDescription)))
                    return
                }
                
                guard let user = authResult?.user else {
                    print("❌ Firebase returned no user")
                    completion(.failure(AuthServiceError.firebaseSignInFailed("No user in auth result")))
                    return
                }
                             
                updateUserData(
                    for: user,
                    userData: userData,
                    emailFallback: appleIDCredential.email ?? user.email,
                    nameComponents: appleIDCredential.fullName,
                    displayName: appleIDCredential.fullName?.formatted() ?? user.displayName
                )
                
                completion(.success(()))
            }
            */
            
            // If anonymous → upgrade guest; otherwise → normal sign-in.
            upgradeAnonymousUser(
                with: credential,
                fallbackSignIn: { handler in Auth.auth().signIn(with: credential, completion: handler) },
                completion: { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .failure(let error):
                        completion(.failure(AuthServiceError.firebaseSignInFailed(error.localizedDescription)))
                        
                    case .success(let user):
                        self.updateUserData(
                            for: user,
                            userData: userData,
                            emailFallback: appleIDCredential.email ?? user.email,
                            nameComponents: appleIDCredential.fullName,
                            displayName: appleIDCredential.fullName?.formatted() ?? user.displayName
                        )
                        
                        completion(.success(()))
                    }
                }
            )
        }
    }
}

extension AuthService {
    /*
    func signInWithEmail(email: String, password: String, into userData: UserData, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let self = self, let user = authResult?.user else {
                completion(.failure(AuthServiceError.firebaseSignInFailed("No user in auth result")))
                return
            }
            
            updateUserData(
                for: user,
                userData: userData,
                emailFallback: email,
                nameComponents: nil,
                displayName: user.displayName
            )

            completion(.success(()))
        }
    }

    func registerWithEmail(
        email: String,
        password: String,
        firstName: String?,
        lastName: String?,
        into userData: UserData,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let self = self, let user = authResult?.user else {
                completion(.failure(AuthServiceError.firebaseSignInFailed("No user in auth result")))
                return
            }

            if let displayName = getDisplayName(firstName: firstName, lastName: lastName) {
                self.setDisplayName(for: user, to: displayName) { error in
                    if let error = error {
                        print("⚠️ Failed to set displayName during registration: \(error.localizedDescription)")
                    }
                }
            }

            updateUserData(
                for: user,
                userData: userData,
                emailFallback: email,
                nameComponents: nil,
                displayName: user.displayName
            )

            user.sendEmailVerification(completion: nil)

            completion(.success(()))
        }
    }
    */
    
    func signInWithEmail(
        email: String,
        password: String,
        into userData: UserData,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        signInReplacingAnonymous(
            { handler in Auth.auth().signIn(withEmail: email, password: password, completion: handler) },
            completion: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let user):
                    updateUserData(
                        for: user,
                        userData: userData,
                        emailFallback: email,
                        nameComponents: nil,
                        displayName: user.displayName
                    )
                    completion(.success(()))
                }
            }
        )
    }

    func registerWithEmail(
        email: String,
        password: String,
        firstName: String?,
        lastName: String?,
        into userData: UserData,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        upgradeAnonymousUser(
            with: EmailAuthProvider.credential(withEmail: email, password: password),
            // If email already exists or we weren't anonymous, this is the "normal sign-in" it falls back to
            fallbackSignIn: { handler in Auth.auth().signIn(withEmail: email, password: password, completion: handler) },
            completion: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let user):
                    if let displayName = getDisplayName(firstName: firstName, lastName: lastName) {
                        self.setDisplayName(for: user, to: displayName) { error in
                            if let error = error {
                                print("⚠️ Failed to set displayName during registration: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                   updateUserData(
                        for: user,
                        userData: userData,
                        emailFallback: email,
                        nameComponents: nil,
                        displayName: user.displayName
                    )
                    
                    user.sendEmailVerification(completion: nil)
                    completion(.success(()))
                }
            }
        )
    }
}

private enum AuthServiceError: LocalizedError {
    case userCancelled
    case systemIssue            // ASAuthorizationError.unknown / transient system state
    case missingIdentityToken
    case tokenSerializationFailed
    case firebaseSignInFailed(String)
    case invalidPresentingController
    case missingGoogleClientID
    case googleSignInFailed(String)
    case googleSignInUnavailable
    case noCurrentUser

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Sign in was canceled."
        case .systemIssue:
            return "Apple sign-in hit a system issue. Try again, make sure you're signed into iCloud, or restart the device."
        case .missingIdentityToken:
            return "Couldn’t get an identity token from Apple."
        case .tokenSerializationFailed:
            return "Couldn’t read the identity token."
        case .firebaseSignInFailed(let msg):
            return "Firebase sign-in failed: \(msg)"
        case .invalidPresentingController:
            return "Unable to find a presenting view controller for Google Sign-In."
        case .missingGoogleClientID:
            return "Missing Google Sign-In client ID. Check Firebase configuration."
        case .googleSignInFailed(let message):
            return "Google sign-in failed: \(message)"
        case .googleSignInUnavailable:
            return "Google Sign-In is not available in this build."
        case .noCurrentUser:
            return "No authenticated user to delete."
        }
    }
}
