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
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            
            TextField(placeholder, text: $text)
                .padding(8)
                .roundedBackground(cornerRadius: 6)
                .overlay(alignment: .trailing) {
                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                                .padding(.trailing, 4)
                                .contentShape(Rectangle())
                        }
                    }
                }
            
            if let err = error {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .italic()
            }
        }
    }
}
