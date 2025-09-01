//
//  InputField.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/14/25.
//

import SwiftUI

struct InputField: View {
    // MARK: – Public API
    @Binding var text: String
    var label: String
    var placeholder: String
    var keyboard: UIKeyboardType = .decimalPad
    
    // MARK: – Body
    var body: some View {
        HStack {
            Spacer(minLength: 20)
            
            Text(label)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .padding()
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            
            Spacer(minLength: 20)
        }
    }
}
