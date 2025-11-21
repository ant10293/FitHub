//
//  StripeAffiliateStatus.swift
//  FitHub
//
//  Created by GPT-5 Codex on 11/10/25.
//

import Foundation

struct StripeAffiliateStatus: Equatable {
    var accountId: String?
    var detailsSubmitted: Bool
    var payoutsEnabled: Bool
    var requirementsDue: [String]
    var lastStripeSyncAt: Date?
    var lastOnboardingAt: Date?
    var lastDashboardLinkAt: Date?

    static let empty = StripeAffiliateStatus(
        accountId: nil,
        detailsSubmitted: false,
        payoutsEnabled: false,
        requirementsDue: [],
        lastStripeSyncAt: nil,
        lastOnboardingAt: nil,
        lastDashboardLinkAt: nil
    )

    var isConnected: Bool {
        accountId != nil 
    }

    var needsAction: Bool {
        !requirementsDue.isEmpty
    }
    
    var statusDescription: String {
        if payoutsEnabled {
            return "Payouts are enabled for your Stripe account. You're ready to receive earnings."
        }
        if detailsSubmitted {
            return "Stripe is reviewing your account details. You can reopen onboarding if you need to update anything."
        }
        if isConnected {
            return "Stripe account created. Complete onboarding to enable payouts."
        }
        return "Connect your Stripe account to receive affiliate payouts."
    }
    
    var primaryButtonTitle: String {
        if payoutsEnabled {
            return "Manage Stripe Account"
        }
        if detailsSubmitted || isConnected {
            return "Continue Stripe Setup"
        }
        return "Connect Stripe Account"
    }
}

