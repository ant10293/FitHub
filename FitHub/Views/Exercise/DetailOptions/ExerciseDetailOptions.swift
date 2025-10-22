//
//  ExerciseDetailOptions.swift
//  FitHub
//
//  Created by Anthony Cantu on 4/5/25.
//

import SwiftUI


/// Encapsulates all the exercise detail options including adding warm-up sets,
/// replacing, removing, and editing custom rest times inline.
struct ExerciseDetailOptions: View {
    @Binding var template: WorkoutTemplate
    @Binding var exercise: Exercise
    @State private var replacedExercises: [String] = []
    @State private var showRestTimeEditor: Bool = false
    @State private var showWarmupSets: Bool = false
    let onReplaceExercise: () -> Void
    let onRemoveExercise: () -> Void
    let onClose: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if exercise.usesWeight {
                TextButton(
                    title: "Warm-up Sets",
                    systemImage: "flame.fill",
                    action: { showWarmupSets.toggle() },
                    color: .blue
                )
            }
            
            TextButton(
                title: "Adjust Rest Timer",
                systemImage: "timer",
                action: { showRestTimeEditor.toggle() },
                color: .blue
            )
            .disabled(exercise.totalSets == 0)
            
            TextButton(
                title: "Replace Exercise",
                systemImage: "arrow.triangle.2.circlepath",
                action: {
                    onReplaceExercise()
                    onClose()
                },
                color: .blue
            )
            
            TextButton(
                title: "Remove Exercise",
                systemImage: "trash",
                action: {
                    onRemoveExercise()
                    onClose()
                },
                color: .red
            )
        }
        .sheet(isPresented: $showRestTimeEditor) {
            RestTimeEditor(exercise: $exercise, onSave: {
                onSave()
            })
        }
        .sheet(isPresented: $showWarmupSets) {
            ExerciseWarmUpDetail(exercise: $exercise, onSave: {
                onSave()
            })
        }
        .cardContainer(
            cornerRadius: 8,
            shadowRadius: 5,
            backgroundColor: Color(UIColor.secondarySystemBackground)
        )
    }
}

