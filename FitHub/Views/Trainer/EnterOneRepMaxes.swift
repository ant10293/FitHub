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

    // Use Mass instead of String
    @State private var benchPressMax: Mass = .init(kg: 0)
    @State private var squatMax: Mass      = .init(kg: 0)
    @State private var deadliftMax: Mass   = .init(kg: 0)

    @State private var numberReps: Int = 1
    // Usually 2–8 for submax estimation (tweak as you like)
    let repOptions: [Int] = Array(1...8)

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()

            VStack {
                header

                repPicker

                VStack(spacing: 15) {
                    InputSection(label: "Bench Press", mass: $benchPressMax)
                    InputSection(label: "Squat",        mass: $squatMax)
                    InputSection(label: "Deadlift",     mass: $deadliftMax)
                }

                Spacer()

                if !kbd.isVisible {
                    ActionButton(
                        title: "Submit",
                        enabled: submitEnabled,
                        color: submitEnabled ? .green : .gray,
                        action: handleSubmit
                    )
                    .padding()
                }

                Spacer()
            }
        }
        .navigationBarTitle("Enter your \(numberReps) Rep Max", displayMode: .large)
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }

    private var header: some View {
        VStack(spacing: 5) {
            Text("Don't know your 1 rep max?")
                .font(.headline)
            Text("Enter your 2–8 rep max for at least one\nof the exercises below.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var repPicker: some View {
        HStack {
            Text("Number Of Reps").bold()
            Picker("", selection: $numberReps) {
                ForEach(repOptions, id: \.self) { Text("\($0)") }
            }
            .pickerStyle(.segmented)
        }
        .padding()
    }

    private var submitEnabled: Bool {
        benchPressMax.inKg > 0 || squatMax.inKg > 0 || deadliftMax.inKg > 0
    }

    private func handleSubmit() {
        let formula: OneRMFormula = .brzycki //OneRMFormula.recommendedFormula(forReps: numberReps)
        var maxValuesEntered = false

        if benchPressMax.inKg > 0,
           let bench = exerciseData.exercise(named: "Bench Press") {
            let est = OneRMFormula.calculateOneRepMax(weight: benchPressMax, reps: numberReps, formula: formula)
            let repsXweight = numberReps > 1 ? RepsXWeight(reps: numberReps, weight: benchPressMax) : nil
            exerciseData.updateExercisePerformance(for: bench, newValue: .oneRepMax(est), repsXweight: repsXweight)
            maxValuesEntered = true
        }

        if squatMax.inKg > 0,
           let squat = exerciseData.exercise(named: "Back Squat") {
            let est = OneRMFormula.calculateOneRepMax(weight: squatMax, reps: numberReps, formula: formula)
            let repsXweight = numberReps > 1 ? RepsXWeight(reps: numberReps, weight: squatMax) : nil
            exerciseData.updateExercisePerformance(for: squat, newValue: .oneRepMax(est), repsXweight: repsXweight)
            maxValuesEntered = true
        }

        if deadliftMax.inKg > 0,
           let deadlift = exerciseData.exercise(named: "Deadlift") {
            let est = OneRMFormula.calculateOneRepMax(weight: deadliftMax, reps: numberReps, formula: formula)
            let repsXweight = numberReps > 1 ? RepsXWeight(reps: numberReps, weight: deadliftMax) : nil
            exerciseData.updateExercisePerformance(for: deadlift, newValue: .oneRepMax(est), repsXweight: repsXweight)
            maxValuesEntered = true
        }

        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.setup.oneRepMaxesEntered = true
            userData.saveSingleStructToFile(\.setup, for: .setup)
            onFinish()
        }
    }

    // MARK: - Small subview

    private func InputSection(label: String, mass: Binding<Mass>) -> some View {
        InputField(text: mass.asText(), label: label, placeholder: "Enter Weight")
    }
}

