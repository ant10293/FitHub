//
//  ErrorFooter.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/23/25.
//

import SwiftUI

struct ErrorFooter: View {
    let message: String?
    let font: Font
    let color: Color
    let image: String
    let showImage: Bool
    let width: CGFloat?

    init(
        message: String?,
        font: Font = .footnote,
        color: Color = .red,
        image: String = "exclamationmark.circle",
        showImage: Bool = false,
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
        /// never show image unless there is a message to go along with it
        let resolvedShowImage: Bool = message == nil ? false : showImage
        
        HStack(spacing: 6) {
            if resolvedShowImage {
                Image(systemName: image)
            }
            if let message {
                Text(message)
                    .multilineTextAlignment(.center)
            }
        }
        .font(font)
        .foregroundStyle(color)
        .frame(width: width, alignment: .center)
    }
}
