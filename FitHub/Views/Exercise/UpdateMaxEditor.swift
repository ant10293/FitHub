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

/*
struct UpdateMaxEditor: View {
    @State private var newMax: String = ""
    @FocusState private var isTextFieldFocused: Bool
    var exercise: Exercise
    var onSave: (PeakMetric) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Update \(exercise.performanceTitle)")
                .font(.headline)
            
            TextField("Enter new \(exercise.fieldLabel) (\(exercise.peformanceUnit))", text: $newMax)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focused($isTextFieldFocused)
                .onAppear { isTextFieldFocused = true }
            
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Button(action: save) {
                    Text(" Save ")
                        .foregroundStyle(.white)
                        .padding()
                        .background(newMax.isEmpty ? Color.gray : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(newMax.isEmpty)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .padding()
    }
    
    private func save() {
        if let newValue = Double(newMax) {
            let new = exercise.metricDouble(from: newValue)
            let peak = exercise.getPeakMetric(metricValue: new)
            onSave(peak)
        }
    }
}
*/

