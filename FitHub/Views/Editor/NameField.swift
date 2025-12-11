//
//  NameField.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/10/25.
//

import SwiftUI

struct NameField: View {
    // MARK: – Inputs
    var title: String
    var placeholder: String
    @Binding var text: String
    var error: String?          // nil → no error label
        
    var body: some View {
        let width = screenWidth
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            
            TextField(placeholder, text: $text)
                .trailingIconButton(
                    systemName: "xmark.circle.fill",
                    isShowing: !text.isEmpty,
                    action: {
                        text = ""
                    }
                )
                .padding(width * 0.02)
                .roundedBackground(cornerRadius: 6)
            
            if let err = error {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .italic()
            }
        }
    }
}
