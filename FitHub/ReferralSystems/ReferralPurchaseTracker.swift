//
//  ReferralPurchaseTracker.swift
//  FitHub
//
//  Tracks when users with referral codes purchase subscriptions
//  Call this after a successful subscription purchase
//  Uses Cloud Function for server-side validation and atomic updates
//

import Foundation
import FirebaseAuth
import FirebaseFunctions
import StoreKit

/// Tracks subscription purchases for referral code attribution
/// Uses Cloud Function for server-side validation to prevent manipulation
final class ReferralPurchaseTracker {
    /// Call this after a successful subscription purchase
    /// - Parameters:
    ///   - productID: The product ID that was purchased (monthly, yearly, lifetime)
    ///   - transactionID: The StoreKit transaction ID
    ///   - originalTransactionID: The original transaction ID (used to link Apple webhooks to users)
    ///   - environment: The transaction environment ("Production" or "Sandbox")
    func trackPurchase(productID: String, transactionID: UInt64, originalTransactionID: UInt64, environment: String) async {
        // Ensure referral code is claimed first
        await ReferralAttributor().claimIfNeeded()
        
        // Must be signed in
        guard AuthService.getUid() != nil else {
            print("⚠️ Cannot track referral purchase: user not authenticated")
            return
        }
        
        // Validate product ID
        let subscriptionType = PremiumStore.ID.membershipType(for: productID)
        guard subscriptionType != .free else {
            print("ℹ️ Not a premium product, skipping purchase tracking")
            return
        }
        
        // Validate transaction before tracking
        guard await validateTransaction(transactionID: transactionID, originalTransactionID: originalTransactionID, productID: productID) else {
            print("⚠️ Transaction validation failed, skipping purchase tracking")
            return
        }
        
        // Use Cloud Function for server-side validation and atomic tracking
        let functions = Functions.functions()
        let trackFunction = functions.httpsCallable("trackReferralPurchase")
        
        do {
            let result = try await trackFunction.call([
                "productID": productID,
                "transactionID": String(transactionID),
                "originalTransactionID": String(originalTransactionID),
                "environment": environment
            ])
            
            // Parse response
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool, success {
                // Check if purchase was tracked on another account
                if let trackedOnOtherAccount = data["trackedOnOtherAccount"] as? Bool, trackedOnOtherAccount {
                    let originalAccountId = data["originalAccountId"] as? String ?? "unknown account"
                    let trackedProductID = data["productID"] as? String ?? productID
                    let message = data["message"] as? String ?? "This subscription is already associated with another account."
                    
                    print("ℹ️ \(message)")
                    print("   Product: \(trackedProductID)")
                    print("   Tracked on account: \(originalAccountId)")
                } else {
                    // Normal tracking success
                    let alreadyTracked = data["alreadyTracked"] as? Bool ?? false
                    let referralCode = data["referralCode"] as? String ?? "unknown"
                    
                    if alreadyTracked {
                        print("ℹ️ Purchase already tracked for product: \(productID)")
                    } else {
                        print("✅ Successfully tracked \(subscriptionType.rawValue) purchase for referral code: \(referralCode)")
                    }
                }
            } else {
                print("⚠️ Unexpected response from trackReferralPurchase")
            }
            
        } catch {
            // Handle Firebase Functions errors
            let nsError = error as NSError
            let errorMessage = nsError.localizedDescription
            
            if nsError.domain.contains("Functions") || nsError.domain.contains("functions") {
                let errorCode = nsError.userInfo["code"] as? String ?? ""
                let errorDetails = nsError.userInfo["NSLocalizedDescription"] as? String ?? errorMessage
                
                if errorCode == "failed-precondition" || errorMessage.contains("no referral code") {
                    print("ℹ️ User has no referral code, skipping purchase tracking")
                } else if errorCode == "not-found" || errorMessage.contains("not found") {
                    print("⚠️ Referral code not found")
                } else if errorCode == "invalid-argument" || errorMessage.contains("Invalid") {
                    print("⚠️ Invalid purchase data: \(errorMessage)")
                } else if errorCode == "unauthenticated" || errorMessage.contains("authenticated") {
                    print("⚠️ User not authenticated")
                } else {
                    print("❌ Failed to track referral purchase: \(errorMessage)")
                    print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
                    print("   Details: \(errorDetails)")
                }
            } else {
                print("❌ Failed to track referral purchase: \(errorMessage)")
                print("   Error code: \(nsError.code), Domain: \(nsError.domain)")
            }
        }
    }
    
    /// Validates that a transaction exists, belongs to the current user, and hasn't been refunded
    /// - Parameters:
    ///   - transactionID: The StoreKit transaction ID to validate
    ///   - originalTransactionID: The original transaction ID to validate
    ///   - productID: The expected product ID
    /// - Returns: true if transaction is valid, false otherwise
    private func validateTransaction(transactionID: UInt64, originalTransactionID: UInt64, productID: String) async -> Bool {
        do {
            // Look up the transaction in StoreKit
            // First check current entitlements (most common case for recent purchases)
            var foundTransaction: StoreKit.Transaction?
            
            // Search through all current entitlements
            for await result in StoreKit.Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                
                // Check if this is the transaction we're looking for
                if transaction.id == transactionID {
                    foundTransaction = transaction
                    break
                }
                
                // Also check original transaction ID
                if transaction.originalID == originalTransactionID && transaction.productID == productID {
                    foundTransaction = transaction
                    break
                }
            }
            
            // If not found in current entitlements, check all transactions as fallback
            if foundTransaction == nil {
                for await result in StoreKit.Transaction.all {
                    guard case .verified(let transaction) = result else { continue }
                    
                    // Check if this is the transaction we're looking for
                    if transaction.id == transactionID {
                        foundTransaction = transaction
                        break
                    }
                    
                    // Also check original transaction ID
                    if transaction.originalID == originalTransactionID && transaction.productID == productID {
                        foundTransaction = transaction
                        break
                    }
                }
            }
            
            // Validate transaction exists
            guard let transaction = foundTransaction else {
                print("⚠️ Transaction \(transactionID) not found in StoreKit")
                return false
            }
            
            // Validate product ID matches
            guard transaction.productID == productID else {
                print("⚠️ Transaction product ID mismatch: expected \(productID), got \(transaction.productID)")
                return false
            }
            
            // Validate transaction hasn't been refunded
            if let revocationDate = transaction.revocationDate {
                print("⚠️ Transaction \(transactionID) was refunded on \(revocationDate)")
                return false
            }
            
            // Validate original transaction ID matches
            guard transaction.originalID == originalTransactionID else {
                print("⚠️ Original transaction ID mismatch: expected \(originalTransactionID), got \(transaction.originalID)")
                return false
            }
            
            // Additional validation: Check if transaction is still valid (not expired for subscriptions)
            if PremiumStore.ID.isSubscription(productID) {
                if let expirationDate = transaction.expirationDate {
                    if expirationDate < Date() {
                        print("⚠️ Transaction \(transactionID) has expired on \(expirationDate)")
                        // Note: We might still want to track expired subscriptions for historical purposes
                        // But we'll log a warning
                        print("ℹ️ Tracking expired subscription for historical purposes")
                    }
                }
            }
            
            print("✅ Transaction validation passed for transaction \(transactionID)")
            return true
            
        }
    }
}

