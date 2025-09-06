//
//  TextButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/4/25.
//

import SwiftUI

struct TextButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    let color: Color

    var body: some View {
        Button {
            withAnimation(.default) { action() }
        } label: {
            HStack {
                Text(title)
                Image(systemName: systemImage)
            }
            .foregroundStyle(color)
        }
        .buttonStyle(.plain) // style outside if you want
    }
}
