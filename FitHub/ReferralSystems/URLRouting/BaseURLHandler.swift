//
//  BaseURLHandler.swift
//  FitHub
//
//  Generic URL handler for extracting and storing tokens/codes from URLs
//  Used by both ReferralURLHandler and AffiliateURLHandler
//

import Foundation

/// Configuration for URL token extraction and storage
struct URLHandlerConfig {
    /// Path segment to match (e.g., "r" for /r/{code} or "affiliate" for /affiliate/{token})
    let pathSegment: String
    
    /// Query parameter name (e.g., "ref" or "token")
    let queryParamName: String
    
    /// UserDefaults key for storing the pending token
    let pendingTokenKey: String
    
    /// UserDefaults key for storing the source
    let pendingSourceKey: String
    
    /// Source value to store (e.g., "universal_link")
    let sourceValue: String
    
    /// Sanitization rules
    let sanitization: SanitizationConfig
    
    /// Log message prefix (e.g., "referral" or "affiliate")
    let logPrefix: String
    
    /// Token type name for logging (e.g., "code" or "link token")
    let tokenTypeName: String
}

/// Configuration for token sanitization
struct SanitizationConfig {
    /// Whether to uppercase the token
    let uppercase: Bool
    
    /// Whether to allow lowercase letters (a-z)
    let allowLowercase: Bool
    
    /// Minimum length (nil = no minimum)
    let minLength: Int?
    
    /// Maximum length (nil = no maximum)
    let maxLength: Int?
    
    static let referral = SanitizationConfig(
        uppercase: true,
        allowLowercase: false,
        minLength: nil,
        maxLength: nil
    )
    
    static let affiliate = SanitizationConfig(
        uppercase: false,
        allowLowercase: true,
        minLength: 16,
        maxLength: 64
    )
}

enum BaseURLHandler {
    /// Extracts a token/code from a URL and stores it using the provided configuration
    /// - Returns: `true` if a token was successfully extracted and stored, `false` otherwise
    @discardableResult
    static func handleIncoming(_ url: URL, config: URLHandlerConfig) -> Bool {
        if let token = extractToken(from: url, config: config) {
            UserDefaults.standard.set(token, forKey: config.pendingTokenKey)
            UserDefaults.standard.set(config.sourceValue, forKey: config.pendingSourceKey)
            UserDefaults.standard.synchronize()
            print("✅ Successfully handled \(config.logPrefix) URL: \(url.absoluteString)")
            print("📝 Pending \(config.logPrefix.capitalized) \(config.tokenTypeName) stored: \(token)")
            return true
        } else {
            print("⚠️ No \(config.logPrefix) \(config.tokenTypeName) found in URL: \(url.absoluteString)")
            return false
        }
    }
    
    /// Extracts token from URL using path-based or query-based extraction
    private static func extractToken(from url: URL, config: URLHandlerConfig) -> String? {
        // 1) Path-based extraction, e.g. /r/{CODE} or /affiliate/{TOKEN}
        let comps = url.pathComponents
        // For /r/{code}: comps = ["/", "r", "CODE"] -> count >= 3
        // For /affiliate/{token}: comps = ["/", "affiliate", "TOKEN"] -> count >= 2 (original used >= 2)
        // Match original behavior: referral requires >= 3, affiliate requires >= 2
        let minPathCount = config.pathSegment == "r" ? 3 : 2
        if comps.count >= minPathCount,
           comps[1].lowercased() == config.pathSegment.lowercased() {
            return sanitize(comps.last, config: config.sanitization)
        }
        
        // 2) Query-based extraction, e.g. ?ref=CODE or ?token=TOKEN
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let raw = items.first(where: { $0.name.lowercased() == config.queryParamName.lowercased() })?.value {
            return sanitize(raw, config: config.sanitization)
        }
        
        return nil
    }
    
    /// Sanitizes token according to configuration rules
    private static func sanitize(_ raw: String?, config: SanitizationConfig) -> String? {
        guard let r = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !r.isEmpty else { return nil }
        
        // Apply uppercase if needed
        let normalized = config.uppercase ? r.uppercased() : r
        
        // Filter allowed characters
        let filtered = normalized.unicodeScalars.filter { c in
            let value = c.value
            return (value >= 48 && value <= 57)  // 0-9
                || (value >= 65 && value <= 90)  // A-Z
                || (config.allowLowercase && value >= 97 && value <= 122) // a-z (if allowed)
        }
        
        let out = String(String.UnicodeScalarView(filtered))
        
        // Validate length if constraints are specified
        if let min = config.minLength, out.count < min { return nil }
        if let max = config.maxLength, out.count > max { return nil }
        
        return out.isEmpty ? nil : out
    }
}
