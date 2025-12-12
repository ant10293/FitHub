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
    @State private var benchPressMax: Mass = .init(kg: 0)
    @State private var squatMax: Mass      = .init(kg: 0)
    @State private var deadliftMax: Mass   = .init(kg: 0)
    @State private var numberReps: Int = 1
    let repOptions: [Int] = Array(1...8)
    var bench: Exercise? = nil
    var squat: Exercise? = nil
    var deadlift: Exercise? = nil
    let onFinish: () -> Void

    init(
        userData: UserData,
        exerciseData: ExerciseData,
        onFinish: @escaping () -> Void
    ) {
        self.userData = userData
        self.exerciseData = exerciseData
        self.onFinish = onFinish

        if let bench = exerciseData.exercise(named: "Bench Press") { self.bench = .init(bench) }
        if let squat = exerciseData.exercise(named: "Back Squat") { self.squat = .init(squat) }
        if let deadlift = exerciseData.exercise(named: "Deadlift") { self.deadlift = .init(deadlift) }

        if let bench = self.bench, let peak = exerciseData.peakMetric(for: bench.id),
           case .oneRepMax(let mass) = peak {
            _benchPressMax = .init(initialValue: mass)
        }

        if let squat = self.squat, let peak = exerciseData.peakMetric(for: squat.id),
           case .oneRepMax(let mass) = peak {
            _squatMax = .init(initialValue: mass)
        }

        if let deadlift = self.deadlift, let peak = exerciseData.peakMetric(for: deadlift.id),
           case .oneRepMax(let mass) = peak {
            _deadliftMax = .init(initialValue: mass)
        }
    }

    var body: some View {
        AssessmentFormView(
            title: "Enter \(numberReps) Rep Maxes",
            headline: "Don't know your 1 rep max?",
            subheadline: "Enter your 2–8 rep max for at least one of the exercises below.",
            inputFields: [
                AssessmentInputField(label: "Bench Press", text: $benchPressMax.asText(), placeholder: "Enter Weight (\(UnitSystem.current.weightUnit))"),
                AssessmentInputField(label: "Squat", text: $squatMax.asText(), placeholder: "Enter Weight (\(UnitSystem.current.weightUnit))"),
                AssessmentInputField(label: "Deadlift", text: $deadliftMax.asText(), placeholder: "Enter Weight (\(UnitSystem.current.weightUnit))")
            ],
            submitEnabled: submitEnabled,
            onSubmit: handleSubmit,
            additionalContent: {
                repPicker
            }
        )
    }

    private var repPicker: some View {
        HStack {
            Text("Number Of Reps").bold()
            Picker("", selection: $numberReps) {
                ForEach(repOptions, id: \.self) {
                    Text("\($0)")
                }
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

        if benchPressMax.inKg > 0, let bench = bench {
            let est = OneRMFormula.calculateOneRepMax(weight: benchPressMax, reps: numberReps, formula: formula)
            let loadXmetric = numberReps > 1 ? LoadXMetric(load: .weight(benchPressMax), metric: metric) : nil
            exerciseData.updateExercisePerformance(
                for: bench,
                newValue: .oneRepMax(est),
                loadXmetric: loadXmetric
            )
            maxValuesEntered = true
        }

        if squatMax.inKg > 0, let squat = squat {
            let est = OneRMFormula.calculateOneRepMax(weight: squatMax, reps: numberReps, formula: formula)
            let loadXmetric = numberReps > 1 ? LoadXMetric(load: .weight(squatMax), metric: metric) : nil
            exerciseData.updateExercisePerformance(
                for: squat,
                newValue: .oneRepMax(est),
                loadXmetric: loadXmetric
            )
            maxValuesEntered = true
        }

        if deadliftMax.inKg > 0, let deadlift = deadlift {
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

}
