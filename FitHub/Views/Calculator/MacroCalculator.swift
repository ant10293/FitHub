//
//  MacroCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct MacroCalculator: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @StateObject private var kbd = KeyboardManager.shared

    // Inputs
    @State private var weight: Mass
    @State private var height: Length
    @State private var ageText: String
    @State private var activityLevel: ActivityLevel

    // Outputs
    @State private var baseCalories: Double = 0
    @State private var macroResult: MacroResult?
    @State private var showingResult = false

    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)

        let storedWeightKg = userData.currentMeasurementValue(for: .weight).actualValue
        _weight        = State(initialValue: Mass(kg: storedWeightKg))
        _height        = State(initialValue: userData.physical.height)
        _ageText       = State(initialValue: userData.profile.age > 0 ? "\(userData.profile.age)" : "")
        _activityLevel = State(initialValue: userData.physical.activityLevel)
    }

    var body: some View {
        Form {
            // Age
            Section {
                TextField("Age", text: $ageText)
                    .keyboardType(.numberPad)
            } header: {
                Text("Enter your Age")
            }

            // Weight
            Section {
                WeightSelectorRow(weight: $weight)
            } header: {
                Text("Enter your Weight")
            }

            // Height
            Section {
                HeightSelectorRow(height: $height)
            } header: {
                Text("Enter your Height")
            }

            // Activity level
            Section {
                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                if activityLevel != .select {
                    Text(activityLevel.description)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            } header: {
                Text("Select your Activity Level")
            }

            // Calculate
            Section {
                EmptyView()
            } footer: {
                if !kbd.isVisible {
                    RectangularButton(
                        title: "Calculate Macros",
                        enabled: isCalculateEnabled,
                        action: calculate
                    )
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
            }
        }
        .disabled(showingResult)
        .blur(radius: showingResult ? 10 : 0)
        .background(Color(UIColor.systemGroupedBackground))
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Macro Calculator", displayMode: .inline)
        .overlay {
            if showingResult, let r = macroResult {
                MacroResultView(result: r) {
                    persistInputs()
                    showingResult = false
                    dismiss()
                }
                .padding()
            }
        }
    }

    // MARK: - Derived

    private var isCalculateEnabled: Bool {
        guard let age = Int(ageText), age > 0 else { return false }
        return weight.inKg > 0 && height.inCm > 0 && activityLevel != .select
    }

    // MARK: - Actions

    private func calculate() {
        guard let age = Int(ageText) else { return }

        // Base BMR
        let bmr = BMR.calculateBMR(
            gender: userData.physical.gender,
            weightKg: weight.inKg,
            heightCm: height.inCm,
            age: Double(age)
        )
        
        // Multiply by activity level
        let maintenance = bmr * activityLevel.multiplier
        /*
        let goal: FitnessGoal = userData.physical.goal
        
        // Adjust by goal
        let adjustedCalories: Double = maintenance * goal.maintenanceMultiplierDefault
        */
        // Macros
        let carbs    = (maintenance * 0.50) / 4.0
        let proteins = (maintenance * 0.30) / 4.0
        let fats     = (maintenance * 0.20) / 9.0

        macroResult = MacroResult(
            totalCalories: maintenance,
            carbs: carbs,
            proteins: proteins,
            fats: fats
        )
        showingResult = true
    }

    private func persistInputs() {
        // Persist age / activity
        userData.profile.age = Int(ageText) ?? 0
        userData.physical.activityLevel = activityLevel

        // Persist weight/height (always metric in storage)
        let kg = round(weight.inKg * 100) / 100
        userData.updateMeasurementValue(for: .weight, with: kg)
        userData.physical.height = height

        // Persist macros & calories
        if let r = macroResult {
            userData.physical.carbs    = r.carbs
            userData.physical.proteins = r.proteins
            userData.physical.fats     = r.fats
            userData.updateMeasurementValue(for: .caloricIntake, with: r.totalCalories)
        }
    }

    // MARK: - View Models

    struct MacroResult {
        let totalCalories: Double
        let carbs: Double
        let proteins: Double
        let fats: Double
    }

    struct MacroResultView: View {
        @Environment(\.colorScheme) var colorScheme
        let result: MacroResult
        var dismissAction: () -> Void

        var body: some View {
            VStack(spacing: 8) {
                Text("Your Macros").font(.headline)

                Group {
                    Text("Calories: \(Int(round(result.totalCalories)))") + Text(" kcal").fontWeight(.light)
                    Text("Carbohydrates: \(Int(round(result.carbs)))") + Text(" g").fontWeight(.light)
                    Text("Proteins: \(Int(round(result.proteins)))") + Text(" g").fontWeight(.light)
                    Text("Fats: \(Int(round(result.fats)))") + Text(" g").fontWeight(.light)
                }

                RingView(dailyCaloricIntake: result.totalCalories,
                         carbs: result.carbs,
                         fats: result.fats,
                         proteins: result.proteins)
                    .padding(.vertical)

                RectangularButton(title: "Close", action: dismissAction)
            }
            .padding()
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
    }
}
