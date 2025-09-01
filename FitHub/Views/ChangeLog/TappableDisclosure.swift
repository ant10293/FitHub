//
//  TappableDisclosure.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import SwiftUI

struct TappableDisclosure<Label: View, Content: View>: View {
    @Binding var isExpanded: Bool
    let label: () -> Label
    let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                label()
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())                 // entire row tappable
            .onTapGesture { withAnimation(.snappy) {   // or .easeInOut if < iOS17
                isExpanded.toggle()
            }}

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

