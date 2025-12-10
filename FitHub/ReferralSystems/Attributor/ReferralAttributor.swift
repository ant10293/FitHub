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

/// Configuration for referral attribution
private struct ReferralAttributorConfig: AttributorConfig {
    var pendingTokenKey: String { "pendingReferralCode" }
    var pendingTokenSourceKey: String { "pendingReferralCodeSource" }
    var hasCheckedServerKey: String { "hasCheckedServerForPendingCode" }
    var getPendingFunctionName: String { "getPendingReferralCode" }
    var claimFunctionName: String { "claimReferralCode" }
    var tokenResponseKey: String { "referralCode" }
    var claimParameterKey: String { "referralCode" }
    var logPrefix: String { "ReferralAttributor" }

    func validateToken(_ token: String) -> Bool {
        return ReferralCodeGenerator.isValidCode(token)
    }

    func normalizeToken(_ token: String) -> String {
        return token.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    func handleClaimSuccess(data: [String: Any], token: String) async {
        // No special handling needed for referral codes
    }

    func handleError(error: NSError, token: String) -> Bool {
        let errorCode = error.userInfo["code"] as? String ?? ""
        let errorMessage = error.localizedDescription

        if errorCode == "failed-precondition" || errorMessage.contains("not active") || errorMessage.contains("inactive") {
            print("⚠️ [ReferralAttributor] Referral code is inactive: \(token)")
            UserDefaults.standard.removeObject(forKey: pendingTokenKey)
            return true
        } else if errorCode == "already-exists" || errorMessage.contains("already has") || errorMessage.contains("already-exists") {
            print("ℹ️ [ReferralAttributor] User already has a referral code")
            UserDefaults.standard.removeObject(forKey: pendingTokenKey)
            return true
        }

        return false
    }

    func restoreIfNeeded() async {
        // No restoration needed for referral codes
    }
}

/// Call right after a successful sign-in.
/// It reads "pendingReferralCode" (if any) and claims it via Cloud Function with server-side validation.
final class ReferralAttributor: BaseAttributor {
    private static let config = ReferralAttributorConfig()

    init() {
        super.init(config: Self.config)
    }

    /// Attempts to claim a referral code once; safe to call multiple times (idempotent).
    /// Uses Cloud Function for server-side validation to prevent bypassing client-side checks.
    override func claimIfNeeded(deviceFingerprint: String? = nil) async {
        await super.claimIfNeeded(deviceFingerprint: deviceFingerprint)
    }
}
