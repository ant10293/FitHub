//
//  AffiliateInfoForm.swift
//  FitHub
//
//  Reusable form component for influencer registration information
//

import SwiftUI

struct AffiliateInfoForm: View {
    @Binding var fullName: String
    @Binding var email: String
    
    let allowEditFullName: Bool
    let allowEditEmail: Bool
    
    var emailErrorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter Information")
                .font(.headline)
            
            // Full Name
            TextField("Full Name", text: $fullName)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .trailingIconButton(systemName: "lock.fill", isShowing: !allowEditFullName)
                .inputStyle()
                .disabled(!allowEditFullName)
            
            // Email
            VStack(alignment: .leading, spacing: 4) {
                TextField("Contact Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .inputStyle()
                    .disabled(!allowEditEmail)
                
                ErrorFooter(message: emailErrorMessage)
            }
        }
    }
}

