//
//  PrivacyPolicy.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct PrivacyPolicy: View {
    private let policyURLString = "privacy/"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LegalSheetDisplay(
            title: "Privacy Policy",
            URLString: policyURLString,
            dismiss: { dismiss() }
        )
    }
}
