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
    @StateObject private var kbd = KeyboardManager.shared
    @State private var situpReps: String = ""
    @State private var squatReps: String = ""
    @State private var pushupReps: String = ""
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea(.all)
                .zIndex(0)
            
            VStack {
                Spacer()
                
                Text("How many reps can you perform consecutively in each bodyweight exercise?")
                    .font(.headline)
                    .padding()
                    .multilineTextAlignment(.center)

                VStack(spacing: 15) {
                    InputSection(label: "Push ups", value: $pushupReps)
                    InputSection(label: "Sit ups", value: $situpReps)
                    InputSection(label: "Squats", value: $squatReps)
                }
                
                Spacer()
                
                if !kbd.isVisible {
                    RectangularButton(title: "Submit", enabled: submitEnabled, color: submitEnabled ? .green : .gray, action: handleSubmit)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationBarTitle("Enter Max Reps", displayMode: .large)
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }
    
    private var submitEnabled: Bool { !pushupReps.isEmpty && !situpReps.isEmpty && !squatReps.isEmpty }

    private func handleSubmit() {
        var maxValuesEntered = false
        
        if let situps = Int(situpReps) {
            if let situp = exerciseData.exercise(named: "Sit-Up") {
                exerciseData.updateExercisePerformance(for: situp, newValue: .maxReps(situps))
            }
            maxValuesEntered = true
        }
        
        if let pushups = Int(pushupReps) {
            if let pushup = exerciseData.exercise(named: "Push-Up") {
                exerciseData.updateExercisePerformance(for: pushup, newValue: .maxReps(pushups))
            }
            maxValuesEntered = true
        }
        
        if let squats = Int(squatReps) {
            if let squat = exerciseData.exercise(named: "Bodyweight Squat") {
                exerciseData.updateExercisePerformance(for: squat, newValue: .maxReps(squats))
            }
            maxValuesEntered = true
        }
        
        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.setup.maxRepsEntered = true
           // userData.saveSingleStructToFile(\.setup, for: .setup)
            onFinish()
        }
    }
    
    private func InputSection(label: String, value: Binding<String>) -> some View {
        InputField(text: value, label: label, placeholder: "Enter Reps")
    }
}

