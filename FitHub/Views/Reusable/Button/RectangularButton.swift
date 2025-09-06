//
//  RectangularButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/18/25.
//

import SwiftUI

struct RectangularButton: View {
    enum WidthStyle { case fit, fill }
    enum IconPosition { case leading, trailing }

    let title: String
    let systemImage: String?
    let enabled: Bool
    let color: Color
    let width: WidthStyle
    let bold: Bool
    let iconPosition: IconPosition
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        enabled: Bool = true,
        color: Color = .blue,
        width: WidthStyle = .fill,
        bold: Bool = false,
        iconPosition: IconPosition = .leading,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.color = color
        self.width = width
        self.bold = bold
        self.iconPosition = iconPosition
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if iconPosition == .leading { icon }
                Text(title)
                    .fontWeight(bold ? .bold : .regular)
                if iconPosition == .trailing { icon }
            }
            .foregroundStyle(Color.primary)
            .frame(maxWidth: width == .fill ? .infinity : nil)
            .padding()
            .background(enabled ? color : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!enabled)
    }

    @ViewBuilder
    private var icon: some View {
        if let name = systemImage {
            Image(systemName: name)
        }
    }
}
