//
//  AffiliateURLHandler.swift
//  FitHub
//
//  Created by Auto on 12/19/25.
//

import Foundation

enum AffiliateURLHandler {
    /// Extracts an affiliate link token from supported URLs and stores it for later claim.
    /// - Parameters:
    ///   - url: The URL to process
    ///   - shouldClaim: If `true` and a token is found, calls `claimIfNeeded()` asynchronously
    static func handleIncoming(_ url: URL, shouldClaim: Bool = false) {
        let config = URLHandlerConfig(
            pathSegment: "affiliate",
            queryParamName: "token",
            pendingTokenKey: "pendingAffiliateLinkToken",
            pendingSourceKey: "pendingAffiliateLinkSource",
            sourceValue: AffiliateAttributor.ClaimSource.universalLink.rawValue,
            sanitization: .affiliate,
            logPrefix: "affiliate",
            tokenTypeName: "link token"
        )
        let tokenFound = BaseURLHandler.handleIncoming(url, config: config)
        
        if shouldClaim && tokenFound {
            Task {
                await AffiliateAttributor().claimIfNeeded()
            }
        }
    }
}
