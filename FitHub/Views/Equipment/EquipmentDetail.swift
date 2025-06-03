//
//  EquipmentDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EquipmentDetail: View {
    var equipment: GymEquipment
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Equipment Image
            Image(equipment.fullImagePath)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .padding()
            
            // Equipment Name
            Text(equipment.name.rawValue)
                .font(.title)
                .bold()
                .padding(.top)
            
            // Equipment Description
            Text(equipment.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            // Close Button
            Button(action: onClose) {
                Text("Close")
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}
