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
        guard let userId = AuthService.getUid() else {
            print("⚠️ Cannot track referral purchase: user not authenticated")
            return
        }
        
        // Get referral code (from UserDefaults or Firestore)
        guard let code = await ReferralCodeRetriever.getClaimedReferralCode() else {
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
            
            // Check if this purchase was already tracked
            let userRef = db.collection("users").document(userId)
            let userDoc = try await userRef.getDocument()
            
            if let existingPurchaseProductID = userDoc.data()?["referralPurchaseProductID"] as? String,
               existingPurchaseProductID == productID {
                print("ℹ️ Purchase already tracked for product: \(productID)")
                return
            }
            
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
            case .yearly:
                updateData["annualPurchasedBy"] = FieldValue.arrayUnion([userId])
            case .lifetime:
                updateData["lifetimePurchasedBy"] = FieldValue.arrayUnion([userId])
            case .free:
                break
            }
            
            guard subscriptionType != .free else { return }
            
            batch.updateData(updateData, forDocument: codeRef)
            
            // 2. Update user document to mark that they purchased
            batch.updateData([
                "referralCodeUsedForPurchase": true,
                "referralPurchaseDate": FieldValue.serverTimestamp(),
                "referralPurchaseProductID": productID
            ], forDocument: userRef)
            
            try await batch.commit()
            
            print("✅ Successfully tracked \(subscriptionType.rawValue) purchase for referral code: \(code)")
            
        } catch {
            print("❌ Failed to track referral purchase: \(error.localizedDescription)")
        }
    }
}

