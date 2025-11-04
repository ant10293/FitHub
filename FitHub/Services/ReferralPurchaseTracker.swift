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
    func trackPurchase(productID: String, transactionID: UInt64) async {
        // Must be signed in
        guard let user = Auth.auth().currentUser else {
            print("⚠️ Cannot track referral purchase: user not authenticated")
            return
        }
        let userId = user.uid
        
        do {
            // Get user's referral code
            let userRef = db.collection("users").document(userId)
            let userDoc = try await userRef.getDocument()
            
            guard let userData = userDoc.data(),
                  let referralCode = userData["referralCode"] as? String,
                  !referralCode.isEmpty else {
                print("ℹ️ User has no referral code, skipping purchase tracking")
                return
            }
            
            // Check if this purchase was already tracked (idempotent)
            let purchaseRef = db.collection("referralPurchases").document("\(userId)_\(transactionID)")
            let purchaseDoc = try await purchaseRef.getDocument()
            
            if purchaseDoc.exists {
                print("ℹ️ Purchase already tracked for transaction: \(transactionID)")
                return
            }
            
            // Get referral code info
            let codeRef = db.collection("referralCodes").document(referralCode.uppercased())
            let codeDoc = try await codeRef.getDocument()
            
            guard codeDoc.exists, let codeData = codeDoc.data() else {
                print("⚠️ Referral code not found: \(referralCode)")
                return
            }
            
            let influencerName = codeData["influencerName"] as? String ?? "Unknown"
            
            // Determine subscription type for compensation tracking
            let subscriptionType = getSubscriptionType(from: productID)
            
            // Perform the tracking in a batch
            let batch = db.batch()
            
            // 1. Update referral code document - track purchases by type
            var updateData: [String: Any] = [
                "lastPurchaseAt": FieldValue.serverTimestamp()
            ]
            
            // Add to the appropriate array based on subscription type
            switch subscriptionType {
            case .monthly:
                updateData["monthlyPurchasedBy"] = FieldValue.arrayUnion([userId])
            case .annual:
                updateData["annualPurchasedBy"] = FieldValue.arrayUnion([userId])
            case .lifetime:
                updateData["lifetimePurchasedBy"] = FieldValue.arrayUnion([userId])
            }
            
            batch.updateData(updateData, forDocument: codeRef)
            
            // 2. Create a purchase record for analytics/compensation
            batch.setData([
                "code": referralCode.uppercased(),
                "userId": userId,
                "productID": productID,
                "subscriptionType": subscriptionType.rawValue,
                "transactionID": String(transactionID),
                "purchasedAt": FieldValue.serverTimestamp(),
                "influencerName": influencerName
            ], forDocument: purchaseRef)
            
            // 3. Update user document to mark that they purchased
            batch.updateData([
                "referralCodeUsedForPurchase": true,
                "referralPurchaseDate": FieldValue.serverTimestamp(),
                "referralPurchaseProductID": productID
            ], forDocument: userRef)
            
            try await batch.commit()
            
            print("✅ Successfully tracked \(subscriptionType.rawValue) purchase for referral code: \(referralCode)")
            
        } catch {
            print("❌ Failed to track referral purchase: \(error.localizedDescription)")
        }
    }
    
    /// Determines subscription type from product ID
    private func getSubscriptionType(from productID: String) -> SubscriptionType {
        switch productID {
        case PremiumStore.ID.monthly:
            return .monthly
        case PremiumStore.ID.yearly:
            return .annual
        case PremiumStore.ID.lifetime:
            return .lifetime
        default:
            return .monthly // Default fallback
        }
    }
    
    /// Subscription type enum for tracking
    private enum SubscriptionType: String {
        case monthly = "monthly"
        case annual = "annual"
        case lifetime = "lifetime"
    }
}

