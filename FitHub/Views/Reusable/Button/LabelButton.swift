//
//  LabelButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/15/25.
//

import SwiftUI

struct LabelButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let controlSize: ControlSize
    let width: WidthStyle
    let action: () -> Void

    init(
        title: String,
        systemImage: String,
        tint: Color = .accentColor,
        controlSize: ControlSize = .regular,
        width: WidthStyle = .fill,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.controlSize = controlSize
        self.width = width
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(tint)
                .frame(maxWidth: width == .fill ? .infinity : nil)
        }
        .buttonStyle(.bordered)
        .tint(tint)
        .controlSize(controlSize)
    }
}
