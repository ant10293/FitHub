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
    @State private var benchPressMax: Mass = .init(kg: 0)
    @State private var squatMax: Mass      = .init(kg: 0)
    @State private var deadliftMax: Mass   = .init(kg: 0)
    @State private var numberReps: Int = 1
    // Usually 2–8 for submax estimation (tweak as you like)
    let repOptions: [Int] = Array(1...8)
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()

            VStack {
                Text("Enter \(numberReps) Rep Maxes")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                header

                repPicker

                VStack(spacing: 15) {
                    InputSection(label: "Bench Press", mass: $benchPressMax)
                    InputSection(label: "Squat",        mass: $squatMax)
                    InputSection(label: "Deadlift",     mass: $deadliftMax)
                }

                Spacer()

                if !kbd.isVisible {
                    RectangularButton(
                        title: "Submit",
                        enabled: submitEnabled,
                        bgColor: submitEnabled ? .green : .gray,
                        action: handleSubmit
                    )
                    .padding()
                }

                Spacer()
            }
        }
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
        let metric: SetMetric = .reps(numberReps)
        var maxValuesEntered = false

        if benchPressMax.inKg > 0,
           let bench = exerciseData.exercise(named: "Bench Press") {
            let est = OneRMFormula.calculateOneRepMax(weight: benchPressMax, reps: numberReps, formula: formula)
            let loadXmetric = numberReps > 1 ? LoadXMetric(load: .weight(benchPressMax), metric: metric) : nil
            exerciseData.updateExercisePerformance(
                for: bench,
                newValue: .oneRepMax(est),
                loadXmetric: loadXmetric
            )
            maxValuesEntered = true
        }

        if squatMax.inKg > 0,
           let squat = exerciseData.exercise(named: "Back Squat") {
            let est = OneRMFormula.calculateOneRepMax(weight: squatMax, reps: numberReps, formula: formula)
            let loadXmetric = numberReps > 1 ? LoadXMetric(load: .weight(squatMax), metric: metric) : nil
            exerciseData.updateExercisePerformance(
                for: squat,
                newValue: .oneRepMax(est),
                loadXmetric: loadXmetric
            )
            maxValuesEntered = true
        }

        if deadliftMax.inKg > 0,
           let deadlift = exerciseData.exercise(named: "Deadlift") {
            let est = OneRMFormula.calculateOneRepMax(weight: deadliftMax, reps: numberReps, formula: formula)
            let loadXmetric = numberReps > 1 ? LoadXMetric(load: .weight(deadliftMax), metric: metric) : nil
            exerciseData.updateExercisePerformance(
                for: deadlift,
                newValue: .oneRepMax(est),
                loadXmetric: loadXmetric
            )
            maxValuesEntered = true
        }

        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.setup.oneRepMaxesEntered = true
            onFinish()
        }
    }

    private func InputSection(label: String, mass: Binding<Mass>) -> some View {
        InputField(text: mass.asText(), label: label, placeholder: "Enter Weight (\(UnitSystem.current.weightUnit))")
    }
}

