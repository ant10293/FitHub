//
//  CardContainer.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/10/25.
//

import SwiftUI

private struct CardContainer: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let shadowRadius: CGFloat
    let backgroundColor: Color

    init(
        cornerRadius: CGFloat = 12,
        padding: CGFloat = 12,
        shadowRadius: CGFloat = 0,
        backgroundColor: Color = Color(uiColor: .secondarySystemBackground),
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .shadow(radius: shadowRadius)
    }
}

extension View {
    /// Flexible card container with Color background and optional border.
    func cardContainer(
        cornerRadius: CGFloat = 12,
        padding: CGFloat = 16,
        shadowRadius: CGFloat = 0,
        backgroundColor: Color = Color(uiColor: .secondarySystemBackground),
    ) -> some View {
        modifier(CardContainer(
            cornerRadius: cornerRadius,
            padding: padding,
            shadowRadius: shadowRadius,
            backgroundColor: backgroundColor
        ))
    }
}
