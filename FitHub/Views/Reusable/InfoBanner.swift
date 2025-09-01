//
//  InfoBanner.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/18/25.
//

import SwiftUI

struct InfoBanner: View {
    // MARK: – Public API
    let text: String
    var width: CGFloat? = 300
    var height: CGFloat? = 100
    var bgColor: Color? = .blue
    
    var body: some View {
        VStack {
            Text(text)
                .foregroundStyle(.white)
                .padding()
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(width: width, height: height)
        .background(Color.clear)
        .shadow(radius: 10)
        .transition(.scale)
    }
}
