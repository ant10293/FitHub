//
//  MeasurementCard.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/9/25.
//

import SwiftUI

struct MeasurementCard<ValueView: View, Content: View>: View {
    let title: String
    let isActive: Bool
    let onTap: () -> Void
    @ViewBuilder var valueView: () -> ValueView
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    valueView()
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isActive ? 90 : 0))
                }
                .padding()
            }
            .contentShape(Rectangle())

            if isActive {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .roundedBackground(cornerRadius: 10, color: Color(UIColor.secondarySystemBackground))
        .padding(.horizontal)
    }
}
