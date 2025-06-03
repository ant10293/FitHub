//
//  EquipmentList.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct EquipmentList: View {
    var equipment: [GymEquipment]
    var title: String
    
    var body: some View {
        List(equipment, id: \.id) { gymEquip in
            HStack {
                Image(gymEquip.fullImagePath)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                
                Text(gymEquip.name.rawValue)
                    //.font(.headline)
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("\(title)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
