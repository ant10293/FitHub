//
//  ReferralAttributor_Updated.swift
//  FitHub
//
//  UPDATED VERSION - Replace your existing ReferralAttributor.swift with this
//  This version writes directly to Firestore instead of calling a cloud function
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Call right after a successful sign-in.
/// It reads "pendingReferralCode" (if any) and claims it in Firestore.
final class ReferralAttributor {
    private let db = Firestore.firestore()
    
    /// Attempts to claim a referral code once; safe to call multiple times (idempotent).
    func claimIfNeeded(source: String = "universal_link") async {
        // Must be signed in
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid
        
        // Pending code saved by the URL handler
        guard let raw = UserDefaults.standard.string(forKey: "pendingReferralCode") else { return }
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }
        
        // Validate code format
        guard ReferralCodeGenerator.isValidCode(code) else {
            print("⚠️ Invalid referral code format: \(code)")
            UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
            return
        }
        
        do {
            // Check if code exists in Firestore
            let codeRef = db.collection("referralCodes").document(code)
            let codeDoc = try await codeRef.getDocument()
            
            guard codeDoc.exists, let codeData = codeDoc.data() else {
                print("⚠️ Referral code not found: \(code)")
                UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                return
            }
            
            // Check if code is active
            guard let isActive = codeData["isActive"] as? Bool, isActive else {
                print("⚠️ Referral code is inactive: \(code)")
                UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                return
            }
            
            // Check if user already used a referral code
            let userRef = db.collection("users").document(userId)
            let userDoc = try await userRef.getDocument()
            
            if let existingReferralCode = userDoc.data()?["referralCode"] as? String {
                print("ℹ️ User already has referral code: \(existingReferralCode)")
                UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                return
            }
            
            // Check if user already claimed this specific code (prevents duplicate claims)
            if let claimedCodes = userDoc.data()?["claimedReferralCodes"] as? [String],
               claimedCodes.contains(code) {
                print("ℹ️ User already claimed this code: \(code)")
                UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
                return
            }
            
            // Perform the claim in a batch transaction
            let batch = db.batch()
            
            // 1. Update user document with referral code
            batch.setData([
                "referralCode": code,
                "referralCodeClaimedAt": FieldValue.serverTimestamp(),
                "referralSource": source,
                "claimedReferralCodes": FieldValue.arrayUnion([code])
            ], forDocument: userRef, merge: true)
            
            // 2. Update referral code document - add user to sign-ups
            batch.updateData([
                "lastUsedAt": FieldValue.serverTimestamp(),
                "usedBy": FieldValue.arrayUnion([userId])
            ], forDocument: codeRef)
            
            // 3. Create a referral claim record for analytics
            let claimRef = db.collection("referralClaims").document()
            batch.setData([
                "code": code,
                "userId": userId,
                "source": source,
                "claimedAt": FieldValue.serverTimestamp(),
                "influencerName": codeData["influencerName"] as? String ?? "Unknown"
            ], forDocument: claimRef)
            
            try await batch.commit()
            
            print("✅ Successfully claimed referral code: \(code)")
            UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
            
        } catch {
            print("❌ Referral claim failed: \(error.localizedDescription)")
            // Optionally keep the code for retry, or clear it
            // UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
        }
    }
}

