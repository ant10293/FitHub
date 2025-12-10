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
        let config = URLHandlerConfig(
            pathSegment: "r",
            queryParamName: "ref",
            pendingTokenKey: "pendingReferralCode",
            pendingSourceKey: "pendingReferralCodeSource",
            sourceValue: ReferralAttributor.ClaimSource.universalLink.rawValue,
            sanitization: .referral,
            logPrefix: "referral",
            tokenTypeName: "code"
        )
        BaseURLHandler.handleIncoming(url, config: config)
    }
}
