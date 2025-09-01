//
//  NextButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct NextButton: View {
    @ObservedObject var timerManager: TimerManager
    @Binding var exercise: Exercise
    @Binding var isPressed: Bool
    @State private var skipPressed: Bool = false
    let isLastExercise: Bool
    var restTimerEnabled: Bool
    var restPeriods: RestPeriods
    let isDisabled: Bool
    let goToNextSetOrExercise: () -> Void
    let getPriorMax: (Exercise.ID) -> PeakMetric? // kg for 1RM, reps for bw, seconds for isometric
    var onPerformanceUpdate: (PerformanceUpdate) -> Void
    
    var index: Int { exercise.currentSet - 1 }
    
    var body: some View {
        VStack {
            if timerManager.restIsActive {
                Text("Rest for \(Format.timeString(from: timerManager.restTimeRemaining))")
                    .font(.headline)
                    .padding(.bottom)
                Button(action: skipRest) {
                    HStack {
                        Text("Skip Rest")
                        Image(systemName: "forward.circle.fill")
                    }
                    .padding()
                    .roundedBackground(cornerRadius: 10, color: .red)
                    .foregroundStyle(.white)
                }
            } else {
                if isDisabled {
                    Text(exercise.type.usesWeight ? "Invalid weight or reps field." : (exercise.effort.usesReps ? "Invalid reps field." : "Invalid time field."))
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                Button(action: handleButtonPress) {
                    let button = buttonInfo // Call computed property once
                    HStack {
                        Text(button.Label)
                        Image(systemName: button.Image)
                    }
                    .padding()
                    .roundedBackground(cornerRadius: 10, color: isDisabled ? .gray : button.Color)
                    .foregroundStyle(.white)
                }
                .disabled(isDisabled)
            }
        }
    }
    
    private var buttonInfo: (Label: String, Image: String, Color: Color) {
        let currentIndex = exercise.currentSet - 1
        let totalSets = exercise.allSetDetails.count
                      
        if currentIndex < totalSets - 1 {
            return ("Next Set", "arrow.right.circle.fill", .blue)
        } else if isLastExercise {
            return ("Finish Workout", "flag.checkered.circle.fill", .green)
        } else {
            return ("Next Exercise", "arrowshape.forward.circle.fill", .blue)
        }
    }

    private func handleButtonPress() {
        let warmCount = exercise.warmUpSets
        let isWarm = index < warmCount
        let detailIdx = isWarm ? index : index - warmCount

        // Pull set detail (copy → mutate → write back)
        var detail = isWarm ? exercise.warmUpDetails[detailIdx] : exercise.setDetails[detailIdx]
                
        // Build PR context
        let setNum   = exercise.currentSet - warmCount
        let priorMax = getPriorMax(exercise.id)
        
        let restForSet = detail.restPeriod ?? exercise.getRestPeriod(isWarm: isWarm, rest: restPeriods)

        // ── A) Repetition-driven sets (compound/isolation) ─────────────────────
        let best: PeakMetric = priorMax ?? exercise.getPeakMetric(metricValue: 0)
        let result = detail.updateCompletedMetrics(currentBest: best)
        if let newPR = result.newMax {
            onPerformanceUpdate(PerformanceUpdate(
                exerciseId: exercise.id,
                value: newPR,
                repsXweight: result.rxw,
                setNumber: setNum
            ))
        }

        // Write back the mutated detail
        if isWarm {
            exercise.warmUpDetails[detailIdx] = detail
        } else {
            exercise.setDetails[detailIdx] = detail
        }

        proceedToNextStep(restForSet: restForSet)
    }
    
    private func proceedToNextStep(restForSet: Int) {
        isPressed = true
        goToNextSetOrExercise()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Only skip rest if this is the final set of the final exercise:
            if isLastExercise && index == exercise.allSetDetails.count - 1 {
                isPressed = false
            }
            // Otherwise, if rest‐timers are on, show it
            else if restTimerEnabled && !timerManager.restIsActive {
                timerManager.startRest(for: restForSet)
            }
            // Or immediately unpress the button
            else {
                isPressed = false
                timerManager.restIsActive = false
            }
        }
    }

    private func skipRest() {
        skipPressed = true
        timerManager.stopRest()
        isPressed = false
    }
}




