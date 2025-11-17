//
//  ReferralCodeGenerator.swift
//  FitHub
//
//  Standalone utility to generate referral codes for influencers
//  This is a utility file - you can run this from a script or admin dashboard
//

import Foundation

/// Utility to generate and manage referral codes
struct ReferralCodeGenerator {
    /// Generates a unique referral code (uppercase alphanumeric, 6-8 characters)
    /// Format: [A-Z0-9]{6,8}
    static func generateCode() -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        let length = Int.random(in: 6...8)
        
        guard !characters.isEmpty else { return "" }
        
        let result = (0..<length).compactMap { _ in
            characters.randomElement()
        }
        
        return String(result)
    }
    
    /// Generates a custom code from influencer name
    /// Example: "ANTHONY" -> "ANTHONY" (if available) or "ANTHONY1"
    static func generateCodeFromName(_ name: String) -> String {
        let allowedScalars = name.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .unicodeScalars
            .filter { c in
                // 0–9 or A–Z
                (48...57).contains(c.value) || (65...90).contains(c.value)
            }
        
        let base = String(allowedScalars)
        let charset = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        
        // If base is too short, pad it with random chars (no force unwrap)
        if base.count < 4 {
            let paddingCount = 4 - base.count
            let padding = (0..<paddingCount).compactMap { _ in
                charset.randomElement()
            }
            return base + String(padding)
        }
        
        // Max 8 chars
        return String(base.prefix(8)).uppercased()
    }
    
    /// Validates a referral code format
    static func isValidCode(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count >= 4 && trimmed.count <= 10 else { return false }
        
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}

// MARK: - Example Usage
/*
// Generate random code
let code1 = ReferralCodeGenerator.generateCode() // "K7X9M2"

// Generate from name
let code2 = ReferralCodeGenerator.generateCodeFromName("Anthony Cantu") // "ANTHONYC"

// Validate
ReferralCodeGenerator.isValidCode("ANTHONY") // true
ReferralCodeGenerator.isValidCode("invalid!") // false
*/

