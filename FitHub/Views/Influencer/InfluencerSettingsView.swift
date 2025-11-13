//
//  InfluencerSettingsView.swift
//  FitHub
//
//  Settings view for editing influencer information
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InfluencerSettingsView: View {
    @StateObject private var admin = ReferralCodeAdmin()
    
    @Binding var fullName: String
    @Binding var email: String
    @Binding var notes: String
    
    let referralCode: String
    
    @State private var originalEmail: String = ""
    @State private var editedEmail: String = ""
    @State private var isUpdatingEmail: Bool = false
    @State private var isUpdatingPayout: Bool = false
    @State private var errorMessage: ReferralError?
    @State private var showSuccess: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Use the reusable form component with limited editability
                InfluencerInfoForm(
                    fullName: $fullName,
                    email: $editedEmail,
                    notes: $notes,
                    allowEditFullName: false,
                    allowEditEmail: true,
                    allowEditNotes: false,
                    emailErrorMessage: emailValidationError(editedEmail)
                )
                
                Spacer(minLength: 20)
                
                // Server error message (for API errors, not validation)
                if let error = errorMessage {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .centerHorizontally()
                }
                
                // Update Email Button
                if !isUpdatingEmail {
                    RectangularButton(
                        title: "Update Email",
                        enabled: editedEmail != originalEmail && isEmailValidForSubmission(editedEmail),
                        bold: true,
                        action: updateEmail
                    )
                } else {
                    ProgressView()
                        .centerHorizontally()
                }
            
                // Info text
                Text("Full name and notes cannot be changed after code generation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .onAppear(perform: initializeValues)
        .alert("Email Updated!", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("Your email has been updated successfully!")
        }
    }
    
    private func initializeValues() {
        // Store original email when view appears
        originalEmail = email
        editedEmail = email
    }
    
    private func updateEmail() {
        let emailResult = validateAndTrimEmail(editedEmail)
        guard let trimmedEmail = emailResult.email else {
            errorMessage = emailResult.error
            return
        }
        
        isUpdatingEmail = true
        errorMessage = nil
        
        Task {
            do {
                try await admin.updateCreatedReferralCodeEmail(code: referralCode, newEmail: trimmedEmail)
                await MainActor.run {
                    email = trimmedEmail
                    originalEmail = trimmedEmail
                    isUpdatingEmail = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isUpdatingEmail = false
                    errorMessage = referralError(from: error)
                }
            }
        }
    }
}

