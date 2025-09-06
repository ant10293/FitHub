//
//  UpdateEditorStyling.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/1/25.
//

import SwiftUI

struct GenericEditor: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var inputValue: String = ""
    @FocusState private var isFocused: Bool
    
    let title: String
    let placeholder: String
    let initialValue: String
    let onSave: (Double) -> Void
    let onExit: () -> Void
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()
            
            TextField(placeholder, text: $inputValue)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .padding(8)
                .roundedBackground()
                .padding(.horizontal)
          
            HStack(spacing: 20) {
                Spacer()
                
                Button(action: buttonAction) {
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
        inputValue = initialValue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isFocused = true }
    }
    
    private func buttonAction() {
        isFocused = false
        onExit()
    }
}
