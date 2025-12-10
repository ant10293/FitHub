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

/// Configuration for affiliate attribution
private struct AffiliateAttributorConfig: AttributorConfig {
    var pendingTokenKey: String { "pendingAffiliateLinkToken" }
    var pendingTokenSourceKey: String { "pendingAffiliateLinkSource" }
    var hasCheckedServerKey: String { "hasCheckedServerForPendingAffiliateLink" }
    var getPendingFunctionName: String { "getPendingAffiliateLink" }
    var claimFunctionName: String { "claimAffiliateLink" }
    var tokenResponseKey: String { "linkToken" }
    var claimParameterKey: String { "linkToken" }
    var logPrefix: String { "AffiliateAttributor" }

    func validateToken(_ token: String) -> Bool {
        // Token should be 16-64 alphanumeric characters
        return token.count >= 16 && token.count <= 64 && token.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil
    }

    func normalizeToken(_ token: String) -> String {
        return token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func handleClaimSuccess(data: [String: Any], token: String) async {
        let premiumGranted = data["premiumGranted"] as? Bool ?? false

        if premiumGranted {
            print("🎉 [AffiliateAttributor] Premium access granted via affiliate link!")
            // Refresh premium status in PremiumStore
            Task { @MainActor in
                // Note: PremiumStore should automatically detect the subscriptionStatus change
                // But we can trigger a refresh if needed
            }
        }
    }

    func handleError(error: NSError, token: String) -> Bool {
        let errorCode = error.userInfo["code"] as? String ?? ""
        let errorMessage = error.localizedDescription

        if errorCode == "failed-precondition" || errorMessage.contains("already been claimed") || errorMessage.contains("already claimed") {
            print("⚠️ [AffiliateAttributor] Affiliate link has already been claimed: \(token)")
            UserDefaults.standard.removeObject(forKey: pendingTokenKey)
            return true
        }

        return false
    }

    func restoreIfNeeded() async {
        await restorePremiumIfClaimed()
    }

    /// Checks if user has already claimed an affiliate link and restores premium access
    private func restorePremiumIfClaimed() async {
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
}

/// Call right after a successful sign-in.
/// It reads "pendingAffiliateLinkToken" (if any) and claims it via Cloud Function with server-side validation.
/// Grants premium access upon successful claim.
final class AffiliateAttributor: BaseAttributor {
    private static let config = AffiliateAttributorConfig()

    init() {
        super.init(config: Self.config)
    }

    /// Attempts to claim an affiliate link once; safe to call multiple times (idempotent).
    /// Uses Cloud Function for server-side validation to prevent bypassing client-side checks.
    /// Grants premium access upon successful claim.
    override func claimIfNeeded(deviceFingerprint: String? = nil) async {
        await super.claimIfNeeded(deviceFingerprint: deviceFingerprint)
    }
}
