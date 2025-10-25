//
//  TappableDisclosure.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import SwiftUI

// MARK: - TappableDisclosure (add @ViewBuilder so conditional content compiles)
struct TappableDisclosure<Label: View, Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                label()
                Spacer(minLength: 0)
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { isExpanded.toggle() }

            if isExpanded { // now valid even when content has if/else inside
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
