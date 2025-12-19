//
//  ExerciseSetOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ExerciseSetOverlay: View {
    @Binding var exercise: Exercise
    @State private var nextPressed: Bool = false
    @State private var showAdjustmentsView: Bool = false
    @State private var shouldDisableNext: Bool = false
    @State private var showPlateVisualizer: Bool = false
    @State private var showPicker: Bool = false
    let timerManager: TimerManager
    let progress: TemplateProgress
    let params: UserParams
    let goToNextSetOrExercise: () -> Void
    let onClose: () -> Void
    let viewDetail: () -> Void
    let getPriorMax: (Exercise.ID) -> PeakMetric?
    let getAvailableImplements: (Exercise) -> Implements?
    let onPerformanceUpdate: (PerformanceUpdate) -> Void
    let saveTemplate: (Binding<SetDetail>, Binding<Exercise>) -> Void

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
                    setDetail: detail,
                    shouldDisableNext: $shouldDisableNext,
                    showPicker: $showPicker,
                    timerManager: timerManager,
                    hideRPE: params.hideRPE,
                    hideCompleted: params.hideCompleted,
                    exercise: exercise
                )

                if !showPicker {
                    NextButton(
                        timerManager: timerManager,
                        isPressed: $nextPressed,
                        exercise: exercise,
                        isLastExercise: progress.isLastExercise,
                        restTimerEnabled: params.restTimerEnabled,
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
        CenteredOverlayHeader(
            leading: {
                Text("Exercise \n\(progress.exerciseIdx + 1) of \(progress.numExercises)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            },
            center: {
                VStack(alignment: .center, spacing: 4) {
                    Button(action: viewDetail) {
                        HStack(spacing: 5) {
                            Text(exercise.name)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    Text("Sets: \(exercise.workingSets)")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal)
            },
            trailing: {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.gray)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        )
        .padding(.bottom)
    }

    private var adjustmentsSection: some View {
        VStack {
            HStack {
                AdjustmentsSection(
                    showingAdjustmentsView: $showAdjustmentsView,
                    showingPlateVisualizer: $showPlateVisualizer,
                    hidePlateVisualizer: false,
                    exercise: exercise
                )
                if !params.hideImage {
                    ExEquipImage(image: exercise.fullImage)
                }
            }
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
        let defaultRest = exercise.getRestPeriod(isWarm: exercise.isWarmUp, rest: params.restPeriods)
        let restForSet = setDetail.wrappedValue.restPeriod ?? defaultRest

        // ── A) Repetition-driven sets (compound/isolation) ─────────────────────
        let best: PeakMetric = priorMax ?? exercise.getPeakMetric(metricValue: 0)
        let availableImplements = getAvailableImplements(exercise)
        let result = setDetail.wrappedValue.updateCompletedMetrics(currentBest: best, availableImplements: availableImplements)
        if let newPR = result.newMax {
            onPerformanceUpdate(PerformanceUpdate(
                exerciseId: exercise.id,
                value: newPR,
                loadXmetric: result.lxm,
                setId: setDetail.id
            ))
        }
        saveTemplate(setDetail, $exercise)

        return restForSet
    }
}
