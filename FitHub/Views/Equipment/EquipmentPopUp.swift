//
//  EquipmentPopUp.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EquipmentPopupView: View {
    let selectedEquipment: [GymEquipment]
    var showingCategories: Bool = false
    var title: String = "Your Equipment"
    var onClose: () -> Void
    var onContinue: () -> Void = {}
    var onEdit: () -> Void = {}
    
    var body: some View {
        VStack {
            HStack {
                // ───── leading  ─────
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .padding()
                }

                Spacer()

                // ───── trailing ─────
                if !showingCategories {
                    Button("Edit", action: onEdit)
                        .padding()
                }
            }
            .overlay(                                       // centered *over* the HStack
                Text(title)
                    .bold()
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)             // keep it truly centred
            )
            .padding()

            
            // Filter and list only selected equipment
            VStack(spacing: 0) {
                EquipmentList
                if !showingCategories {
                    Divider()
                }
            }
            if !showingCategories {
                Button("Save and Continue") {
                    onContinue()
                }
                .foregroundStyle(.white)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var EquipmentList: some View {
        List(selectedEquipment, id: \.id) { gymEquip in
            HStack {
                gymEquip.fullImageView
                    .frame(width: UIScreen.main.bounds.width * 0.15)
                
                Text(gymEquip.name)

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}
