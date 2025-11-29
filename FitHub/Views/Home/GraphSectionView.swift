//
//  GraphSectionView.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/19/25.
//

import SwiftUI

/// A reusable view for displaying a graph section with a label and selection control.
/// Provides consistent styling for both exercise performance and measurements graphs.
struct GraphSectionView<SelectionControl: View, Content: View>: View {
    let label: String
    let selectionControl: SelectionControl
    let content: Content
    
    init(
        label: String,
        @ViewBuilder selectionControl: () -> SelectionControl,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.selectionControl = selectionControl()
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .padding(.leading)
                
                Spacer()
                
                selectionControl
                    .padding(.trailing)
            }
            .padding(.bottom)
            
            content
        }
    }
}

enum GraphSelection {
    case exercise(Exercise)
    case measurement(MeasurementType)
}
