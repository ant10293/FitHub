//
//  BaseAttributor.swift
//  FitHub
//
//  Base class for attribution logic shared between AffiliateAttributor and ReferralAttributor
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import UIKit

/// Configuration for attribution behavior
protocol AttributorConfig {
    /// The UserDefaults key for the pending token/code
    var pendingTokenKey: String { get }

    /// The UserDefaults key for the token source
    var pendingTokenSourceKey: String { get }

    /// The UserDefaults key for tracking if server was checked
    var hasCheckedServerKey: String { get }

    /// The Cloud Function name for getting pending token from server
    var getPendingFunctionName: String { get }

    /// The Cloud Function name for claiming the token
    var claimFunctionName: String { get }

    /// The response key for the token in the server response
    var tokenResponseKey: String { get }

    /// The parameter key for the token when calling the claim function (e.g., "linkToken" or "referralCode")
    var claimParameterKey: String { get }

    /// The log prefix for debugging
    var logPrefix: String { get }

    /// Validates the token format client-side
    func validateToken(_ token: String) -> Bool

    /// Normalizes the token (e.g., uppercase, trim)
    func normalizeToken(_ token: String) -> String

    /// Handles successful claim response
    func handleClaimSuccess(data: [String: Any], token: String) async

    /// Handles specific error cases
    func handleError(error: NSError, token: String) -> Bool

    /// Optional: Check for restoration (e.g., restore premium)
    func restoreIfNeeded() async
}

/// Base class for attribution logic
class BaseAttributor {
    public enum ClaimSource: String {
        case universalLink = "universal_link"
        case manualEntry = "manual_entry"
        case serverStored = "server_stored"
    }

    let config: AttributorConfig

    init(config: AttributorConfig) {
        self.config = config
    }

    /// Gets the browser device fingerprint via WKWebView (same as landing page generates)
    /// This is shared across all attributors to avoid duplicate work
    static func getBrowserFingerprint() async -> String? {
        print("📱 [BaseAttributor] Getting browser device fingerprint...")

        // Try to get from UserDefaults first (cached)
        if let cached = UserDefaults.standard.string(forKey: "browserDeviceFingerprint"), !cached.isEmpty {
            print("📱 [BaseAttributor] Using cached browser fingerprint: \(cached.prefix(20))...")
            return cached
        }

        // Get from browser via WKWebView (reuse DeviceFingerprintManager)
        if let fingerprint = await DeviceFingerprintManager.shared.getBrowserFingerprint() {
            UserDefaults.standard.set(fingerprint, forKey: "browserDeviceFingerprint")
            print("✅ [BaseAttributor] Retrieved browser fingerprint: \(fingerprint.prefix(20))...")
            return fingerprint
        } else {
            print("⚠️ [BaseAttributor] Failed to retrieve browser fingerprint")
            return nil
        }
    }

    /// Checks server for pending token and stores it locally if found
    func checkServerForPendingToken(deviceFingerprint: String) async -> String? {
        print("🔍 [\(config.logPrefix)] Checking server for pending token...")

        let functions = Functions.functions()
        let getPendingFunction = functions.httpsCallable(config.getPendingFunctionName)

        let params: [String: Any] = ["deviceFingerprint": deviceFingerprint]

        print("📤 [\(config.logPrefix)] Calling \(config.getPendingFunctionName) with fingerprint: \(deviceFingerprint.prefix(20))...")

        do {
            let result = try await getPendingFunction.call(params)
            print("📥 [\(config.logPrefix)] Received response from \(config.getPendingFunctionName)")

            if let data = result.data as? [String: Any] {
                print("📦 [\(config.logPrefix)] Response data: \(data)")
                let success = data["success"] as? Bool ?? false

                if success, let token = data[config.tokenResponseKey] as? String, !token.isEmpty {
                    // Store in UserDefaults so claimIfNeeded can process it
                    UserDefaults.standard.set(token, forKey: config.pendingTokenKey)
                    UserDefaults.standard.set(ClaimSource.serverStored.rawValue, forKey: config.pendingTokenSourceKey)
                    UserDefaults.standard.synchronize()
                    print("✅ [\(config.logPrefix)] Retrieved pending token from server: \(token)")
                    return token
                } else {
                    let reason = data["reason"] as? String ?? "unknown"
                    print("ℹ️ [\(config.logPrefix)] No pending token found. Reason: \(reason)")
                }
            } else {
                print("⚠️ [\(config.logPrefix)] Unexpected response format from \(config.getPendingFunctionName)")
            }
        } catch {
            print("❌ [\(config.logPrefix)] Failed to check server for pending token: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain), code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
        }

        return nil
    }

    /// Attempts to claim a token once; safe to call multiple times (idempotent).
    /// Uses Cloud Function for server-side validation to prevent bypassing client-side checks.
    func claimIfNeeded(deviceFingerprint: String?) async {
        print("🚀 [\(config.logPrefix)] claimIfNeeded called")

        // Must be signed in
        guard let userId = AuthService.getUid() else {
            print("⚠️ [\(config.logPrefix)] User not authenticated, skipping claim")
            return
        }
        print("✅ [\(config.logPrefix)] User authenticated: \(userId)")

        // Check if there's already a token in UserDefaults (from universal link or manual entry)
        let existingToken = UserDefaults.standard.string(forKey: config.pendingTokenKey)
        let existingSource = UserDefaults.standard.string(forKey: config.pendingTokenSourceKey)

        // First check server for pending tokens (for deferred deep linking)
        // Only check once per app launch to avoid unnecessary calls
        // Only check server if there's no existing token in UserDefaults (prioritize universal link/manual entry)
        if existingToken == nil || existingToken?.isEmpty == true {
            let hasCheckedServer = UserDefaults.standard.bool(forKey: config.hasCheckedServerKey)
            print("🔍 [\(config.logPrefix)] Has checked server before: \(hasCheckedServer)")

            if !hasCheckedServer {
                print("📡 [\(config.logPrefix)] Checking server for pending token...")
                let fingerprint: String?
                if let provided = deviceFingerprint {
                    fingerprint = provided
                } else {
                    fingerprint = await Self.getBrowserFingerprint()
                }
                if let fingerprint = fingerprint {
                    _ = await checkServerForPendingToken(deviceFingerprint: fingerprint)
                }
                UserDefaults.standard.set(true, forKey: config.hasCheckedServerKey)
            } else {
                print("ℹ️ [\(config.logPrefix)] Already checked server, skipping")
            }
        } else if let existing = existingToken, !existing.isEmpty {
            print("ℹ️ [\(config.logPrefix)] Existing token found in UserDefaults (source: \(existingSource ?? "unknown")), skipping server check to preserve it")
        }

        // Pending token saved by the URL handler, manual entry, or server
        guard let raw = UserDefaults.standard.string(forKey: config.pendingTokenKey) else {
            print("ℹ️ [\(config.logPrefix)] No pending token found in UserDefaults")
            // If no pending token, check if restoration is needed
            await config.restoreIfNeeded()
            return
        }
        print("📝 [\(config.logPrefix)] Found pending token in UserDefaults: \(raw)")

        let normalized = config.normalizeToken(raw)
        guard !normalized.isEmpty else {
            print("⚠️ [\(config.logPrefix)] Pending token is empty after normalization")
            UserDefaults.standard.removeObject(forKey: config.pendingTokenKey)
            UserDefaults.standard.removeObject(forKey: config.pendingTokenSourceKey)
            return
        }

        // Validate token format client-side (early rejection for invalid format)
        guard config.validateToken(normalized) else {
            print("⚠️ [\(config.logPrefix)] Invalid token format: \(normalized)")
            UserDefaults.standard.removeObject(forKey: config.pendingTokenKey)
            UserDefaults.standard.removeObject(forKey: config.pendingTokenSourceKey)
            return
        }
        print("✅ [\(config.logPrefix)] Token format is valid")

        // Get the source from UserDefaults (stored when token was saved)
        let sourceRaw = UserDefaults.standard.string(forKey: config.pendingTokenSourceKey) ?? ClaimSource.universalLink.rawValue
        let source = ClaimSource(rawValue: sourceRaw) ?? .universalLink
        print("📋 [\(config.logPrefix)] Claiming with source: \(source.rawValue)")

        // Use Cloud Function for server-side validation and atomic claim
        print("📤 [\(config.logPrefix)] Calling \(config.claimFunctionName) Cloud Function...")
        let functions = Functions.functions()
        let claimFunction = functions.httpsCallable(config.claimFunctionName)

        do {
            let claimParams: [String: Any] = [
                config.claimParameterKey: normalized,
                "source": source.rawValue
            ]

            let result = try await claimFunction.call(claimParams)
            print("📥 [\(config.logPrefix)] Received response from \(config.claimFunctionName)")

            // Parse response
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool, success {
                let alreadyClaimed = data["alreadyClaimed"] as? Bool ?? false

                if alreadyClaimed {
                    print("ℹ️ [\(config.logPrefix)] Token already claimed: \(normalized)")
                } else {
                    print("✅ [\(config.logPrefix)] Successfully claimed token: \(normalized)")
                }

                // Handle success (e.g., grant premium, etc.)
                await config.handleClaimSuccess(data: data, token: normalized)

                // Clear pending token and source on success
                UserDefaults.standard.removeObject(forKey: config.pendingTokenKey)
                UserDefaults.standard.removeObject(forKey: config.pendingTokenSourceKey)
            } else {
                print("⚠️ [\(config.logPrefix)] Unexpected response from \(config.claimFunctionName)")
                // Keep token for retry
            }

        } catch {
            // Handle Firebase Functions errors
            let nsError = error as NSError
            let errorMessage = nsError.localizedDescription

            // Check if config handles the error
            if config.handleError(error: nsError, token: normalized) {
                return
            }

            // Check error domain and code
            if nsError.domain.contains("Functions") || nsError.domain.contains("functions") {
                // Extract error code from userInfo if available
                let errorCode = nsError.userInfo["code"] as? String ?? ""
                let errorDetails = nsError.userInfo["NSLocalizedDescription"] as? String ?? errorMessage

                // Check error message for specific error types
                if errorCode == "not-found" || errorMessage.contains("not found") || errorMessage.contains("not-found") {
                    print("⚠️ [\(config.logPrefix)] Token not found: \(normalized)")
                    UserDefaults.standard.removeObject(forKey: config.pendingTokenKey)
                } else if errorCode == "invalid-argument" || errorMessage.contains("Invalid") || errorMessage.contains("invalid-argument") {
                    print("⚠️ [\(config.logPrefix)] Invalid token format: \(normalized)")
                    UserDefaults.standard.removeObject(forKey: config.pendingTokenKey)
                } else if errorCode == "unauthenticated" || errorMessage.contains("authenticated") || nsError.code == 16 {
                    print("⚠️ [\(config.logPrefix)] User not authenticated")
                    // Keep token for retry after re-authentication
                } else {
                    print("❌ [\(config.logPrefix)] Claim failed: \(errorMessage)")
                    print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
                    print("   Details: \(errorDetails)")
                    // Keep token for retry on other errors (network, etc.)
                }
            } else {
                // Not a Firebase Functions error - might be network error
                print("❌ [\(config.logPrefix)] Claim failed: \(errorMessage)")
                print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
                // Keep token for retry on network/unknown errors
            }
        }
    }
}
