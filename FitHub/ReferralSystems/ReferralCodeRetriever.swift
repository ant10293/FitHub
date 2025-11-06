//
//  ReferralCodeRetriever.swift
//  FitHub
//
//  Utility to retrieve referral code from UserDefaults (pending) or Firestore (claimed)
//

import Foundation
import FirebaseFirestore

/// Utility to retrieve referral codes from various sources
enum ReferralCodeRetriever {
    static func getCreatedReferralCode() async throws -> String? {
        guard let userId = AuthService.getUid() else { return nil }

        let db = Firestore.firestore()
        let snapshot = try await db.collection("referralCodes")
            .whereField("createdBy", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        guard let code = snapshot.documents.first?.documentID else { return nil }
        print("✅ User \(userId) has referral code: \(code)")
        return code.trimmed.uppercased()
    }
    
    static func getClaimedReferralCode() async -> String? {
        guard let userId = AuthService.getUid() else { return nil }
        
        do {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(userId)
            let userDoc = try await userRef.getDocument()
            
            if let referralCode = userDoc.data()?["referralCode"] as? String, !referralCode.isEmpty {
                return referralCode.trimmed.uppercased()
            }
        } catch {
            print("⚠️ Failed to retrieve referral code from Firestore: \(error.localizedDescription)")
        }
        
        return nil
    }
}


