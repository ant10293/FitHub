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
                    Group {
                        if let adjustmentsText {
                            (titleText + adjustmentsText)
                                .lineLimit(6)
                        } else {
                            (titleText + addAdjustmentPlaceholder)
                                .lineLimit(2)
                        }
                    }
                    .minimumScaleFactor(0.8)
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
                .padding([.top, .horizontal])
            }
        }
    }

    private var titleText: Text {
        Text("Equipment Adjustments\n")
            .font(titleFont)
            .bold()
            .foregroundStyle(titleColor)
    }

    private var addAdjustmentPlaceholder: Text {
        (Text(Image(systemName: "plus"))
        + Text("Add Adjustment"))
        .font(bodyFont)
        .foregroundStyle(bodyColor)
    }

    private var adjustmentsText: Text? {
        guard let adjustments = ctx.adjustments.getEquipmentAdjustments(for: exercise) else {
            return nil
        }

        let nonEmpty = adjustments
            .filter { !$0.value.displayValue.isEmpty }
            .sorted { $0.category.rawValue < $1.category.rawValue }

        guard let first = nonEmpty.first else { return nil }

        func line(for adjustment: AdjustmentEntry) -> Text {
            (Text("\(adjustment.category.rawValue): ")
            + Text(adjustment.value.displayValue).bold())
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }

        let initial = line(for: first)

        return nonEmpty.dropFirst().reduce(initial) { partial, adjustment in
            partial + Text("\n") + line(for: adjustment)
        }
    }
}
