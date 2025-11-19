//
//  ReferralAttributor.swift
//  FitHub
//
//  UPDATED VERSION - Uses Cloud Function for server-side validation
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

/// Call right after a successful sign-in.
/// It reads "pendingReferralCode" (if any) and claims it via Cloud Function with server-side validation.
final class ReferralAttributor {
    enum ClaimSource: String {
        case universalLink = "universal_link"
        case manualEntry = "manual_entry"
    }

    /// Attempts to claim a referral code once; safe to call multiple times (idempotent).
    /// Uses Cloud Function for server-side validation to prevent bypassing client-side checks.
    func claimIfNeeded(source: ClaimSource = .universalLink) async {
        // Must be signed in
        guard AuthService.getUid() != nil else { return }

        // Pending code saved by the URL handler
        guard let raw = UserDefaults.standard.string(forKey: "pendingReferralCode") else { return }
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }

        // Validate code format client-side (early rejection for invalid format)
        guard ReferralCodeGenerator.isValidCode(code) else {
            print("⚠️ Invalid referral code format: \(code)")
            UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
            return
        }
        
        // Use Cloud Function for server-side validation and atomic claim
        let functions = Functions.functions()
        let claimFunction = functions.httpsCallable("claimReferralCode")
        
        do {
            let result = try await claimFunction.call([
                "referralCode": code,
                "source": source.rawValue
            ])
            
            // Parse response
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool, success {
                let alreadyClaimed = data["alreadyClaimed"] as? Bool ?? false
                
                if alreadyClaimed {
                    print("ℹ️ Referral code already claimed: \(code)")
                } else {
                    print("✅ Successfully claimed referral code: \(code)")
                }
                
                // Clear pending code on success
                UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
            } else {
                print("⚠️ Unexpected response from claimReferralCode")
                // Keep code for retry
            }
            
        } catch {
            // Handle Firebase Functions errors
            // Firebase Functions errors are wrapped in NSError with specific structure
            let nsError = error as NSError
            let errorMessage = nsError.localizedDescription
            
            // Check error domain and code
            // Firebase Functions errors have domain "FIRFunctionsErrorDomain"
            if nsError.domain.contains("Functions") || nsError.domain.contains("functions") {
                // Extract error code from userInfo if available
                let errorCode = nsError.userInfo["code"] as? String ?? ""
                let errorDetails = nsError.userInfo["NSLocalizedDescription"] as? String ?? errorMessage
                
                // Check error message for specific error types
                if errorCode == "not-found" || errorMessage.contains("not found") || errorMessage.contains("not-found") {
                    print("⚠️ Referral code not found: \(code)")
                    UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                } else if errorCode == "failed-precondition" || errorMessage.contains("not active") || errorMessage.contains("inactive") {
                    print("⚠️ Referral code is inactive: \(code)")
                    UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                } else if errorCode == "already-exists" || errorMessage.contains("already has") || errorMessage.contains("already-exists") {
                    print("ℹ️ User already has a referral code")
                    UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                } else if errorCode == "invalid-argument" || errorMessage.contains("Invalid") || errorMessage.contains("invalid-argument") {
                    print("⚠️ Invalid referral code format: \(code)")
                UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                } else if errorCode == "unauthenticated" || errorMessage.contains("authenticated") || nsError.code == 16 {
                    print("⚠️ User not authenticated")
                    // Keep code for retry after re-authentication
                } else {
                    print("❌ Referral claim failed: \(errorMessage)")
                    print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
                    print("   Details: \(errorDetails)")
                    // Keep code for retry on other errors (network, etc.)
                }
            } else {
                // Not a Firebase Functions error - might be network error
                print("❌ Referral claim failed: \(errorMessage)")
                print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
                // Keep code for retry on network/unknown errors
            }
        }
    }
}
