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
/*
struct MeasurementEditor: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @State private var inputValue: String = ""
    @FocusState private var isFocused: Bool
    var measurement: MeasurementValue
    var measurementType: MeasurementType
    var onSave: ((Double) -> Void)?
    var onExit: () -> Void
    
    var body: some View {
        VStack {
            Text("Edit \(measurementType.rawValue)")
                .font(.headline)
                .padding()
            
            TextField(getString, text: $inputValue)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .padding(8)
                .roundedBackground()
                .padding(.horizontal)
                .onChange(of: inputValue) { oldValue, newValue in
                    inputValue = InputLimiter.filteredWeight(old: oldValue, new: newValue)
                }
            
            HStack(spacing: 20) {
                Spacer()
                
                Button(action: {
                    buttonAction()
                }) {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Button(action: {
                    if let newValue = Double(inputValue) {
                        let new = measurement.metricDouble(from: newValue)
                        onSave?(new)
                    }
                    buttonAction()
                }) {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                Spacer()
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 10)
        .padding()
        .onAppear(perform: appearAction)
    }
    
    private func appearAction() {
        inputValue = measurement.displayValueString
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isFocused = true }
    }
    
    private func buttonAction() {
        isFocused = false
        onExit()
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
*/
