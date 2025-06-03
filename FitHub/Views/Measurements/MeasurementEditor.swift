//
//  MeasurementEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct MeasurementEditor: View {
    var measurementType: MeasurementType
    @Binding var value: Double
    @Binding var isPresented: Bool
    @State private var inputValue: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    var onSave: ((Double) -> Void)?
    
    var body: some View {
        VStack {
            Text("Edit \(measurementType.rawValue)")
                .font(.headline)
                .padding()
            
            TextField(getString(), text: $inputValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .onChange(of: inputValue) { oldValue, newValue in
                    inputValue = formatInput(newValue)
                }
            HStack(spacing: 20) {
                Spacer()
                
                Button(action: {
                    isFocused = false
                    isPresented = false
                }) {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Button(action: {
                    isFocused = false
                    if let newValue = Double(inputValue) {
                        value = newValue
                        onSave?(newValue)
                    }
                    isPresented = false
                }) {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(!isInputValid())
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
        .onAppear {
            inputValue = formatValue(value)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                self.isFocused = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                self.isFocused = false
            }
        }
    }
    private func getString() -> String {
        var stringValue: String = ""
        
        if let unitLabel = measurementType.unitLabel {
            stringValue = MeasurementType.bodyPartMeasurements.contains(measurementType) ? "Enter Circumference (\(unitLabel))" : "Enter Value (\(unitLabel))"
        } else {
            stringValue = "Enter Value"
        }
        return stringValue
    }
    
    private func formatValue(_ value: Double) -> String {
        // Format the value to a string with a maximum of two decimal places
        return String(format: "%.2f", value).trimmingCharacters(in: CharacterSet(charactersIn: "0").union(.punctuationCharacters))
    }
    
    private func formatInput(_ input: String) -> String {
        // Allow only numbers and one decimal point, and limit to two decimal places
        var filtered = input.filter { "0123456789.".contains($0) }
        
        let components = filtered.split(separator: ".")
        if components.count > 1, let decimalPart = components.last {
            filtered = components.first! + "." + String(decimalPart.prefix(2))
        }
        
        return filtered
    }
    
    private func isInputValid() -> Bool {
        let trimmedInput = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return false }
        return Double(trimmedInput) != nil
    }
}

