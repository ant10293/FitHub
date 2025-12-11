//
//  EnterMaxReps.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EnterMaxReps: View {
    @ObservedObject var userData: UserData
    @ObservedObject var exerciseData: ExerciseData
    @State private var situpReps: String = ""
    @State private var squatReps: String = ""
    @State private var pushupReps: String = ""
    var situp: Exercise? = nil
    var squat: Exercise? = nil
    var pushup: Exercise? = nil
    let onFinish: () -> Void
    
    init(
        userData: UserData,
        exerciseData: ExerciseData,
        onFinish: @escaping () -> Void
    ) {
        self.userData = userData
        self.exerciseData = exerciseData
        self.onFinish = onFinish
        
        if let situp = exerciseData.exercise(named: "Sit-Up") { self.situp = .init(situp) }
        if let pushup = exerciseData.exercise(named: "Push-Up") { self.pushup = .init(pushup) }
        if let squat = exerciseData.exercise(named: "Bodyweight Squat") { self.squat = .init(squat) }
        
        if let situp = self.situp, let max = exerciseData.peakMetric(for: situp.id) {
            _situpReps = .init(initialValue: max.displayString)
        }
        
        if let pushup = self.pushup, let max = exerciseData.peakMetric(for: pushup.id) {
            _pushupReps = .init(initialValue: max.displayString)
        }
        
        if let squat = self.squat, let max = exerciseData.peakMetric(for: squat.id) {
            _squatReps = .init(initialValue: max.displayString)
        }
    }

    var body: some View {
        AssessmentFormView(
            title: "Enter Max Reps",
            headline: "How many reps can you perform consecutively?",
            subheadline: "Enter your max reps for at least one of the exercises below.",
            inputFields: [
                AssessmentInputField(label: "Push ups", text: $pushupReps, placeholder: "Enter Reps"),
                AssessmentInputField(label: "Sit ups", text: $situpReps, placeholder: "Enter Reps"),
                AssessmentInputField(label: "Squats", text: $squatReps, placeholder: "Enter Reps")
            ],
            submitEnabled: submitEnabled,
            onSubmit: handleSubmit
        ) 
    }
    
    private var submitEnabled: Bool { !pushupReps.isEmpty && !situpReps.isEmpty && !squatReps.isEmpty }

    private func handleSubmit() {
        var maxValuesEntered = false
        
        if let situps = Int(situpReps), let situp = situp {
            exerciseData.updateExercisePerformance(for: situp, newValue: .maxReps(situps))
            maxValuesEntered = true
        }
        
        if let pushups = Int(pushupReps), let pushup = pushup {
            exerciseData.updateExercisePerformance(for: pushup, newValue: .maxReps(pushups))
            maxValuesEntered = true
        }
        
        if let squats = Int(squatReps), let squat = squat {
            exerciseData.updateExercisePerformance(for: squat, newValue: .maxReps(squats))
            maxValuesEntered = true
        }
        
        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.setup.maxRepsEntered = true
            onFinish()
        }
    }
    
}

