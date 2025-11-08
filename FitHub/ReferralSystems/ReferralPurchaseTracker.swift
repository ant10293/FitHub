//
//  ReferralPurchaseTracker.swift
//  FitHub
//
//  Tracks when users with referral codes purchase subscriptions
//  Call this after a successful subscription purchase
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Tracks subscription purchases for referral code attribution
final class ReferralPurchaseTracker {
    private let db = Firestore.firestore()
    
    /// Call this after a successful subscription purchase
    /// - Parameters:
    ///   - productID: The product ID that was purchased (monthly, yearly, lifetime)
    ///   - transactionID: The StoreKit transaction ID
    ///   - originalTransactionID: The original transaction ID (used to link Apple webhooks to users)
    ///   - environment: The transaction environment ("Production" or "Sandbox")
    func trackPurchase(productID: String, transactionID: UInt64, originalTransactionID: UInt64, environment: String) async {
        // Must be signed in        
        guard let userId = AuthService.getUid() else {
            print("⚠️ Cannot track referral purchase: user not authenticated")
            return
        }
        
        // Get referral code (from UserDefaults or Firestore)
        guard let code = await ReferralRetriever.getClaimedCode() else {
            print("ℹ️ No referral code claimed, skipping purchase tracking")
            return
        }
        
        do {
            // Get referral code info
            let codeRef = db.collection("referralCodes").document(code.uppercased())
            let codeDoc = try await codeRef.getDocument()
            
            guard codeDoc.exists else {
                print("⚠️ Referral code not found: \(code)")
                return
            }
            
            // Determine subscription type for compensation tracking
            let subscriptionType = PremiumStore.ID.membershipType(for: productID)
            
            guard subscriptionType != .free else { return }
            
            // Check if this purchase was already tracked
            let userRef = db.collection("users").document(userId)
            let userDoc = try await userRef.getDocument()
            
            if let existingPurchaseProductID = userDoc.data()?["referralPurchaseProductID"] as? String,
               existingPurchaseProductID == productID {
                print("ℹ️ Purchase already tracked for product: \(productID)")
                return
            }
            
            // Get the user's current subscription type (if any) to remove from old active array
            let currentSubscriptionType = PremiumStore.ID.membershipType(for: userDoc.data()?["referralPurchaseProductID"] as? String)
            
            // Perform the tracking in a batch
            let batch = db.batch()
            
            // 1. Update referral code document - track purchases by type
            var updateData: [String: Any] = ["lastPurchaseAt": FieldValue.serverTimestamp()]
            
            // Remove user from old active subscription array (if they had a different subscription)
            if currentSubscriptionType != .free && currentSubscriptionType != subscriptionType {
                switch currentSubscriptionType {
                case .monthly:
                    updateData["activeMonthlySubscriptions"] = FieldValue.arrayRemove([userId])
                case .yearly:
                    updateData["activeAnnualSubscriptions"] = FieldValue.arrayRemove([userId])
                case .free, .lifetime:
                    break
                }
            }
            
            // Add to the appropriate array based on subscription type
            // Also add to active subscriptions (assumed active on purchase)
            switch subscriptionType {
            case .monthly:
                updateData["monthlyPurchasedBy"] = FieldValue.arrayUnion([userId])
                updateData["activeMonthlySubscriptions"] = FieldValue.arrayUnion([userId])
            case .yearly:
                updateData["annualPurchasedBy"] = FieldValue.arrayUnion([userId])
                updateData["activeAnnualSubscriptions"] = FieldValue.arrayUnion([userId])
            case .lifetime:
                updateData["lifetimePurchasedBy"] = FieldValue.arrayUnion([userId])
                updateData["activeLifetimeSubscriptions"] = FieldValue.arrayUnion([userId])
            case .free:
                break
            }
            
            batch.updateData(updateData, forDocument: codeRef)
            
            // 2. Update user document to mark that they purchased
            // CRITICAL: Store originalTransactionID so webhooks can link back to user
            batch.updateData([
                "referralCodeUsedForPurchase": true,
                "referralPurchaseDate": FieldValue.serverTimestamp(),
                "referralPurchaseProductID": productID,
                "subscriptionStatus": [
                    "originalTransactionID": String(originalTransactionID),
                    "transactionID": String(transactionID),
                    "productID": productID,
                    "isActive": true,  // Assume active on purchase
                    "lastValidatedAt": FieldValue.serverTimestamp(),
                    "environment": environment  // "Production", "Sandbox", or "XCODE" (XCODE won't receive webhooks)
                ]
            ], forDocument: userRef)
            
            try await batch.commit()
            
            print("✅ Successfully tracked \(subscriptionType.rawValue) purchase for referral code: \(code)")
            
        } catch {
            print("❌ Failed to track referral purchase: \(error.localizedDescription)")
        }
    }
}

