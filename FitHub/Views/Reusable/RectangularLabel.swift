//
//  RectangularLabel.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/10/25.
//

import SwiftUI

struct RectangularLabel: View {
    enum WidthStyle { case fit, fill }
    enum IconPosition { case leading, trailing }

    let title: String
    let systemImage: String?
    let enabled: Bool
    let bgColor: Color
    let fgColor: Color
    let width: WidthStyle
    let bold: Bool
    let iconPosition: IconPosition

    init(
        title: String,
        systemImage: String? = nil,
        enabled: Bool = true,
        bgColor: Color = .blue,
        fgColor: Color = .primary,
        width: WidthStyle = .fill,
        bold: Bool = false,
        iconPosition: IconPosition = .leading,
    ) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.bgColor = bgColor
        self.fgColor = fgColor
        self.width = width
        self.bold = bold
        self.iconPosition = iconPosition
    }

    var body: some View {
        HStack(spacing: 8) {
            if iconPosition == .leading { icon }
            Text(title)
                .fontWeight(bold ? .bold : .regular)
            if iconPosition == .trailing { icon }
        }
        .foregroundStyle(fgColor)
        .frame(maxWidth: width == .fill ? .infinity : nil)
        .cardContainer(cornerRadius: 10, backgroundColor: enabled ? bgColor : Color.gray)
    }

    @ViewBuilder
    private var icon: some View {
        if let name = systemImage {
            Image(systemName: name)
        }
    }
}
