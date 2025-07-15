//
//  ImageField.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/10/25.
//

import SwiftUI

struct ImageField: View {
    var initialFilename: String? = nil
    var onImageUpdate: (String) -> Void = { _ in }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            Text("Image")
                .font(.headline)
            
            Group {
                // Picker
                UploadImageDemo(initialFilename: initialFilename) { name in
                    onImageUpdate(name)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))  // darker card
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15))
            )
        }
    }
}
