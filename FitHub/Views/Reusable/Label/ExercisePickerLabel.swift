//
//  ExercisePickerLabel.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/8/25.
//

import SwiftUI

struct ExercisePickerLabel: View {
    let exerciseName: String?
    var defaultLabel: String = "Select Exercise"

    var body: some View {
        HStack(spacing: 5) {
            Text(exerciseName ?? defaultLabel)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.blue)
    }
}
