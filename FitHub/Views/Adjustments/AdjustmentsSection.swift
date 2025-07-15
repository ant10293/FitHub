//
//  AdjustmentsSection.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/8/25.
//

import SwiftUI

struct AdjustmentsSection: View {
    @ObservedObject var adjustments: AdjustmentsData
    @ObservedObject var equipmentData: EquipmentData
    @Binding var showingAdjustmentsView: Bool
    let exercise: Exercise
    
    var titleFont: Font = .caption
    var titleColor: Color = .blue
    var bodyFont: Font = .caption
    var bodyColor: Color = .secondary
    var padding: CGFloat = -10
    
    var body: some View {
        VStack(alignment: .leading) {
            if equipmentData.hasEquipmentAdjustments(for: exercise) {
                Button(action: { showingAdjustmentsView.toggle() }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipment Adjustments")
                            .font(titleFont)
                            .bold()
                            .foregroundColor(titleColor)
                            .minimumScaleFactor(0.8)

                        if let adjustments = adjustments.getEquipmentAdjustments(for: exercise), !adjustments.isEmpty {
                            let nonEmpty = adjustments.filter { !$0.value.displayValue.isEmpty }
                            if nonEmpty.isEmpty {
                                addAdjustmentPlaceholder
                            } else {
                                ForEach(nonEmpty.keys.sorted(), id: \.self) { cat in
                                    if let val = nonEmpty[cat]?.displayValue {
                                        Text("\(cat.rawValue): ")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        + Text(val)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .bold()
                                    }
                                }
                            }
                        } else {
                            addAdjustmentPlaceholder 
                        }
                    }
                    .padding(.leading, padding)
                }
            }
        }  
    }
    
    private var addAdjustmentPlaceholder: some View {
        HStack(spacing: 4) {
            Image(systemName: "plus")
            Text("Add Adjustment")
        }
        .font(bodyFont)
        .foregroundStyle(bodyColor)
    }
}

