//
//  ReferralStats.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/19/25.
//

import SwiftUI

struct ReferralStats: View {
    let isLoadingStats: Bool
    let codeStats: CodeStats?

    var body: some View {
        if isLoadingStats {
            ProgressView()
                .centerHorizontally()
        } else if let stats = codeStats {
            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)

                StatRow(label: "Sign-ups", value: "\(stats.signUps)")
                StatRow(label: "Monthly Purchases", value: "\(stats.monthlyPurchases)")
                StatRow(label: "Annual Purchases", value: "\(stats.annualPurchases)")
                StatRow(label: "Lifetime Purchases", value: "\(stats.lifetimePurchases)")

                if let lastUsed = stats.lastUsedAt {
                    StatRow(label: "Last Sign-up", value: Format.formatDate(lastUsed, dateStyle: .medium, timeStyle: .short))
                }

                if let lastPurchase = stats.lastPurchaseAt {
                    StatRow(label: "Last Purchase", value: Format.formatDate(lastPurchase, dateStyle: .medium, timeStyle: .short))
                }
            }
            .cardContainer(cornerRadius: 12, backgroundColor: Color(UIColor.secondarySystemBackground))
        }
    }
}

// MARK: - Supporting Types
struct CodeStats {
    let signUps: Int
    let monthlyPurchases: Int
    let annualPurchases: Int
    let lifetimePurchases: Int
    let lastUsedAt: Date?
    let lastPurchaseAt: Date?

    static var blankStats: CodeStats = .init(
        signUps: 0,
        monthlyPurchases: 0,
        annualPurchases: 0,
        lifetimePurchases: 0,
        lastUsedAt: nil,
        lastPurchaseAt: nil
    )
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}
