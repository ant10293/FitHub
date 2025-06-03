//
//  AuthenticationService.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

/// A self-contained service for “Sign in with Apple → Firebase → UserData” logic.
final class AuthService {
    func signIn(with result: Result<ASAuthorization, Error>, into userData: UserData, completion: @escaping (Result<Void, Error>) -> Void) {
      switch result {
      case .failure(let err):
        completion(.failure(err))
        
      case .success(let auth):
          print("Authentication Successful")
          if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
              print("Got Apple ID Credential")
              userData.allowedCredentials = true
              // Extract token
              guard let identityToken = appleIDCredential.identityToken else {
                  print("Unable to fetch identity token")
                  return
              }
              guard let tokenString = String(data: identityToken, encoding: .utf8) else {
                  print("Unable to serialize token string from data: \(identityToken.debugDescription)")
                  return
              }
              
              // Firebase Authentication
              let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nil)
              Auth.auth().signIn(with: credential) { (authResult, error) in
                  var firstName: String = ""
                  var lastName: String = ""
                  var userName: String = ""
                  
                  if let error = error {
                      print("Firebase Authentication error: \(error.localizedDescription)")
                      return
                  }
                  
                  if let user = authResult?.user {
                      // 1.  Grab the creation date
                      if let created = user.metadata.creationDate {
                          userData.accountCreationDate = created
                      }
                      
                      userData.userId = user.uid
                      userData.email = appleIDCredential.email ?? user.email ?? ""
                      
                      if let fullName = appleIDCredential.fullName?.givenName ?? user.displayName  {
                          let nameComponents = fullName.description.split(separator: " ")
                          
                          let first = nameComponents.first.map(String.init) ?? ""
                          let last = nameComponents.dropFirst().joined(separator: "")
                          
                          firstName = (first.prefix(1).uppercased() + first.dropFirst().lowercased()).trimmingCharacters(in: .whitespaces)
                          lastName = (last.prefix(1).uppercased() + last.dropFirst().lowercased()).trimmingCharacters(in: .whitespaces)
                          
                          userData.firstName = firstName
                          userData.lastName = lastName
                      } else {
                          firstName = user.displayName ?? ""
                          userData.firstName = firstName
                          userData.lastName = lastName // or a fallback value
                      }
                      
                      if lastName.isEmpty {
                          userName = firstName
                      } else {
                          userName = firstName + " " + lastName
                      }
                      
                      userData.userName = userName
                      userData.saveToFile() // call userData here only to establish all variables and prevent loading failure
                      
                      /*print("userID: \(userData.userId)")
                      print("email: \(userData.email)")
                      print("userName: \(userData.userName)")
                      print("first: \(userData.firstName)")
                      print("last: \(userData.lastName)")*/

                  }
              }
          
          completion(.success(()))
        }
      }
    }
}
