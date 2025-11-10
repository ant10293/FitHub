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

/// A self-contained service for “Sign in with Apple → Firebase → UserData” logic.
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published private(set) var isAuthenticated: Bool = (Auth.auth().currentUser != nil)
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
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
    
    func signIn(with result: Result<ASAuthorization, Error>, into userData: UserData, completion: @escaping (Result<Void, Error>) -> Void) {
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
                    // Soft landing for transient system issues (the one you hit)
                    print("⚠️ Apple sign-in unknown error (1000). Suggest retry/reboot.")
                    completion(.failure(AuthServiceError.systemIssue))
                    return
                }
            }
            completion(.failure(err))

        case .success(let auth):
            print("Authentication Successful")
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
               print("❌ Missing ASAuthorizationAppleIDCredential")
               completion(.failure(AuthServiceError.missingIdentityToken))
               return
            }
            
            print("Got Apple ID Credential")
            userData.settings.allowedCredentials = true
            // Extract token
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
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: tokenString,
                rawNonce: nil
            )
        
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

                // 1. Grab the creation date
                userData.profile.accountCreationDate = user.metadata.creationDate ?? Date()

                userData.profile.userId = user.uid
                userData.profile.email = appleIDCredential.email ?? user.email ?? ""

                // 2. Handle name parsing and setting
                let (userName, firstName, lastName) = parseAndSetName(
                    appleIDCredential: appleIDCredential,
                    firebaseUser: user
                )
                userData.profile.userName = userName
                userData.profile.firstName = firstName
                userData.profile.lastName = lastName
                
                completion(.success(()))
            }
        }
    }
    
    /// Parses and sets the user's name from Apple ID credential or Firebase user
    /// Returns the formatted userName string
    private func parseAndSetName(
        appleIDCredential: ASAuthorizationAppleIDCredential,
        firebaseUser: User
    ) -> (userName: String, firstName: String, lastName: String) {
        // pick a source name: Apple → Firebase → empty
        let rawName = appleIDCredential.fullName?.givenName
            ?? firebaseUser.displayName
            ?? ""

        // split into parts
        let parts = rawName.split(separator: " ")
        let first = parts.first.map(String.init) ?? ""
        let last  = parts.dropFirst().joined(separator: "")

        // format
        let firstName = first.formatName()
        let lastName  = last.formatName()
        let userName = lastName.isEmpty ? firstName : "\(firstName) \(lastName)"

        // final display
        return (userName, firstName, lastName)
    }

    // MARK: — Update only the Firebase displayName
    
    /// Updates the current Firebase user's displayName to the given `newName`.
    /// Calls `completion(Result<Void,Error>)` when done.
    func updateDisplayName(to newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        UIApplication.shared.endEditing()
        guard let request = Auth.auth().currentUser?.createProfileChangeRequest() else {
            let err = NSError(
                domain: "AuthService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user to update"]
            )
            completion(.failure(err))
            return
        }
        request.displayName = newName
        request.commitChanges { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: — Sign out
    
    /// Signs out the current Firebase user. Clears local `UserData` fields as needed.
    func signOut(userData: UserData, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            // Clear out local userData
            userData.profile.accountCreationDate = nil
            userData.profile.firstName         = ""
            userData.profile.lastName          = ""
            userData.profile.email             = ""
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

private enum AuthServiceError: LocalizedError {
    case userCancelled
    case systemIssue            // ASAuthorizationError.unknown / transient system state
    case missingIdentityToken
    case tokenSerializationFailed
    case firebaseSignInFailed(String)

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
        }
    }
}
