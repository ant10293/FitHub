//
//  AddDeleteButtons.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/4/25.
//

import SwiftUI

struct AddDeleteButtons: View {
    var addSet: () -> Void
    var deleteSet: () -> Void
    
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
            
            Spacer()
        }
        .padding(.top)
    }
}

