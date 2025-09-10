//
//  MeasurementEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct MeasurementEditor: View {
    var measurement: MeasurementValue
    var measurementType: MeasurementType
    var onSave: ((Double) -> Void)?
    var onExit: () -> Void
    
    var body: some View {
        GenericEditor(
            title: "Edit \(measurementType.rawValue)",
            placeholder: getString,
            initialValue: measurement.displayValueString,
            onSave: { newValue in
                let new = measurement.metricDouble(from: newValue)
                onSave?(new)
            },
            onExit: onExit
        )
    }
    
    private var getString: String {
        if let unitLabel = measurementType.unitLabel {
            return MeasurementType.bodyPartMeasurements.contains(measurementType)
                ? "Enter Circumference (\(unitLabel))"
                : "Enter Value (\(unitLabel))"
        } else {
            return "Enter Value"
        }
    }
}
