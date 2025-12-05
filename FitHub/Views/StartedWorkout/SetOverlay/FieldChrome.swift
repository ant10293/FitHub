//
//  FieldChrome.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//

import SwiftUI

struct FieldChrome<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let width: CGFloat
    let isZero: Bool
    let content: () -> Content

    init(
        width: CGFloat,
        isZero: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.width = width
        self.isZero = isZero
        self.content = content
    }

    var body: some View {
        content()
            .foregroundStyle(isZero ? .red : .primary)
            .frame(width: width, height: screenHeight * 0.0425, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark
                          ? Color(UIColor.systemGray4)
                          : Color(UIColor.secondarySystemBackground))
            )
    }
}
