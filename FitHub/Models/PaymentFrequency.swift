//
//  PaymentFrequency.swift
//  FitHub
//
//  Defines payout cadence options for influencers.
//

import Foundation

enum PaymentFrequency: String, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case monthly
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Biweekly"
        case .monthly: return "Monthly"
        }
    }
}
