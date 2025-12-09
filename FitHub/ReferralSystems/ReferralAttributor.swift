//
//  ReferralAttributor.swift
//  FitHub
//
//  UPDATED VERSION - Uses Cloud Function for server-side validation
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import UIKit

/// Call right after a successful sign-in.
/// It reads "pendingReferralCode" (if any) and claims it via Cloud Function with server-side validation.
final class ReferralAttributor {
    public enum ClaimSource: String {
        case universalLink = "universal_link"
        case manualEntry = "manual_entry"
        case serverStored = "server_stored"
    }
    
    /// Gets the browser device fingerprint via WKWebView (same as landing page generates)
    static func getBrowserFingerprint() async -> String? {
        print("📱 [ReferralAttributor] Getting browser device fingerprint...")
        
        // Try to get from UserDefaults first (cached)
        if let cached = UserDefaults.standard.string(forKey: "browserDeviceFingerprint"), !cached.isEmpty {
            print("📱 [ReferralAttributor] Using cached browser fingerprint: \(cached.prefix(20))...")
            return cached
        }
        
        // Get from browser via WKWebView
        if let fingerprint = await DeviceFingerprintManager.shared.getBrowserFingerprint() {
            UserDefaults.standard.set(fingerprint, forKey: "browserDeviceFingerprint")
            print("✅ [ReferralAttributor] Retrieved browser fingerprint: \(fingerprint.prefix(20))...")
            return fingerprint
        } else {
            print("⚠️ [ReferralAttributor] Failed to retrieve browser fingerprint")
            return nil
        }
    }
    
    /// Checks server for pending referral code and stores it locally if found
    static func checkServerForPendingCode() async -> String? {
        print("🔍 [ReferralAttributor] Checking server for pending referral code...")
        
        guard let deviceFingerprint = await getBrowserFingerprint() else {
            print("⚠️ [ReferralAttributor] Cannot check server without browser fingerprint")
            return nil
        }
        
        let functions = Functions.functions()
        let getPendingFunction = functions.httpsCallable("getPendingReferralCode")
        
        let params: [String: Any] = ["deviceFingerprint": deviceFingerprint]
        
        print("📤 [ReferralAttributor] Calling getPendingReferralCode with fingerprint: \(deviceFingerprint.prefix(20))...")
        
        do {
            let result = try await getPendingFunction.call(params)
            print("📥 [ReferralAttributor] Received response from getPendingReferralCode")
            
            if let data = result.data as? [String: Any] {
                print("📦 [ReferralAttributor] Response data: \(data)")
                let success = data["success"] as? Bool ?? false
                
                if success, let referralCode = data["referralCode"] as? String, !referralCode.isEmpty {
                    // Store in UserDefaults so claimIfNeeded can process it
                    UserDefaults.standard.set(referralCode, forKey: "pendingReferralCode")
                    UserDefaults.standard.set(ClaimSource.serverStored.rawValue, forKey: "pendingReferralCodeSource")
                    UserDefaults.standard.synchronize()
                    print("✅ [ReferralAttributor] Retrieved pending referral code from server: \(referralCode)")
                    return referralCode
                } else {
                    let reason = data["reason"] as? String ?? "unknown"
                    print("ℹ️ [ReferralAttributor] No pending referral code found. Reason: \(reason)")
                }
            } else {
                print("⚠️ [ReferralAttributor] Unexpected response format from getPendingReferralCode")
            }
        } catch {
            print("❌ [ReferralAttributor] Failed to check server for pending referral code: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain), code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
        }
        
        return nil
    }

    /// Attempts to claim a referral code once; safe to call multiple times (idempotent).
    /// Uses Cloud Function for server-side validation to prevent bypassing client-side checks.
    func claimIfNeeded() async {
        print("🚀 [ReferralAttributor] claimIfNeeded called")
        
        // Must be signed in
        guard let userId = AuthService.getUid() else {
            print("⚠️ [ReferralAttributor] User not authenticated, skipping referral claim")
            return
        }
        print("✅ [ReferralAttributor] User authenticated: \(userId)")

        // Check if there's already a code in UserDefaults (from universal link or manual entry)
        let existingCode = UserDefaults.standard.string(forKey: "pendingReferralCode")
        let existingSource = UserDefaults.standard.string(forKey: "pendingReferralCodeSource")
        
        // First check server for pending codes (for deferred deep linking)
        // Only check once per app launch to avoid unnecessary calls
        // Only check server if there's no existing code in UserDefaults (prioritize universal link/manual entry)
        if existingCode == nil || existingCode?.isEmpty == true {
            let hasCheckedServer = UserDefaults.standard.bool(forKey: "hasCheckedServerForPendingCode")
            print("🔍 [ReferralAttributor] Has checked server before: \(hasCheckedServer)")
            
            if !hasCheckedServer {
                print("📡 [ReferralAttributor] Checking server for pending referral code...")
                _ = await Self.checkServerForPendingCode()
                UserDefaults.standard.set(true, forKey: "hasCheckedServerForPendingCode")
            } else {
                print("ℹ️ [ReferralAttributor] Already checked server, skipping")
            }
        } else if let existing = existingCode, !existing.isEmpty {
            print("ℹ️ [ReferralAttributor] Existing code found in UserDefaults (source: \(existingSource ?? "unknown")), skipping server check to preserve it")
        }

        // Pending code saved by the URL handler, manual entry, or server
        guard let raw = UserDefaults.standard.string(forKey: "pendingReferralCode") else {
            print("ℹ️ [ReferralAttributor] No pending referral code found in UserDefaults")
            return
        }
        print("📝 [ReferralAttributor] Found pending referral code in UserDefaults: \(raw)")
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else {
            print("⚠️ [ReferralAttributor] Pending code is empty after trimming")
            UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
            UserDefaults.standard.removeObject(forKey: "pendingReferralCodeSource")
            return
        }
        print("✨ [ReferralAttributor] Processing referral code: \(code)")

        // Validate code format client-side (early rejection for invalid format)
        guard ReferralCodeGenerator.isValidCode(code) else {
            print("⚠️ [ReferralAttributor] Invalid referral code format: \(code)")
            UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
            UserDefaults.standard.removeObject(forKey: "pendingReferralCodeSource")
            return
        }
        print("✅ [ReferralAttributor] Referral code format is valid")
        
        // Get the source from UserDefaults (stored when code was saved)
        let sourceRaw = UserDefaults.standard.string(forKey: "pendingReferralCodeSource") ?? ClaimSource.universalLink.rawValue
        let source = ClaimSource(rawValue: sourceRaw) ?? .universalLink
        print("📋 [ReferralAttributor] Claiming with source: \(source.rawValue)")
        
        // Use Cloud Function for server-side validation and atomic claim
        print("📤 [ReferralAttributor] Calling claimReferralCode Cloud Function...")
        let functions = Functions.functions()
        let claimFunction = functions.httpsCallable("claimReferralCode")
        
        do {
            let result = try await claimFunction.call([
                "referralCode": code,
                "source": source.rawValue
            ])
            print("📥 [ReferralAttributor] Received response from claimReferralCode")
            
            // Parse response
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool, success {
                let alreadyClaimed = data["alreadyClaimed"] as? Bool ?? false
                
                if alreadyClaimed {
                    print("ℹ️ Referral code already claimed: \(code)")
                } else {
                    print("✅ Successfully claimed referral code: \(code)")
                }
                
                // Clear pending code and source on success
                UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                UserDefaults.standard.removeObject(forKey: "pendingReferralCodeSource")
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
