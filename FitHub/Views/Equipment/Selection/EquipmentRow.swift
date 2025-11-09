//
//  EquipmentRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/22/25.
//

import SwiftUI

struct EquipmentRow: View {
    let gymEquip: GymEquipment
    let equipmentSelected: Bool
    let viewDetail: () -> Void
    let toggleSelection: () -> Void

    var body: some View {
        HStack {
            ExEquipImage(
                image: gymEquip.fullImage,
                size: 0.2,
                button: .info,
                onTap: { viewDetail() }
            )

            Button(action: toggleSelection) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gymEquip.name)
                            .foregroundStyle(Color.primary)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.65)

                        Text(gymEquip.equCategory.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }

                    Spacer()

                    Image(systemName: equipmentSelected ? "checkmark.square.fill" : "square")
                        .foregroundStyle(equipmentSelected ? .blue : .gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 4)
    }
}


