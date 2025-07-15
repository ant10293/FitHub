//
//  EnterOneRepMaxes.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EnterOneRepMaxes: View {
    @ObservedObject var userData: UserData
    @ObservedObject var exerciseData: ExerciseData
    @StateObject private var kbd = KeyboardManager.shared
    @State private var benchPressMax: String = ""
    @State private var squatMax: String = ""
    @State private var deadliftMax: String = ""
    @State private var numberReps: Int = 1 // Defaulting to 1 to ensure the Text reflects initial selection correctly
    let repOptions: [Int] = Array(1...8).filter { $0 % 1 == 0 }
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea(.all)
                .zIndex(0)
            
            VStack {
                VStack(spacing: 5) {
                    Text("Don't know your 1 rep max?")
                        .font(.headline)
                    Text("Enter your 2-8 rep max for atleast one \n of the exercises below.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .centerHorizontally()
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                HStack(alignment: .center) {
                    Text("Number Of Reps")
                        .bold()
                    Picker("", selection: $numberReps) {
                        ForEach(repOptions, id: \.self) {
                            Text("\($0)")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                
                VStack(spacing: 15) {
                    InputSection(label: "Bench Press", value: $benchPressMax)
                    InputSection(label: "Squat", value: $squatMax)
                    InputSection(label: "Deadlift", value: $deadliftMax)
                }
                
                Spacer()
                
                if !kbd.isVisible {
                    ActionButton(title: "Submit", enabled: submitEnabled, color: submitEnabled ? .green : .gray, action: handleSubmit)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationBarTitle("Enter your \(numberReps) Rep Max", displayMode: .large)
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }
    
    private var submitEnabled: Bool { !benchPressMax.isEmpty && !squatMax.isEmpty && !deadliftMax.isEmpty }
    
    private func handleSubmit() {
        let recommendedFormula = OneRMFormula.recommendedFormula(forReps: numberReps)
        var maxValuesEntered = false
        
        if let benchMax = Double(benchPressMax) {
            let estimatedBench = OneRMFormula.calculateOneRepMax(weight: benchMax, reps: numberReps, formula: recommendedFormula)
            if let bench = exerciseData.exercise(named: "Bench Press") {
                // "8DCDCCF6-F83E-4445-BF63-8EF67CA91240"
                exerciseData.updateExercisePerformance(for: bench, newValue: estimatedBench, reps: numberReps, weight: benchMax, csvEstimate: false)
            }
            maxValuesEntered = true
        }
        
        if let squatMax = Double(squatMax) {
            let estimatedSquat = OneRMFormula.calculateOneRepMax(weight: squatMax, reps: numberReps, formula: recommendedFormula)
            if let squat = exerciseData.exercise(named: "Back Squat") {
                // "F4E51C55-059D-4B60-902B-B9D31C894813"
                exerciseData.updateExercisePerformance(for: squat, newValue: estimatedSquat, reps: numberReps, weight: squatMax, csvEstimate: false)
            }
            maxValuesEntered = true
        }
        
        if let deadMax = Double(deadliftMax) {
            let estimatedDeadlift = OneRMFormula.calculateOneRepMax(weight: deadMax, reps: numberReps, formula: recommendedFormula)
            if let deadlift = exerciseData.exercise(named: "Deadlift") {
                // "B61A4A76-D761-4A08-8C66-25AB3662AC35"
                exerciseData.updateExercisePerformance(for: deadlift, newValue: estimatedDeadlift, reps: numberReps, weight: deadMax, csvEstimate: false)
            }
            maxValuesEntered = true
        }
        
        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.setup.oneRepMaxesEntered = true
            userData.saveSingleStructToFile(\.setup, for: .setup)
            onFinish()
        }
    }
    
    private func InputSection(label: String, value: Binding<String>) -> some View {
        InputField(text: value, label: label, placeholder: "Enter Weight (lbs)")
    }
}
