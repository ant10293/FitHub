//
//  AddDeleteButtons.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/4/25.
//

import SwiftUI

struct AddDeleteButtons: View {
    var addSet: () -> Void
    var deleteLastSet: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: addSet) {
                Label(" Add Set ", systemImage: "plus").foregroundStyle(.blue)
            }
            .buttonStyle(.bordered).tint(.blue)

            Button(action: deleteLastSet) {
                Label("Delete Set", systemImage: "minus").foregroundStyle(.red)
            }
            .buttonStyle(.bordered).tint(.red)
            Spacer()
        }
        .padding(.top)
    }
}

