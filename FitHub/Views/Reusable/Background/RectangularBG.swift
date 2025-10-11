//
//  TextFieldBackground.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/23/25.
//

import SwiftUI

private struct RectangularBG: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    let color: Color?
    let style: RoundedCornerStyle?

    func body(content: Content) -> some View {
        let fillColor = color ?? (colorScheme == .dark ? Color.black : Color(UIColor.secondarySystemBackground))
        let cornerStyle = style ?? .circular

        return content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: cornerStyle)
                    .fill(fillColor)
            )
    }
}

extension View {
    func roundedBackground(
        cornerRadius: CGFloat = 4,
        color: Color? = nil,
        style: RoundedCornerStyle? = nil
    ) -> some View {
        self.modifier(RectangularBG(cornerRadius: cornerRadius, color: color, style: style))
    }
}

