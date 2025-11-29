//
//  AffiliateTermsView.swift
//  FitHub
//
//  View to display affiliate program terms and conditions
//

import SwiftUI

struct AffiliateTermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LegalSheetDisplay(
            document: .affiliateTerms,
            dismiss: { dismiss() }
        )
    }
}

































