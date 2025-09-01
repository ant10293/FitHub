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
    var rest: RestPeriods
    var onReplaceExercise: () -> Void
    var onRemoveExercise: () -> Void
    var onClose: () -> Void
    var onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if exercise.type.usesWeight {
                Button(action: {
                    withAnimation {
                        showWarmupSets.toggle()
                    }
                }) {
                    HStack {
                        Text("Warm-up Sets")
                        Image(systemName: "flame.fill")
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                withAnimation {
                    showRestTimeEditor.toggle()
                }
            }) {
                HStack {
                    Text("Adjust Rest Timer")
                    Image(systemName: "timer")
                }
                .foregroundStyle(.blue)
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
                .foregroundStyle(.blue)
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
                .foregroundStyle(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showRestTimeEditor) {
            RestTimeEditor(exercise: $exercise, rest: rest, onSave: {
                onSave()
            })
        }
        .sheet(isPresented: $showWarmupSets) {
            WarmUpSetsEditorView(exercise: $exercise, onSave: {
                onSave()
            })
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 5)
    }
}



