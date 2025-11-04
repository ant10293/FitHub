//
//  DescriptionField.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/10/25.
//

import SwiftUI

struct DescriptionField: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    var placeholder: String = "Description"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(placeholder)
                .font(.headline)
            TextEditor(text: $text)
                .frame(minHeight: 60)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25))
                )
                .scrollContentBackground(.hidden)
                .roundedBackground(cornerRadius: 6)
        }
    }
}
