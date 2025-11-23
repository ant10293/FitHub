//
//  TermsOfService.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct TermsOfService: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LegalSheetDisplay(
            document: .termsOfService,
            dismiss: { dismiss() }
        )
    }
}

