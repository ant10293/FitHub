//
//  ExEquipImage.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/16/25.
//

import SwiftUI


struct ExEquipImage: View {
    @State private var isExpanded = false
    let image: Image
    var size: CGFloat = 0.44                // collapsed % of screen width
    var button: ButtonOption = .none
    var onTap: (() -> Void)? = nil          // used for .info / .none
        
    var body: some View {
        Button(action: handleTap) {
            image
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .bottomTrailing) { overlayIcon }
                .frame(width: currentWidth)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: Overlay
    @ViewBuilder
    private var overlayIcon: some View {
        let iconSize = currentWidth * 0.12 // 12% of image width

        switch button {
        case .info:
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
                .font(.system(size: iconSize))
                .padding(4)

        case .expand:
            Image(systemName: isExpanded
                  ? "arrow.down.forward.and.arrow.up.backward.circle.fill"
                  : "arrow.down.left.and.arrow.up.right.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: iconSize))
                .padding(4)

        case .none:
            EmptyView()
        }
    }
    
    // Collapsed width in points
    private var collapsedWidth: CGFloat { UIScreen.main.bounds.width * size }
    
    // Expanded = 2× collapsed, but don't blow past screen (leave tiny margin)
    private var expandedWidth: CGFloat {
        let maxWidth = UIScreen.main.bounds.width * 0.98
        return min(collapsedWidth * 2.0, maxWidth)
    }
    
    private var currentWidth: CGFloat { isExpanded ? expandedWidth : collapsedWidth }
    
    enum ButtonOption { case info, expand, none }
    
    // MARK: Tap routing
    private func handleTap() {
        switch button {
        case .expand:
            isExpanded.toggle()
        case .info, .none:
            onTap?()
        }
    }
}

