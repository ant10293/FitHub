//
//  ReferralAttributor.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/28/25.
//

import Foundation
import FirebaseFunctions
import FirebaseAuth

/// Call right after a successful sign-in.
/// It reads "pendingReferralCode" (if any) and asks the backend to claim it.
/// If you don't want a backend yet, you can write directly to Firestore from here instead.
final class ReferralAttributor {
    private let functions = Functions.functions()

    /// Attempts to claim once; safe to call multiple times (idempotent on backend).
    func claimIfNeeded(source: String = "universal_link") async {
        // Must be signed in
        guard Auth.auth().currentUser != nil else { return }

        // Pending code saved by the URL handler
        guard let raw = UserDefaults.standard.string(forKey: "pendingReferralCode") else { return }
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        do {
            _ = try await functions.httpsCallable("claimReferral").call([
                "code": code,
                "source": source
            ])
            UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
        } catch {
            // Up to you: clear anyway, or keep for a single retry later
            print("Referral claim failed: \(error)")
        }
    }
}
