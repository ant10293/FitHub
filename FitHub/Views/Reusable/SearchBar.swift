//
//  SearchBar.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/14/25.
//

import SwiftUI

/// Reusable search field with magnifying-glass icon and a clear (“x”) button.
///
/// Usage:
/// ```swift
/// @State private var searchText = ""
///
/// SearchBar(text: $searchText,
///           placeholder: "Search Equipment")
/// ```
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            // Actual text field
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)

            // Clear button (only when text isn’t empty)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain) // removes tap-area inset
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
