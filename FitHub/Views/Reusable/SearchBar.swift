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
    let placeholder: String
    
    init(
        text: Binding<String>,
        placeholder: String = "Search"
    ) {
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        // Actual text field
        TextField(
            placeholder,
            text: $text
        )
        .textInputAutocapitalization(.none)
        .disableAutocorrection(true)
        .leadingIconButton(
            systemName: "magnifyingglass",
            fgColor: Color.secondary,
            isButton: false
        )
        .trailingIconButton(
            systemName: "xmark.circle.fill",
            isShowing: !text.isEmpty,
            isButton: false,
            action: {
                text = ""
            }
        )
        .inputStyle()
    }
}
