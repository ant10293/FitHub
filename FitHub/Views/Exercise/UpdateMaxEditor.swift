//
//  UpdateMax.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct UpdateMaxEditor: View {
    let exercise: Exercise
    let peakType: PeakMetric
    let onSave: (PeakMetric) -> Void
    let onCancel: () -> Void
    
    init(exercise: Exercise, onSave: @escaping (PeakMetric) -> Void, onCancel: @escaping () -> Void) {
        self.exercise = exercise
        self.peakType = exercise.getPeakMetric(metricValue: 0)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        GenericEditor(
            title: "Update \(exercise.performanceTitle)",
            placeholder: "Enter new \(exercise.performanceUnit)",
            initialValue: "",
            onSave: { newValue in
                let peak = peakType.peakMetricConverted(from: newValue)
                onSave(peak)
            },
            onExit: onCancel
        )
    }
}

