//
//  ExerciseSetOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ExerciseSetOverlay: View {
    let timerManager: TimerManager
    @ObservedObject var equipment: EquipmentData
    @Binding var exercise: Exercise
    @State private var isPressed: Bool = false
    @State private var showAdjustmentsView: Bool = false
    @State private var shouldDisableNext: Bool = false
    @State private var showOverlay: Bool = false
    @State private var showPlateVisualizer: Bool = false
    var progress: TemplateProgress
    var goToNextSetOrExercise: () -> Void
    var onClose: () -> Void
    var viewDetail: () -> Void
    let getPriorMax: (Exercise.ID) -> PeakMetric?
    var onPerformanceUpdate: (PerformanceUpdate) -> Void
    var saveTemplate: (Binding<SetDetail>, Binding<Exercise>) -> Void

    var body: some View {
        VStack {
            exerciseToolbar
            
            if let detail = currentSetBinding(for: $exercise) {
                // Equipment Adjustments + Info button
                adjustmentsSection
                
                if exercise.usesPlates(equipmentData: equipment) {
                    Button("View Plate Configuration") {
                        showPlateVisualizer = true
                    }
                }
                
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
                        restPeriods: progress.restPeriods,
                        isDisabled: shouldDisableNext,
                        goToNextSetOrExercise: goToNextSetOrExercise,
                        getPriorMax: { id in
                            getPriorMax(id)
                        },
                        onPerformanceUpdate: { update in 
                            onPerformanceUpdate(update)
                        }
                    )
                }
            } else {
                Text("No current set available")
            }
        }
        .padding()
        .disabled(exercise.isCompleted)
        .sheet(isPresented: $showAdjustmentsView) {
            AdjustmentsView(exercise: exercise)
        }
        /*.sheet(isPresented: $showPlateVisualizer) {
            if let detail = currentSetBinding(for: $exercise) {
                PlateVisualizer(
                    weight: detail.weight.wrappedValue,
                    exercise: exercise
                )
                .presentationDetents([.fraction(0.75)]) // only 3/4 height
                .presentationDragIndicator(.visible)
            }
        }*/
        .navigationDestination(isPresented: $showPlateVisualizer) {
            if let detail = currentSetBinding(for: $exercise) {
                PlateVisualizer(
                    weight: detail.weight.wrappedValue,
                    exercise: exercise
                )
            }
        }
    }

    private var exerciseToolbar: some View {
        HStack {
            Text("Exercise \n\(progress.exerciseIdx + 1) of \(progress.numExercises)")
                .frame(maxWidth: UIScreen.main.bounds.width * 0.15)
                .foregroundStyle(.gray)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            VStack(alignment: .center) {
                Text("\(exercise.name)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.5)  // ≈ 1/2 screen
                
                Text("Sets: \(exercise.workingSets)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }.padding(.horizontal).zIndex(1)
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.gray)
                    .padding()
            }.contentShape(Rectangle())
           
        }
        .padding(.top, -15)
    }
    
    private var adjustmentsSection: some View {
        HStack {
            AdjustmentsSection(showingAdjustmentsView: $showAdjustmentsView, exercise: exercise)
            ExEquipImage(image: exercise.fullImage, button: .info, onTap: { viewDetail() })
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

