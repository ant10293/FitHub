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
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let length = Int.random(in: 6...8)
        
        return String((0..<length).map { _ in
            characters.randomElement()!
        })
    }
    
    /// Generates a custom code from influencer name
    /// Example: "ANTHONY" -> "ANTHONY" (if available) or "ANTHONY1"
    static func generateCodeFromName(_ name: String) -> String {
        let sanitized = name.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .unicodeScalars.filter { c in
                (c.value >= 48 && c.value <= 57) || (c.value >= 65 && c.value <= 90)
            }
        let base = String(sanitized)
        
        // Ensure minimum length
        if base.count < 4 {
            return base + String((0..<(4 - base.count)).map { _ in
                "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()!
            })
        }
        
        return base.prefix(8).uppercased() // Max 8 chars
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

