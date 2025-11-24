//
//  InfoBanner.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/18/25.
//

import SwiftUI

struct InfoBanner: View {
    // MARK: – Public API
    let title: String
    let bgColor: Color
    
    init(
        title: String,
        bgColor: Color = .blue
    ) {
        self.title = title
        self.bgColor = bgColor
    }
    
    var body: some View {
        RectangularLabel(title: title, bgColor: bgColor, width: .fit)
            .shadow(radius: 10)
            .transition(.scale)
    }
}
