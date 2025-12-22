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
    let content: () -> Content

    init(
        width: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.width = width
        self.content = content
    }

    var body: some View {
        content()
            .frame(width: width, height: screenHeight * 0.0425, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark
                          ? Color(UIColor.systemGray4)
                          : Color(UIColor.secondarySystemBackground))
            )
    }
}
