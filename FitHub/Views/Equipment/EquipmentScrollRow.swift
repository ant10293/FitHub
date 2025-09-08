//
//  EquipmentScrollRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/7/25.
//

import SwiftUI

struct EquipmentScrollRow: View {
    var equipment: [GymEquipment]
    var title: String
    
    var body: some View {
        if !equipment.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(title): ").bold()
                ScrollView(.horizontal) {
                    LazyHStack {
                        let size: CGFloat = UIScreen.main.bounds.height * 0.1
                        
                        ForEach(equipment, id: \.self) { equipment in
                            VStack {
                                equipment.fullImageView
                                    .frame(width: size, height: size)
                                
                                Text(equipment.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)      // wrap + center
                                    .lineLimit(nil)                       // unlimited lines
                                    .frame(maxWidth: size * 1.1)          // ≤ 110 % of image width
                                    .fixedSize(horizontal: false, vertical: true) // grow down, not sideways
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
    }
}

