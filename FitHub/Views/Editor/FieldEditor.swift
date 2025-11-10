//
//  FieldEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/10/25.
//

import SwiftUI

struct FieldEditor: View {
    let title: String
    let valueText: String
    let isEmpty: Bool
    let isReadOnly: Bool
    let buttonLabel: String
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            (
                Text("\(title): ")
                    .font(.headline)
                +
                Text(valueText)
                    .foregroundStyle(isEmpty ? .secondary : .primary)
            )
            .multilineTextAlignment(.leading)

            if !isReadOnly {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: isEmpty ? "plus" : "square.and.pencil")
                        Text(buttonLabel)
                    }
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }
        }
    }
}
