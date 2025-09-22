//
//  ExerciseSetOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ExerciseSetOverlay: View {
    let timerManager: TimerManager
    @Binding var exercise: Exercise
    @State private var isPressed: Bool = false
    @State private var showAdjustmentsView: Bool = false
    @State private var shouldDisableNext: Bool = false
    @State private var showPlateVisualizer: Bool = false
    @State private var showPicker: Bool = false
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
            
            if let detail = currentSetBinding {
                if !showPicker {
                    // Equipment Adjustments + Info button
                    adjustmentsSection
                }
                                
                // Display the set editor
                ExerciseSetDisplay(
                    timerManager: timerManager,
                    setDetail: detail,
                    shouldDisableNext: $shouldDisableNext,
                    showPicker: $showPicker,
                    exercise: exercise,
                    saveTemplate: {
                        saveTemplate(detail, $exercise)
                    }
                )
                
                if !showPicker {
                    NextButton(
                        timerManager: timerManager,
                        isPressed: $isPressed,
                        exercise: exercise,
                        isLastExercise: progress.isLastExercise,
                        restTimerEnabled: progress.restTimerEnabled,
                        isDisabled: shouldDisableNext,
                        onButtonPress: {
                            return handleButtonPress(setDetail: detail)
                        },
                        goToNextSetOrExercise: goToNextSetOrExercise
                    )
                }
            } else {
                Text("No current set available")
            }
        }
        .padding()
        .disabled(exercise.isCompleted)
        .sheet(isPresented: $showAdjustmentsView) { AdjustmentsView(exercise: exercise) }
        .sheet(isPresented: $showPlateVisualizer) {
            if let detail = currentSetBinding, let weight = detail.wrappedValue.load.weight {
                PlateVisualizer(
                    weight: weight,
                    exercise: exercise
                )
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // TODO: use this layout to make a generic toolbar header that we can use instead of a real toolbar
    private var exerciseToolbar: some View {
        HStack {
            let width: CGFloat = UIScreen.main.bounds.width
            
            Text("Exercise \n\(progress.exerciseIdx + 1) of \(progress.numExercises)")
                .frame(maxWidth: width * 0.15)
                .foregroundStyle(.gray)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .center) {
                Text("\(exercise.name)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: width * 0.7)
     
                Text("Sets: \(exercise.workingSets)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)
            
            Button(action: onClose) {
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: width * 0.15)
        }
        .padding(.bottom)
    }
    
    private var adjustmentsSection: some View {
        HStack {
            AdjustmentsSection(
                showingAdjustmentsView: $showAdjustmentsView,
                showingPlateVisualizer: $showPlateVisualizer,
                hidePlateVisualizer: false,
                exercise: exercise
            )
            ExEquipImage(image: exercise.fullImage, button: .info, onTap: { viewDetail() })
        }
    }
    
    private var currentSetBinding: Binding<SetDetail>? {
        let i = exercise.currentSetIndex              // 0-based
        guard exercise.allSetDetails.indices.contains(i) else { return nil }

        return Binding(
            get: { exercise.allSetDetails[i] },
            set: { newVal in
                if i < exercise.warmUpSets {
                    exercise.warmUpDetails[i] = newVal
                } else {
                    exercise.setDetails[i - exercise.warmUpSets] = newVal
                }
            }
        )
    }
    
    private func handleButtonPress(setDetail: Binding<SetDetail>) -> Int {
        let priorMax = getPriorMax(exercise.id)
        let defaultRest = exercise.getRestPeriod(isWarm: exercise.isWarmUp, rest: progress.restPeriods)
        let restForSet = setDetail.wrappedValue.restPeriod ?? defaultRest
        
        // ── A) Repetition-driven sets (compound/isolation) ─────────────────────
        let best: PeakMetric = priorMax ?? exercise.getPeakMetric(metricValue: 0)
        let result = setDetail.wrappedValue.updateCompletedMetrics(currentBest: best)
        if let newPR = result.newMax {
            onPerformanceUpdate(PerformanceUpdate(
                exerciseId: exercise.id,
                value: newPR,
                repsXweight: result.rxw,
                setId: setDetail.id
            ))
        }
        
        return restForSet
    }
}

