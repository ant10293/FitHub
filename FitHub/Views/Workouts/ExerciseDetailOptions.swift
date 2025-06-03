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
    @State private var showRestTimerEditor: Bool = false
    @State private var showWarmupSets: Bool = false
    var roundingPreference: [EquipmentCategory: Double]
    var setStructure: SetStructures = .pyramid
    var onReplaceExercise: () -> Void
    var onRemoveExercise: () -> Void
    var onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if exercise.usesWeight {
                Button(action: {
                    withAnimation {
                        showWarmupSets.toggle()
                    }
                }) {
                    HStack {
                        Text("Warm-up Sets")
                        Image(systemName: "flame.fill")
                        //Text("+")
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                withAnimation {
                    showRestTimerEditor.toggle()
                }
            }) {
                HStack {
                    Text("Adjust Rest Timer")
                    Image(systemName: "timer")
                }
                .foregroundColor(.blue)
            }
            .disabled(exercise.totalSets == 0)
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                onReplaceExercise()
                onClose()
            }) {
                HStack {
                    Text("Replace Exercise")
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())

            
            Button(role: .destructive, action: {
                onRemoveExercise()
                onClose()
            }) {
                HStack {
                    Text("Remove Exercise")
                    Image(systemName: "trash")
                }
                .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showRestTimerEditor) {
            RestTimerEditor(exercise: $exercise)
        }
        .sheet(isPresented: $showWarmupSets) {
            WarmUpSetsEditorView(exercise: $exercise, setStructure: setStructure, roundingPreference: roundingPreference)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 5)
    }
}



