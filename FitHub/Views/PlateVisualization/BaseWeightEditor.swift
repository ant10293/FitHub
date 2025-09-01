//
//  BaseWeightEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/1/25.
//

import SwiftUI

struct BaseWeightEditor: View {
    let exercise: Exercise
    let gymEquip: GymEquipment
    var onSave: (Double) -> Void
    var onExit: () -> Void
    
    var body: some View {
        GenericEditor(
            title: "Set Base Weight for \(gymEquip.name)",
            placeholder: "Enter weight (\(UnitSystem.current.weightUnit))",
            initialValue: gymEquip.baseWeight?.resolvedMass.displayString ?? "",
            onSave: onSave,
            onExit: onExit
        )
    }
}
/*
struct BaseWeightEditor: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @State private var inputValue: String = ""
    @FocusState private var isFocused: Bool
    let exercise: Exercise
    let gymEquip: GymEquipment
    var onSave: (Double) -> Void
    var onExit: () -> Void
    
    var body: some View {
        VStack {
            Text("Set Base Weight for \(gymEquip.name)")
                .font(.headline)
                .padding()
            
            TextField("Enter weight (\(UnitSystem.current.weightUnit))", text: $inputValue)
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
                        onSave(newValue)
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
        inputValue = gymEquip.baseWeight?.resolvedMass.displayString ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isFocused = true }
    }
    
    private func buttonAction() {
        isFocused = false
        onExit()
    }
}
*/
