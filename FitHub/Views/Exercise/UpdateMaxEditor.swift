//
//  UpdateMax.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct UpdateMaxEditor: View {
    var exercise: Exercise
    var onSave: (PeakMetric) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        GenericEditor(
            title: "Update \(exercise.performanceTitle)",
            placeholder: "Enter new \(exercise.fieldLabel) (\(exercise.peformanceUnit))",
            initialValue: "",
            onSave: { newValue in
                let new = exercise.metricDouble(from: newValue)
                let peak = exercise.getPeakMetric(metricValue: new)
                onSave(peak)
            },
            onExit: onCancel
        )
    }
}

