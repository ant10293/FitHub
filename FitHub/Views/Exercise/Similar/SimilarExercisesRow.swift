//
//  SimilarExercisesRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/23/25.
//

import SwiftUI

struct SimilarExerciseRow: View {
    @State private var showDetails = false
    let userData: UserData
    let exercise: Exercise
    let baseExercise: Exercise          // used only for %-match math
    let onReplace: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ── top line ───────────────────────────────────────────────
            HStack(spacing: 12) {
                exercise.fullImageView(favState: FavoriteState.getState(for: exercise, userData: userData))
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .minimumScaleFactor(0.75)
                    
                    // %-similar badge
                    Text("\(similarityPercent)% similarity")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Button(action: onReplace) {              // <-- ONLY this triggers replace
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .padding(8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)                // don’t steal tap-area from row
            }
            
            // ── expanded details ───────────────────────────────────────
            if showDetails {
                Text("\(exercise.musclesTextFormatted)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .transition(.opacity.combined(with: .slide))
            }
            
            // “View more / Hide details” toggle
            Button(showDetails ? "Hide details" : "View more") {
                withAnimation { showDetails.toggle() }
            }
            .font(.caption)
            .foregroundStyle(.blue)
            .buttonStyle(.plain)                         // keeps entire row passive
        }
        .padding(.vertical, 4)
    }
    
    // quick similarity heuristic: (# shared muscles) / (# union) × 100
    private var similarityPercent: Int {
        let sharedPrimaries   = exercise.primaryMuscles == baseExercise.primaryMuscles
            ? baseExercise.primaryMuscles.count : 0
        let sharedSecondaries = Set(exercise.secondaryMuscles).intersection(baseExercise.secondaryMuscles).count
        let shared  = sharedPrimaries + sharedSecondaries
        let union   = Set(exercise.primaryMuscles + exercise.secondaryMuscles
                        + baseExercise.primaryMuscles + baseExercise.secondaryMuscles).count
        
        return union == 0 ? 0 : Int((Double(shared) / Double(union)) * 100.0)
    }
}
