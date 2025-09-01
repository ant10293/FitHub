//
//  ExpandCollapseList.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/16/25.
//

import SwiftUI

struct ExpandCollapseList: View {
    @Binding var expandList: Bool
    var expandText: String = "Expand List"
    var collapseText: String = "Collapse List"
    
    var body: some View {
        Button(action: {
            withAnimation {
                expandList.toggle()
            }
        }) {
            HStack {
                Label(
                    expandList ? collapseText : expandText,
                    systemImage: expandList ? "chevron.down" : "chevron.up"
                )
                .font(.subheadline)
                Spacer()
            }
            .padding(.top)
        }
    }
}

