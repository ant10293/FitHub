//
//  NextButton.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct NextButton: View {
    @ObservedObject var timerManager: TimerManager
    @Binding var isPressed: Bool
    let exercise: Exercise
    let isLastExercise: Bool
    let restTimerEnabled: Bool
    let isDisabled: Bool
    let onButtonPress: () -> Int
    let goToNextSetOrExercise: () -> Void
        
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
                    Text("Set field(s) must exceed zero.")
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
                    .roundedBackground(cornerRadius: 10, color: isDisabled ? .gray : .blue)
                    .foregroundStyle(.white)
                }
                .disabled(isDisabled)
            }
        }
    }
    
    private var buttonInfo: (Label: String, Image: String) {
        if exercise.currentSetIndex < exercise.totalSets - 1 {
            return ("Next Set", "arrow.right.circle.fill")
        } else if isLastExercise {
            return ("Finish Workout", "flag.checkered.circle.fill")
        } else {
            return ("Next Exercise", "arrowshape.forward.circle.fill")
        }
    }
    
    private func handleButtonPress() {
        let restForSet = onButtonPress()
        proceedToNextStep(restForSet: restForSet)
    }
    
    private func proceedToNextStep(restForSet: Int) {
        isPressed = true
        goToNextSetOrExercise()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Only skip rest if this is the final set of the final exercise:
            if isLastExercise && exercise.currentSetIndex == exercise.totalSets - 1 {
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
        timerManager.stopRest()
        isPressed = false
    }
}




