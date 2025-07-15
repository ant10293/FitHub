//
//  MeasurementEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct MeasurementEditor: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    var measurementType: MeasurementType
    @Binding var value: Double
    @Binding var isPresented: Bool
    @State private var inputValue: String = ""
    @FocusState private var isFocused: Bool
    var onSave: ((Double) -> Void)?
    
    var body: some View {
        VStack {
            Text("Edit \(measurementType.rawValue)")
                .font(.headline)
                .padding()
            
            TextField(getString(), text: $inputValue)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4) // Background shape
                    .fill(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
                .onChange(of: inputValue) { oldValue, newValue in
                    inputValue = InputLimiter.filteredWeight(old: oldValue, new: newValue)
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
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 10)
        .padding()
        .onAppear {
            inputValue = Format.smartFormat(value)
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
}

