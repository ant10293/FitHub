//
//  SimilarExercisesRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/17/25.
//

import SwiftUI

struct SimilarExercisesRow: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var isLoading: Bool = false
    @Binding var loadedExercises: [Exercise]?
    let exercise: Exercise
    
    var body: some View {
        Group {
            if let exercises = loadedExercises {
                if !exercises.isEmpty {
                    ExerciseScrollRow(
                        userData: ctx.userData,
                        exercises: exercises,
                        title: "Similar Exercises"
                    )
                }
            } else if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Finding similar exercises…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            } else {
                // Not loaded yet, trigger lazily when this section appears
                Color.clear
                    .frame(height: 1)
                    .onAppear(perform: loadIfNeeded)
            }
        }
    }
    
    private func loadIfNeeded() {
        guard !isLoading, loadedExercises == nil else { return }
        isLoading = true
        
        // If you want this completely off the main thread, you can move the
        // heavy work into a detached Task; but often just doing it here is fine
        Task {
            let result = ctx.exercises.similarExercises(
                to: exercise,
                equipmentData: ctx.equipment,
                availableEquipmentIDs: ctx.userData.evaluation.availableEquipment,
                needPerformanceData: false,
                canPerformRequirement: false
            )
            
            await MainActor.run {
                self.loadedExercises = result   // cache
                self.isLoading = false
            }
        }
    }
}
