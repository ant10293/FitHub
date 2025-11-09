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
        NavigationStack {
            VStack {
                // Filter and list only selected equipment
                VStack(spacing: 0) {
                    EquipmentList
                    if !showingCategories {
                        Divider()
                    }
                }
                if !showingCategories {
                    RectangularButton(title: "Save and Continue", width: .fit, action: onContinue)
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                }
                if !showingCategories {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { onEdit() }
                    }
                }
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
