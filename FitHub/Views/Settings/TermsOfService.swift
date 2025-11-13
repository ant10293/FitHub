//
//  TermsOfService.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct TermsOfService: View {
    private let termsURLString = "terms/"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LegalSheetDisplay(
            title: "Terms of Service",
            URLString: termsURLString,
            dismiss: { dismiss() }
        )
    }
}

