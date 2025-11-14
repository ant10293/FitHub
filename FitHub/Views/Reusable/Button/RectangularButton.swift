//
//  RectangularButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/18/25.
//

import SwiftUI

struct RectangularButton: View {
    let title: String
    let systemImage: String?
    let enabled: Bool
    let bgColor: Color
    let fgColor: Color
    let width: WidthStyle
    let fontWeight: Font.Weight
    let iconPosition: RectangularLabel.IconPosition
    let cornerRadius: CGFloat
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        enabled: Bool = true,
        bgColor: Color = .blue,
        fgColor: Color = .primary,
        width: WidthStyle = .fill,
        fontWeight: Font.Weight = .regular,
        iconPosition: RectangularLabel.IconPosition = .leading,
        cornerRadius: CGFloat = 10,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.bgColor = bgColor
        self.fgColor = fgColor
        self.width = width
        self.fontWeight = fontWeight
        self.iconPosition = iconPosition
        self.cornerRadius = cornerRadius
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            RectangularLabel(
                title: title,
                systemImage: systemImage,
                enabled: enabled,
                bgColor: bgColor,
                fgColor: fgColor,
                width: width,
                fontWeight: fontWeight,
                iconPosition: iconPosition,
                cornerRadius: cornerRadius
            )
        }
        .disabled(!enabled)
    }
}
