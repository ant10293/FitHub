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
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea(.all)
                .zIndex(0)
            
            VStack {
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
                    ActionButton(title: "Submit", enabled: submitEnabled, color: submitEnabled ? .green : .gray, action: handleSubmit)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationBarTitle("Enter your Max Reps", displayMode: .large)
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }
    
    private var submitEnabled: Bool { !pushupReps.isEmpty && !situpReps.isEmpty && !squatReps.isEmpty }

    private func handleSubmit() {
        var maxValuesEntered = false
        
        if let situps = Double(situpReps) {
            if let situp = exerciseData.exercise(named: "Sit-Up") {
                // "D011FE15-0E04-411E-BF9E-5153634CE050"
                exerciseData.updateExercisePerformance(for: situp, newValue: situps, csvEstimate: false)
            }
            maxValuesEntered = true
        }
        
        if let pushups = Double(pushupReps) {
            if let pushup = exerciseData.exercise(named: "Push-Up") {
                // "D314DC2A-60C4-4C25-A2CB-F46023462D2E"
                exerciseData.updateExercisePerformance(for: pushup, newValue: pushups, csvEstimate: false)
            }
            maxValuesEntered = true
        }
        
        if let squats = Double(squatReps) {
            if let squat = exerciseData.exercise(named: "Bodyweight Squat") {
                // "7A4E8270-424C-432F-9459-C9E2065773F4"
                exerciseData.updateExercisePerformance(for: squat, newValue: squats, csvEstimate: false)
            }
            maxValuesEntered = true
        }
        
        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.setup.maxRepsEntered = true
            userData.saveSingleStructToFile(\.setup, for: .setup)
            onFinish()
        }
    }
    
    private func InputSection(label: String, value: Binding<String>) -> some View {
        InputField(text: value, label: label, placeholder: "Enter Reps")
    }
}

