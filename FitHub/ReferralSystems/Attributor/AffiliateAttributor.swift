//
//  AffiliateAttributor.swift
//  FitHub
//
//  UPDATED VERSION - Uses Cloud Function for server-side validation
//  Similar to ReferralAttributor but grants premium access
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import UIKit

/// Call right after a successful sign-in.
/// It reads "pendingAffiliateLinkToken" (if any) and claims it via Cloud Function with server-side validation.
/// Grants premium access upon successful claim.
final class AffiliateAttributor {
    public enum ClaimSource: String {
        case universalLink = "universal_link"
        case manualEntry = "manual_entry"
        case serverStored = "server_stored"
    }
    
    /// Gets the browser device fingerprint via WKWebView (same as landing page generates)
    static func getBrowserFingerprint() async -> String? {
        print("📱 [AffiliateAttributor] Getting browser device fingerprint...")
        
        // Try to get from UserDefaults first (cached)
        if let cached = UserDefaults.standard.string(forKey: "browserDeviceFingerprint"), !cached.isEmpty {
            print("📱 [AffiliateAttributor] Using cached browser fingerprint: \(cached.prefix(20))...")
            return cached
        }
        
        // Get from browser via WKWebView (reuse DeviceFingerprintManager)
        if let fingerprint = await DeviceFingerprintManager.shared.getBrowserFingerprint() {
            UserDefaults.standard.set(fingerprint, forKey: "browserDeviceFingerprint")
            print("✅ [AffiliateAttributor] Retrieved browser fingerprint: \(fingerprint.prefix(20))...")
            return fingerprint
        } else {
            print("⚠️ [AffiliateAttributor] Failed to retrieve browser fingerprint")
            return nil
        }
    }
    
    /// Checks server for pending affiliate link and stores it locally if found
    static func checkServerForPendingLink() async -> String? {
        print("🔍 [AffiliateAttributor] Checking server for pending affiliate link...")
        
        guard let deviceFingerprint = await getBrowserFingerprint() else {
            print("⚠️ [AffiliateAttributor] Cannot check server without browser fingerprint")
            return nil
        }
        
        let functions = Functions.functions()
        let getPendingFunction = functions.httpsCallable("getPendingAffiliateLink")
        
        let params: [String: Any] = ["deviceFingerprint": deviceFingerprint]
        
        print("📤 [AffiliateAttributor] Calling getPendingAffiliateLink with fingerprint: \(deviceFingerprint.prefix(20))...")
        
        do {
            let result = try await getPendingFunction.call(params)
            print("📥 [AffiliateAttributor] Received response from getPendingAffiliateLink")
            
            if let data = result.data as? [String: Any] {
                print("📦 [AffiliateAttributor] Response data: \(data)")
                let success = data["success"] as? Bool ?? false
                
                if success, let linkToken = data["linkToken"] as? String, !linkToken.isEmpty {
                    // Store in UserDefaults so claimIfNeeded can process it
                    UserDefaults.standard.set(linkToken, forKey: "pendingAffiliateLinkToken")
                    UserDefaults.standard.set(ClaimSource.serverStored.rawValue, forKey: "pendingAffiliateLinkSource")
                    UserDefaults.standard.synchronize()
                    print("✅ [AffiliateAttributor] Retrieved pending affiliate link from server: \(linkToken)")
                    return linkToken
                } else {
                    let reason = data["reason"] as? String ?? "unknown"
                    print("ℹ️ [AffiliateAttributor] No pending affiliate link found. Reason: \(reason)")
                }
            } else {
                print("⚠️ [AffiliateAttributor] Unexpected response format from getPendingAffiliateLink")
            }
        } catch {
            print("❌ [AffiliateAttributor] Failed to check server for pending affiliate link: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain), code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
        }
        
        return nil
    }
    
    /// Checks if user has already claimed an affiliate link and restores premium access
    static func restorePremiumIfClaimed() async {
        print("🔍 [AffiliateAttributor] Checking for previously claimed affiliate link...")
        
        guard let userId = AuthService.getUid() else {
            print("⚠️ [AffiliateAttributor] User not authenticated, skipping restore check")
            return
        }
        
        let functions = Functions.functions()
        let restoreFunction = functions.httpsCallable("restoreAffiliatePremium")
        
        print("📤 [AffiliateAttributor] Calling restoreAffiliatePremium...")
        
        do {
            let result = try await restoreFunction.call([:])
            print("📥 [AffiliateAttributor] Received response from restoreAffiliatePremium")
            
            if let data = result.data as? [String: Any] {
                let success = data["success"] as? Bool ?? false
                
                if success {
                    let premiumGranted = data["premiumGranted"] as? Bool ?? false
                    let alreadyHadPremium = data["alreadyHadPremium"] as? Bool ?? false
                    
                    if let linkToken = data["linkToken"] as? String, !linkToken.isEmpty {
                        if premiumGranted {
                            print("🎉 [AffiliateAttributor] Premium access restored from previously claimed affiliate link: \(linkToken)")
                        } else if alreadyHadPremium {
                            print("ℹ️ [AffiliateAttributor] User already has premium from affiliate link: \(linkToken)")
                        }
                    } else {
                        print("ℹ️ [AffiliateAttributor] No link token in response")
                    }
                } else {
                    let reason = data["reason"] as? String ?? "unknown"
                    print("ℹ️ [AffiliateAttributor] No previously claimed affiliate link found. Reason: \(reason)")
                }
            } else {
                print("⚠️ [AffiliateAttributor] Unexpected response format from restoreAffiliatePremium")
            }
        } catch {
            print("❌ [AffiliateAttributor] Failed to restore affiliate premium: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain), code: \(nsError.code)")
            }
        }
    }

    /// Attempts to claim an affiliate link once; safe to call multiple times (idempotent).
    /// Uses Cloud Function for server-side validation to prevent bypassing client-side checks.
    /// Grants premium access upon successful claim.
    func claimIfNeeded() async {
        print("🚀 [AffiliateAttributor] claimIfNeeded called")
        
        // Must be signed in
        guard let userId = AuthService.getUid() else {
            print("⚠️ [AffiliateAttributor] User not authenticated, skipping affiliate link claim")
            return
        }
        print("✅ [AffiliateAttributor] User authenticated: \(userId)")

        // Check if there's already a token in UserDefaults (from universal link or manual entry)
        let existingToken = UserDefaults.standard.string(forKey: "pendingAffiliateLinkToken")
        let existingSource = UserDefaults.standard.string(forKey: "pendingAffiliateLinkSource")
        
        // First check server for pending links (for deferred deep linking)
        // Only check once per app launch to avoid unnecessary calls
        // Only check server if there's no existing token in UserDefaults (prioritize universal link/manual entry)
        if existingToken == nil || existingToken?.isEmpty == true {
            let hasCheckedServer = UserDefaults.standard.bool(forKey: "hasCheckedServerForPendingAffiliateLink")
            print("🔍 [AffiliateAttributor] Has checked server before: \(hasCheckedServer)")
            
            if !hasCheckedServer {
                print("📡 [AffiliateAttributor] Checking server for pending affiliate link...")
                _ = await Self.checkServerForPendingLink()
                UserDefaults.standard.set(true, forKey: "hasCheckedServerForPendingAffiliateLink")
            } else {
                print("ℹ️ [AffiliateAttributor] Already checked server, skipping")
            }
        } else if let existing = existingToken, !existing.isEmpty {
            print("ℹ️ [AffiliateAttributor] Existing token found in UserDefaults (source: \(existingSource ?? "unknown")), skipping server check to preserve it")
        }

        // Pending token saved by the URL handler, manual entry, or server
        guard let raw = UserDefaults.standard.string(forKey: "pendingAffiliateLinkToken") else {
            print("ℹ️ [AffiliateAttributor] No pending affiliate link token found in UserDefaults")
            // If no pending link, check if user has already claimed an affiliate link
            await Self.restorePremiumIfClaimed()
            return
        }
        print("📝 [AffiliateAttributor] Found pending affiliate link token in UserDefaults: \(raw)")
        let token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            print("⚠️ [AffiliateAttributor] Pending token is empty after trimming")
            UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkToken")
            UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkSource")
            return
        }
        
        // Validate token format client-side (early rejection for invalid format)
        // Token should be 16-64 alphanumeric characters
        guard token.count >= 16 && token.count <= 64 && token.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil else {
            print("⚠️ [AffiliateAttributor] Invalid affiliate link token format: \(token)")
            UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkToken")
            UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkSource")
            return
        }
        print("✅ [AffiliateAttributor] Affiliate link token format is valid")
        
        // Get the source from UserDefaults (stored when token was saved)
        let sourceRaw = UserDefaults.standard.string(forKey: "pendingAffiliateLinkSource") ?? ClaimSource.universalLink.rawValue
        let source = ClaimSource(rawValue: sourceRaw) ?? .universalLink
        print("📋 [AffiliateAttributor] Claiming with source: \(source.rawValue)")
        
        // Use Cloud Function for server-side validation and atomic claim
        print("📤 [AffiliateAttributor] Calling claimAffiliateLink Cloud Function...")
        let functions = Functions.functions()
        let claimFunction = functions.httpsCallable("claimAffiliateLink")
        
        do {
            let result = try await claimFunction.call([
                "linkToken": token,
                "source": source.rawValue
            ])
            print("📥 [AffiliateAttributor] Received response from claimAffiliateLink")
            
            // Parse response
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool, success {
                let alreadyClaimed = data["alreadyClaimed"] as? Bool ?? false
                let premiumGranted = data["premiumGranted"] as? Bool ?? false
                
                if alreadyClaimed {
                    print("ℹ️ Affiliate link already claimed: \(token)")
                } else {
                    print("✅ Successfully claimed affiliate link: \(token)")
                }
                
                if premiumGranted {
                    print("🎉 Premium access granted via affiliate link!")
                    // Refresh premium status in PremiumStore
                    Task { @MainActor in
                        // Note: PremiumStore should automatically detect the subscriptionStatus change
                        // But we can trigger a refresh if needed
                    }
                }
                
                // Clear pending token and source on success
                UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkToken")
                UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkSource")
            } else {
                print("⚠️ Unexpected response from claimAffiliateLink")
                // Keep token for retry
            }
            
        } catch {
            // Handle Firebase Functions errors
            let nsError = error as NSError
            let errorMessage = nsError.localizedDescription
            
            // Check error domain and code
            if nsError.domain.contains("Functions") || nsError.domain.contains("functions") {
                // Extract error code from userInfo if available
                let errorCode = nsError.userInfo["code"] as? String ?? ""
                let errorDetails = nsError.userInfo["NSLocalizedDescription"] as? String ?? errorMessage
                
                // Check error message for specific error types
                if errorCode == "not-found" || errorMessage.contains("not found") || errorMessage.contains("not-found") {
                    print("⚠️ Affiliate link not found: \(token)")
                    UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkToken")
                } else if errorCode == "failed-precondition" || errorMessage.contains("already been claimed") || errorMessage.contains("already claimed") {
                    print("⚠️ Affiliate link has already been claimed: \(token)")
                    UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkToken")
                } else if errorCode == "invalid-argument" || errorMessage.contains("Invalid") || errorMessage.contains("invalid-argument") {
                    print("⚠️ Invalid affiliate link token format: \(token)")
                    UserDefaults.standard.removeObject(forKey: "pendingAffiliateLinkToken")
                } else if errorCode == "unauthenticated" || errorMessage.contains("authenticated") || nsError.code == 16 {
                    print("⚠️ User not authenticated")
                    // Keep token for retry after re-authentication
                } else {
                    print("❌ Affiliate link claim failed: \(errorMessage)")
                    print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
                    print("   Details: \(errorDetails)")
                    // Keep token for retry on other errors (network, etc.)
                }
            } else {
                // Not a Firebase Functions error - might be network error
                print("❌ Affiliate link claim failed: \(errorMessage)")
                print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
                // Keep token for retry on network/unknown errors
            }
        }
    }
}



