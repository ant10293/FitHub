//
//  UpdateMax.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct UpdateMaxView: View {
    @State var usesWeight: Bool
    var onSave: (Double) -> Void
    var onCancel: () -> Void
    @State private var isKeyboardVisible = false
    @State private var newOneRepMax: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(usesWeight ? "Update 1 Rep Max" : "Update Max Reps")
                .font(.headline)
            
            TextField(usesWeight ? "Enter new 1RM" : "Enter new Reps", text: $newOneRepMax)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .focused($isTextFieldFocused)
                .onAppear {
                    // Automatically focus on the text field when the view appears
                    isTextFieldFocused = true
                }
            
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                Button(action: {
                    if let newValue = Double(newOneRepMax) {
                        onSave(newValue)
                    }
                }) {
                    Text(" Save ")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(newOneRepMax.isEmpty)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}
