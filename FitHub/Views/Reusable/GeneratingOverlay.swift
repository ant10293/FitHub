//
//  GeneratingOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/28/25.
//

import SwiftUI

private struct GeneratingOverlay: ViewModifier {
    let isPresented: Bool
    var message: String = "Generating Workout..."

    @ViewBuilder
    private var overlayCard: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().progressViewStyle(.circular).scaleEffect(1.2)
                Text(message).font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(radius: 8, y: 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(message))
        }
        .transition(.opacity)
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isPresented)           // block touches beneath
            if isPresented {
                overlayCard
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    func generatingOverlay(_ isPresented: Bool, message: String = "Generating Workout...") -> some View {
        modifier(GeneratingOverlay(isPresented: isPresented, message: message))
    }
}
