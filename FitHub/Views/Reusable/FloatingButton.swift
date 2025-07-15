//
//  FloatingButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/11/25.
//

import SwiftUI

struct FloatingButton: View {
    var image: String                 // SF-Symbol or asset name
    var foreground: Color = .white
    var background: Color = .blue     // background tint (optional)
    var size: CGFloat = 24        // icon size   (optional)
    var action: () -> Void            // button tap
    
    var body: some View {
        Button(action: action) {
            Image(systemName: image)
                .resizable()
                .frame(width: size, height: size)
                .padding()
                .foregroundColor(foreground)
                .background(background)
                .clipShape(Circle())
                .shadow(radius: 10)
                .padding()
        }
    }
}
