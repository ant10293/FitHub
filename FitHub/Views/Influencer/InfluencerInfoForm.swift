//
//  InfluencerInfoForm.swift
//  FitHub
//
//  Reusable form component for influencer registration information
//

import SwiftUI

struct InfluencerInfoForm: View {
    @Binding var fullName: String
    @Binding var email: String
    @Binding var notes: String
    @Binding var payoutFrequency: PaymentFrequency
    
    let allowEditFullName: Bool
    let allowEditEmail: Bool
    let allowEditNotes: Bool
    let allowEditPayoutFrequency: Bool
    
    var emailErrorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter Information")
                .font(.headline)
            
            // Full Name
            TextField("Full Name", text: $fullName)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .inputStyle()
                .disabled(!allowEditFullName)
                .overlay(alignment: .trailing) {
                    if !allowEditFullName {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(.trailing, 12)
                    }
                }
            
            // Email
            VStack(alignment: .leading, spacing: 4) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .inputStyle()
                    .disabled(!allowEditEmail)
                
                if let errorMessage = emailErrorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            // Notes
            TextField("Notes (Optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .inputStyle()
                .disabled(!allowEditNotes)
                .overlay(alignment: .trailing) {
                    if !allowEditNotes {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(.trailing, 12)
                    }
                }
            
            // Payout Frequency
            VStack(alignment: .leading, spacing: 4) {
                Text("Payout Frequency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Picker("Payout Frequency", selection: $payoutFrequency) {
                    ForEach(PaymentFrequency.allCases) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!allowEditPayoutFrequency)
                .opacity(allowEditPayoutFrequency ? 1.0 : 0.5)
            }
        }
    }
}

