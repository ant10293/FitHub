//
//  WarningFooter.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/17/25.
//

import SwiftUI

struct WarningFooter: View {
    let message: String
    let font: Font
    let color: Color
    let image: String
    let showImage: Bool
    let width: CGFloat?

    init(
        message: String,
        font: Font = .footnote,
        color: Color = .orange,
        image: String = "exclamationmark.triangle.fill",
        showImage: Bool = true,
        width: CGFloat? = nil
    ) {
        self.message = message
        self.font = font
        self.color = color
        self.image = image
        self.showImage = showImage
        self.width = width
    }

    var body: some View {
        HStack(spacing: 6) {
            if showImage {
                Image(systemName: image)
            }
            Text(message)
                .multilineTextAlignment(.center)
        }
        .font(font)
        .foregroundStyle(color)
        .frame(width: width, alignment: .center)
    }
}

