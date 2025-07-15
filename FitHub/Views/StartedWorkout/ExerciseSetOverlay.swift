//
//  ExerciseSetOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ExerciseSetOverlay: View {
    let timerManager: TimerManager
    @ObservedObject var adjustments: AdjustmentsData
    @ObservedObject var equipmentData: EquipmentData
    @Binding var exercise: Exercise
    @State private var isPressed: Bool = false
    @State private var showingAdjustmentsView: Bool = false
    @State private var shouldDisableNext: Bool = false
    @State private var showOverlay: Bool = false
    let progress: TemplateProgress
    var goToNextSetOrExercise: () -> Void
    var onClose: () -> Void
    var viewDetail: () -> Void
    //let getPriorMax: (String) -> Double
    let getPriorMax: (UUID) -> Double
    var onPerformanceUpdate: (PerformanceUpdate) -> Void
    var saveTemplate: (Binding<SetDetail>, Binding<Exercise>) -> Void

    var body: some View {
        VStack {
            exerciseToolbar
            
            if let detail = currentSetBinding(for: $exercise) {
                // Equipment Adjustments + Info button
                adjustmentsSection

                // Display the set editor
                ExerciseSetDisplay(
                    setDetail: detail,
                    shouldDisableNext: $shouldDisableNext,
                    exercise: exercise,
                    saveTemplate: {
                        saveTemplate(detail, $exercise)
                    }
                )

                if !exercise.isCompleted {
                    NextButton(
                        timerManager: timerManager,
                        exercise: $exercise,
                        isPressed: $isPressed,
                        isLastExercise: progress.isLastExercise,
                        restTimerEnabled: progress.restTimerEnabled,
                        restPeriod: progress.restPeriod,
                        goToNextSetOrExercise: goToNextSetOrExercise,
                        getPriorMax: { id in
                            getPriorMax(id)
                        },
                        onPerformanceUpdate: { update in 
                            onPerformanceUpdate(update)
                        }
                    )
                    .disabled(shouldDisableNext)
                }
            } else {
                Text("No current set available")
            }
        }
        .padding()
        .disabled(exercise.isCompleted)
        .sheet(isPresented: $showingAdjustmentsView, onDismiss: { showingAdjustmentsView = false }) {
            AdjustmentsView(AdjustmentsData: adjustments, exercise: exercise)
        }
    }
    
    private var exerciseToolbar: some View {
        HStack {
            Text("Exercise \n\(progress.exerciseIdx + 1) of \(progress.numExercises)")
                .frame(maxWidth: UIScreen.main.bounds.width * 0.15)
                .foregroundColor(.gray)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            VStack(alignment: .center) {
                Text("\(exercise.name)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.5)  // ≈ 1/2 screen
                
                Text("Sets: \(exercise.sets)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }.padding(.horizontal).zIndex(1)
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.gray)
                    .padding()
            }.contentShape(Rectangle())
           
        }
        .padding(.top, -15)
    }
    
    private var adjustmentsSection: some View {
        HStack {
            AdjustmentsSection(adjustments: adjustments, equipmentData: equipmentData, showingAdjustmentsView: $showingAdjustmentsView, exercise: exercise)
            Button(action: viewDetail) {
                ExEquipImage(exercise.fullImage)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func currentSetBinding(for exercise: Binding<Exercise>) -> Binding<SetDetail>? {
        let i = exercise.wrappedValue.currentSet - 1               // 0-based
        guard exercise.wrappedValue.allSetDetails.indices.contains(i) else { return nil }

        return Binding(
            get: { exercise.wrappedValue.allSetDetails[i] },
            set: { newVal in
                if i < exercise.wrappedValue.warmUpSets {
                    exercise.wrappedValue.warmUpDetails[i] = newVal
                } else {
                    exercise.wrappedValue.setDetails[i - exercise.wrappedValue.warmUpSets] = newVal
                }
            }
        )
    }
}

