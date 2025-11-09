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
    @State private var macroResult: MacroResult?
    @State private var showingResult = false
    @State private var activeCard: ActiveCard = .none

    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)

        let storedWeightKg = userData.currentMeasurementValue(for: .weight).actualValue
        _weight        = State(initialValue: Mass(kg: storedWeightKg))
        _height        = State(initialValue: userData.physical.height)
        _ageText       = State(initialValue: userData.profile.age > 0 ? "\(userData.profile.age)" : "")
        _activityLevel = State(initialValue: userData.physical.activityLevel)
    }

    var body: some View {
        let height = UIScreen.main.bounds.height * 0.1

        VStack {
            ScrollView {
                ageCard
                    .padding(.top)
                weightCard
                heightCard
                activityCard
                
                
                if !kbd.isVisible {
                    Spacer(minLength: height)

                    RectangularButton(
                        title: "Calculate Macros",
                        enabled: isCalculateEnabled,
                        action: calculate
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: height)
                }
            }
        }
        .disabled(showingResult)
        .blur(radius: showingResult ? 10 : 0)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Macro Calculator", displayMode: .inline)
        .overlay {
            if showingResult, let r = macroResult {
                MacroResultView(result: r) {
                    persistInputs()
                    showingResult = false
                    dismiss()
                }
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

    // MARK: - Card Builders

    private var ageCard: some View {
        MeasurementCard(
            title: "Age",
            isActive: activeCard == .age,
            onTap: { toggle(.age) },
            valueView: {
                Text(ageText.isEmpty ? "—" : "\(ageText) yrs")
            },
            content: {
                TextField("Age", text: $ageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top)

                floatingDoneButton
            }
        )
    }

    private var weightCard: some View {
        MeasurementCard(
            title: "Weight",
            isActive: activeCard == .weight,
            onTap: { toggle(.weight) },
            valueView: {
                Text(summary(for: weight, unit: UnitSystem.current.weightUnit))
            },
            content: {
                WeightSelectorRow(weight: $weight)
                    .padding(.top)

                floatingDoneButton
                    .padding(.top, 6)
            }
        )
    }

    private var heightCard: some View {
        MeasurementCard(
            title: "Height",
            isActive: activeCard == .height,
            onTap: { toggle(.height) },
            valueView: {
                height.heightFormatted.foregroundStyle(.gray)
            },
            content: {
                HeightSelectorRow(height: $height)
                    .padding(.top)

                floatingDoneButton
                    .padding(.top, 6)
            }
        )
    }

    private var activityCard: some View {
        MeasurementCard(
            title: "Activity Level",
            isActive: activeCard == .activity,
            onTap: { toggle(.activity) },
            valueView: {
                Text(activityLevel == .select ? "Select" : activityLevel.rawValue)
            },
            content: {
                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .padding(.top)

                if activityLevel != .select {
                    Text(activityLevel.description)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.top, 4)
                }

                floatingDoneButton
            }
        )
    }

    private func summary(for mass: Mass, unit: String) -> String {
        let value = mass.displayString
        return value.isEmpty ? "—" : "\(value) \(unit)"
    }

    private func toggle(_ card: ActiveCard) {
        activeCard = activeCard == card ? .none : card
    }

    private var floatingDoneButton: some View {
        HStack {
            Spacer()
            FloatingButton(image: "checkmark") {
                kbd.dismiss()
                activeCard = .none
            }
            .padding(.horizontal)
        }
    }

    private enum ActiveCard {
        case none, age, weight, height, activity
    }

    // MARK: - View Models

    struct MacroResult {
        let totalCalories: Double
        let carbs: Double
        let proteins: Double
        let fats: Double
    }

    struct MacroResultView: View {
        let result: MacroResult
        var dismissAction: () -> Void

        var body: some View {
            CalcResultView(title: "Your Macros", dismissAction: dismissAction, content: {
                customText(for: "Calories", value: result.totalCalories, unit: "kcal")
                customText(for: "Carbohydrates", value: result.carbs, unit: "g")
                customText(for: "Proteins", value: result.proteins, unit: "g")
                customText(for: "Fats", value: result.fats, unit: "g")

                RingView(dailyCaloricIntake: result.totalCalories,
                         carbs: result.carbs,
                         fats: result.fats,
                         proteins: result.proteins)
                .padding(.vertical)
            })
        }
        
        private func customText(for label: String, value: Double, unit: String) -> Text {
            Text("\(label): \(Int(round(value)))") + Text(" \(unit)").fontWeight(.light)
        }
    }
}
