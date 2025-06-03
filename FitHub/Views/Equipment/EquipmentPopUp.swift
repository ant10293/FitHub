//
//  EquipmentPopUp.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EquipmentPopupView: View {
    @EnvironmentObject var equipmentData: EquipmentData
    var onClose: () -> Void
    var onContinue: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .padding()
                Spacer()
                Text("Your Equipment")
                    .bold()
                Spacer()
                Button("Edit") {
                    onEdit()
                }
                .padding()
            }
            
            // Filter and list only selected equipment
            VStack(spacing: 0) {
                EquipmentList(equipment: equipmentData.allEquipment.filter { $0.isSelected }, title: "")
                Divider()
            }
            Button("Save and Continue") {
                onContinue()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
    struct Line: View {
        var body: some View {
            Rectangle()
                .frame(width: .infinity, height: 1)
                .foregroundColor(.gray)
        }
    }
}
