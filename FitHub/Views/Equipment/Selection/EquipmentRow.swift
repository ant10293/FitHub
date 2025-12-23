//
//  EquipmentRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/22/25.
//
import SwiftUI


struct EquipmentRow: View {
    let gymEquip: GymEquipment
    let equipmentSelected: Bool 
    let subtitle: RowSubtitle
    var viewDetail: () -> Void = {}
    let viewImplements: () -> Void
    var toggleSelection: () -> Void = {}
    var size: Double = 0.2
    var buttonOption: ExEquipImage.ButtonOption = .info
    var showCheckbox: Bool = true

    var body: some View {
        HStack {
            ExEquipImage(
                image: gymEquip.fullImage,
                size: size,
                button: buttonOption,
                onTap: { viewDetail() }
            )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(gymEquip.name)
                        .foregroundStyle(.primary)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                    
                    subtitleView
                }

                Spacer()
                
                if showCheckbox {
                    Image(systemName: equipmentSelected ? "checkmark.square.fill" : "square")
                        .foregroundStyle(equipmentSelected ? .blue : .gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: toggleSelection)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    var subtitleView: some View {
        switch subtitle {
        case .category:
            categoryLine

        case .implements:
            implementsLine

        case .both:
            categoryLine
            implementsLine
            
        case .none:
            EmptyView()
        }
    }

    var categoryLine: some View {
        Text(gymEquip.equCategory.rawValue)
            .lineLimit(1)
            .font(.subheadline)
            .foregroundStyle(.gray)
    }

    @ViewBuilder
    var implementsLine: some View {
        if let impl = gymEquip.availableImplements?.subtitle {
            Button(action: viewImplements) {
                HStack(spacing: 6) {
                    Text(impl)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Edit")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .contentShape(Rectangle())
                }
                .font(.caption)
                .lineLimit(1)
                .padding(.trailing)
            }
            .buttonStyle(.plain)
        }
    }
}

enum RowSubtitle: String {
    case category, implements, both, none
}
