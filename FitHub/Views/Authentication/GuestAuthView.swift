//
//  GuestAuthView.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/14/25.
//

import SwiftUI

struct GuestAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    let onSuccess: () -> Void
    let onFailure: (Error) -> Void

    var body: some View {
        Form {
            Section {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
            } header: {
                Text("Profile (optional)")
            } footer: {
                footerContent
            }
        }
        .overlay { if isProcessing { ProgressView() } }
    }
    
    private var footerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ErrorFooter(message: errorMessage)
            
            RectangularButton(title: "Continue") {
                signIn(firstName: firstName.trimmed, lastName: lastName.trimmed)
            }
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                errorMessage = error.localizedDescription
                onFailure(error)
            }
        })
    }
}
