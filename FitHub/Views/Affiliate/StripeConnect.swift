//
//  StripeConnect.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/19/25.
//

import SwiftUI

struct StripeConnect: View {
    @Environment(\.openURL) private var openURL
    @Binding var stripeStatus: StripeAffiliateStatus
    @State private var isRequestingStripeOnboardingLink: Bool = false
    @State private var isRequestingStripeDashboardLink: Bool = false
    @State private var stripeErrorMessage: String?
    let referralCode: String
    let refreshStripeStatus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stripe Payouts")
                .font(.headline)

            Text(stripeStatus.statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if stripeStatus.needsAction {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Needed")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(stripeStatus.requirementsDue, id: \.self) { requirement in
                        Text("• \(requirement.formattedRequirement)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ErrorFooter(message: stripeErrorMessage)

            if isRequestingStripeOnboardingLink {
                ProgressView()
                    .centerHorizontally()
            } else {
                RectangularButton(
                    title: stripeStatus.primaryButtonTitle,
                    enabled: true,
                    fontWeight: .bold,
                    action: { connectStripe(for: referralCode) }
                )
            }

            if stripeStatus.isConnected {
                if isRequestingStripeDashboardLink {
                    ProgressView()
                        .centerHorizontally()
                } else {
                    // FIXME: this should not be displayed unless there is an actual stripe account linked.
                    RectangularButton(
                        title: "Open Stripe Dashboard",
                        enabled: true,
                        action: { openStripeDashboard(for: referralCode) }
                    )
                }
            }

            Button {
                refreshStripeStatus()
            } label: {
                Text("Refresh Stripe Status")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .tint(.blue)
        }
        .cardContainer(cornerRadius: 12, backgroundColor: Color(UIColor.secondarySystemBackground))
    }

    private func connectStripe(for code: String) {
        guard !isRequestingStripeOnboardingLink else { return }
        isRequestingStripeOnboardingLink = true
        stripeErrorMessage = nil

        Task {
            do {
                let onboardingLink = try await StripeAffiliateService.shared.createOnboardingLink(referralCode: code)
                await MainActor.run {
                    isRequestingStripeOnboardingLink = false
                    stripeStatus.accountId = onboardingLink.accountId
                    if let detailsSubmitted = onboardingLink.detailsSubmitted {
                        stripeStatus.detailsSubmitted = detailsSubmitted
                    }
                    if let payoutsEnabled = onboardingLink.payoutsEnabled {
                        stripeStatus.payoutsEnabled = payoutsEnabled
                    }

                    guard let linkURL = URL(string: onboardingLink.url) else {
                        stripeErrorMessage = "Received an invalid onboarding link."
                        return
                    }

                    openURL(linkURL)
                }
            } catch {
                await MainActor.run {
                    isRequestingStripeOnboardingLink = false
                    stripeErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func openStripeDashboard(for code: String) {
        guard stripeStatus.isConnected else {
            stripeErrorMessage = "Connect your Stripe account before opening the dashboard."
            return
        }
        guard !isRequestingStripeDashboardLink else { return }

        isRequestingStripeDashboardLink = true
        stripeErrorMessage = nil

        Task {
            do {
                let dashboardLink = try await StripeAffiliateService.shared.createDashboardLink(referralCode: code)
                await MainActor.run {
                    isRequestingStripeDashboardLink = false
                    stripeStatus.accountId = dashboardLink.accountId
                    if let payoutsEnabled = dashboardLink.payoutsEnabled {
                        stripeStatus.payoutsEnabled = payoutsEnabled
                    }

                    guard let linkURL = URL(string: dashboardLink.url) else {
                        stripeErrorMessage = "Received an invalid dashboard link."
                        return
                    }

                    openURL(linkURL)
                }
            } catch {
                await MainActor.run {
                    isRequestingStripeDashboardLink = false
                    stripeErrorMessage = error.localizedDescription
                }
            }
        }
    }
}
