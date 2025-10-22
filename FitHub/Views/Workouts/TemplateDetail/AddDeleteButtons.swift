//
//  AddDeleteButtons.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/4/25.
//

import SwiftUI

struct AddDeleteButtons: View {
    let addSet: () -> Void
    let deleteSet: () -> Void
    let disableDelete: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            LabelButton(
                title: "Add Set",
                systemImage: "plus",
                tint: .blue,
                action: addSet
            )
            
            LabelButton(
                title: "Delete Set",
                systemImage: "minus",
                tint: .red,
                action: deleteSet
            )
            .disabled(disableDelete)
            
            Spacer()
        }
        .padding(.top)
    }
}

