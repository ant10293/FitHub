//
//  WeightSelectorRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/20/25.
//

import SwiftUI

/// Presents a weight picker in the user–preferred unit while binding
/// the result back to *kilograms*.

struct WeightSelectorRow: View {
    @AppStorage(UnitSystem.storageKey) private var unit: UnitSystem = .metric
    @Binding var weight: Mass

    /// This is the visible binding the wheel sees (kg or lb depending on system)
    private var weightBinding: Binding<CGFloat> {
        Binding(
            get: {
                if unit == .imperial {
                    CGFloat(weight.inLb)
                } else {
                    CGFloat(weight.inKg)
                }
            },
            set: { newVal in
                if unit == .imperial {
                    weight.setLb(newVal)
                } else {
                    weight.setKg(newVal)
                }
            }
        )
    }

    var body: some View {
        WeightSelectorView(value: weightBinding)
    }
}


