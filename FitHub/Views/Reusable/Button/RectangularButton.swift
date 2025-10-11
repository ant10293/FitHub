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
    let width: RectangularLabel.WidthStyle
    let bold: Bool
    let iconPosition: RectangularLabel.IconPosition
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        enabled: Bool = true,
        bgColor: Color = .blue,
        fgColor: Color = .primary,
        width: RectangularLabel.WidthStyle = .fill,
        bold: Bool = false,
        iconPosition: RectangularLabel.IconPosition = .leading,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.bgColor = bgColor
        self.fgColor = fgColor
        self.width = width
        self.bold = bold
        self.iconPosition = iconPosition
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
                bold: bold,
                iconPosition: iconPosition
            )
        }
        .disabled(!enabled)
    }
}
