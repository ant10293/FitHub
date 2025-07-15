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
    var restPeriod: Int
    let goToNextSetOrExercise: () -> Void
    //let getPriorMax: (String) -> Double
    let getPriorMax: (UUID) -> Double
    var onPerformanceUpdate: (PerformanceUpdate) -> Void
    
    var index: Int { exercise.currentSet - 1 }
    
    var body: some View {
        VStack {
            if timerManager.restIsActive {
                Text("Rest for \(formattedTime(time: timerManager.restTimeRemaining))")
                    .font(.headline)
                    .padding()
                Button(action: skipRest) {
                    HStack {
                        Text("Skip Rest")
                        Image(systemName: "forward.circle.fill")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.red))
                    .foregroundColor(.white)
                }
            } else {
                Button(action: handleButtonPress) {
                    HStack {
                        if index < exercise.allSetDetails.count - 1 {
                            Text("Next Set")
                            //Image(systemName: "forward.circle.fill")
                            Image(systemName: "arrow.right.circle.fill")
                        } else if isLastExercise {
                            Text("Finish Workout")
                            Image(systemName: "flag.checkered.circle.fill")
                        } else {
                            Text("Next Exercise")
                            //Image(systemName: "forward.end.circle.fill")
                            Image(systemName: "arrowshape.forward.circle.fill")
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func handleButtonPress() {
        let warmCount = exercise.warmUpSets
        let isWarm = index < warmCount
        let detailIdx = isWarm ? index : index - warmCount

        // Get and update SetDetail
        var detail = isWarm ? exercise.warmUpDetails[detailIdx] : exercise.setDetails[detailIdx]

        if detail.repsCompleted == nil {
            detail.repsCompleted = detail.reps
        }
        let repsComp = detail.repsCompleted ?? 0

        // Write back to correct array
        if isWarm {
            exercise.warmUpDetails[detailIdx] = detail
        } else {
            exercise.setDetails[detailIdx] = detail
        }

        let weightUsed = detail.weight
        let rxw = RepsXWeight(reps: repsComp, weight: weightUsed)
        let setNum = exercise.currentSet - warmCount
        let priorMax = getPriorMax(exercise.id)

        if !exercise.type.usesWeight {
            let result = detail.updateCompletedReps(repsCompleted: repsComp, maxReps: Int(priorMax))
            if let newMax = result.newMaxReps {
                onPerformanceUpdate(PerformanceUpdate(exerciseId: exercise.id, exerciseName: exercise.name, value: Double(newMax), repsXweight: rxw, setNumber: setNum))
            }
        } else {
            let result = detail.updateCompletedRepsAndRecalculate(repsCompleted: repsComp, oneRepMax: priorMax)
            if let new1RM = result.new1RM {
                onPerformanceUpdate(PerformanceUpdate(exerciseId: exercise.id, exerciseName: exercise.name, value: new1RM, repsXweight: rxw, setNumber: setNum))
            }
        }

        proceedToNextStep()
    }

    private func proceedToNextStep() {
        isPressed = true
        goToNextSetOrExercise()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Only skip rest if this is the final set of the final exercise:
            if isLastExercise && index == exercise.allSetDetails.count - 1 {
                isPressed = false
            }
            // Otherwise, if rest‐timers are on, show it
            else if restTimerEnabled && !timerManager.restIsActive {
                timerManager.startRest(for: restPeriod)
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

    private func formattedTime(time: Int) -> String {
        let m = time / 60
        let s = time % 60
        return String(format: "%d:%02d", m, s)
    }
}




