//
//  MeasurementEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct MeasurementEditor: View {
    let measurement: MeasurementValue
    let measurementType: MeasurementType
    let onSave: ((Double) -> Void)?
    let onExit: () -> Void
    
    var body: some View {
        GenericEditor(
            title: "Edit \(measurementType.rawValue)",
            placeholder: measurementType.placeholder,
            initialValue: measurement.fieldString,
            onSave: { newValue in
                let convertedVal: Double
                switch measurement {
                case .size:
                    convertedVal = UnitSystem.current == .imperial ? UnitSystem.INtoCM(newValue) : newValue
                case .weight:
                    convertedVal = UnitSystem.current == .imperial ? UnitSystem.LBtoKG(newValue) : newValue
                case .bmi, .calories, .percentage:
                    convertedVal = newValue
                }
                onSave?(convertedVal)
            },
            onExit: onExit
        )
    }
}
