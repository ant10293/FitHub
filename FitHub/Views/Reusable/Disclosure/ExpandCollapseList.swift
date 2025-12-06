//
//  ExpandCollapseList.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/16/25.
//

import SwiftUI

struct ExpandCollapseList: View {
    @Binding var expandList: Bool
    let expandText: String
    let collapseText: String
    
    init(
        expandList: Binding<Bool>,
        expandText: String = "Expand List",
        collapseText: String = "Collapse List"
    ) {
        _expandList = expandList
        self.expandText = expandText
        self.collapseText = collapseText
    }
    
    var body: some View {
        Button(action: {
            withAnimation { expandList.toggle() }
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

