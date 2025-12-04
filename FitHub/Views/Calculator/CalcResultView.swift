//
//  CalcResultView.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/8/25.
//

import SwiftUI

struct CalcResultView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let singleResult: String?
    let buttonLabel: String
    let dismissAction: () -> Void
    @ViewBuilder var content: () -> Content
    
    init(
        title: String,
        singleResult: String? = nil,
        buttonLabel: String = "Close",
        dismissAction: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.singleResult = singleResult
        self.buttonLabel = buttonLabel
        self.dismissAction = dismissAction
        self.content = content
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            if let singleResult {
                Text(singleResult)
                    .font(.title2)
                    .padding(.vertical)
            }

            content()

            RectangularButton(title: buttonLabel, action: dismissAction)
        }
        .frame(width: screenWidth * 0.9)
        .cardContainer(
            cornerRadius: 12,
            shadowRadius: 10,
            backgroundColor: colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white
        )
    }
}
