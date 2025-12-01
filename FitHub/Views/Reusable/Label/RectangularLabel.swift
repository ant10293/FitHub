//
//  RectangularLabel.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/10/25.
//

import SwiftUI

struct RectangularLabel: View {
    enum IconPosition { case leading, trailing }

    let title: String
    let systemImage: String?
    let enabled: Bool
    let bgColor: Color
    let fgColor: Color
    let width: WidthStyle
    let font: Font
    let fontWeight: Font.Weight
    let iconPosition: IconPosition
    let cornerRadius: CGFloat

    init(
        title: String,
        systemImage: String? = nil,
        enabled: Bool = true,
        bgColor: Color = .blue,
        fgColor: Color = .primary,
        width: WidthStyle = .fill,
        font: Font = .body,
        fontWeight: Font.Weight = .regular,
        iconPosition: IconPosition = .leading,
        cornerRadius: CGFloat = 10
    ) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.bgColor = bgColor
        self.fgColor = fgColor
        self.width = width
        self.font = font
        self.fontWeight = fontWeight
        self.iconPosition = iconPosition
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        HStack(spacing: 8) {
            if iconPosition == .leading { icon }
            Text(title)
                .font(font)
                .fontWeight(fontWeight)
            if iconPosition == .trailing { icon }
        }
        .foregroundStyle(fgColor)
        .frame(maxWidth: width == .fill ? .infinity : nil)
        .cardContainer(cornerRadius: cornerRadius, backgroundColor: enabled ? bgColor : Color.gray)
    }

    @ViewBuilder
    private var icon: some View {
        if let name = systemImage {
            Image(systemName: name)
                .font(font)
                .fontWeight(fontWeight)
        }
    }
}
