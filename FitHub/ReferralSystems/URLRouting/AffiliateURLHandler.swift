//
//  AffiliateURLHandler.swift
//  FitHub
//
//  Created by Auto on 12/19/25.
//

import Foundation

enum AffiliateURLHandler {
    /// Extracts an affiliate link token from supported URLs and stores it for later claim.
    static func handleIncoming(_ url: URL) {
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
        GenericURLHandler.handleIncoming(url, config: config)
    }
}
