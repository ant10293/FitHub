//
//  AdjustmentsSection.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/8/25.
//

import SwiftUI

struct AdjustmentsSection: View {
    @EnvironmentObject var ctx: AppContext
    @Binding var showingAdjustmentsView: Bool
    @Binding var showingPlateVisualizer: Bool
    
    let hidePlateVisualizer: Bool
    let exercise: Exercise
    
    var titleFont: Font = .caption
    var titleColor: Color = .blue
    var bodyFont: Font = .caption
    var bodyColor: Color = .secondary
    
    var body: some View {
        VStack {
            if ctx.equipment.hasEquipmentAdjustments(for: exercise) {
                Button(action: { showingAdjustmentsView.toggle() }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipment Adjustments")
                            .font(titleFont)
                            .bold()
                            .foregroundStyle(titleColor)
                            .minimumScaleFactor(0.8)
                        
                        if let adjustments = ctx.adjustments.getEquipmentAdjustments(for: exercise), !adjustments.isEmpty {
                            let nonEmpty = adjustments.filter { !$0.value.displayValue.isEmpty }
                            if nonEmpty.isEmpty {
                                addAdjustmentPlaceholder
                            } else {
                                let sorted = nonEmpty.sorted { $0.category.rawValue < $1.category.rawValue }
                                ForEach(sorted, id: \.category) { adjustment in
                                    (Text("\(adjustment.category.rawValue): ")
                                     + Text(adjustment.value.displayValue).bold())
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                }
                            }
                        } else {
                            addAdjustmentPlaceholder
                        }
                    }
                }
            }
            
            if !hidePlateVisualizer, exercise.usesPlates(equipmentData: ctx.equipment) {
                Button(action: { showingPlateVisualizer.toggle() }) {
                    Text("Plate Loading Visualizer")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.blue)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                .padding(.horizontal)
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

