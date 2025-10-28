//
//  ReferralURLHandler.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/28/25.
//

import Foundation

enum ReferralURLHandler {
    /// Extracts a referral code from supported URLs and stores it for later claim.
    static func handleIncoming(_ url: URL) {
        if let code = extractCode(from: url) {
            UserDefaults.standard.set(code, forKey: "pendingReferralCode")
            UserDefaults.standard.synchronize()
        }
    }

    /// Support both /r/{CODE} and ?ref=CODE shapes, case-insensitive, A–Z0–9 only.
    private static func extractCode(from url: URL) -> String? {
        // 1) Path-based, e.g. https://your.site/r/ANTHONY
        let comps = url.pathComponents
        if comps.count >= 3, comps[1].lowercased() == "r" {
            return sanitize(comps.last)
        }

        // 2) Query-based, e.g. https://your.site/somepath?ref=ANTHONY
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let raw = items.first(where: { $0.name.lowercased() == "ref" })?.value {
            return sanitize(raw)
        }

        return nil
    }

    /// Uppercase and strip everything except A–Z0–9.
    private static func sanitize(_ raw: String?) -> String? {
        guard let r = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !r.isEmpty else { return nil }
        let up = r.uppercased()
        let filtered = up.unicodeScalars.filter { c in
            (c.value >= 48 && c.value <= 57)  // 0-9
            || (c.value >= 65 && c.value <= 90) // A-Z
        }
        let out = String(String.UnicodeScalarView(filtered))
        return out.isEmpty ? nil : out
    }
}
