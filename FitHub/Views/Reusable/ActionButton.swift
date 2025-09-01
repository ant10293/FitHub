//
//  ActionButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/18/25.
//

import SwiftUI

struct ActionButton: View {
    let title: String
    let systemImage: String?
    let enabled: Bool
    let color: Color
    let width: WidthStyle
    let bold: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        enabled: Bool = true,
        color: Color = .blue,
        width: WidthStyle = .fill,
        bold: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.color = color
        self.width = width
        self.bold = bold
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if let name = systemImage {
                    Image(systemName: name)
                }
                Text(title)
                    .fontWeight(bold ? .bold : .regular)
                    
            }
            .foregroundStyle(Color.primary)
            .frame(maxWidth: width == .fill ? .infinity : nil)
            .padding()
            .background(enabled ? color : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!enabled)
    }
    
    enum WidthStyle { case fit, fill }   // fit = text width, fill = full width
}


