//
//  InlineDeletion.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/10/25.
//

import SwiftUI

struct InlineDeletion: View {
    let isEditing: Bool
    let delete: () -> Void

    var body: some View {
        if isEditing {
            Button(role: .destructive) {
                withAnimation { delete() }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
