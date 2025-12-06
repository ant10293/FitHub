//
//  KcalCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct KcalCalculator: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @StateObject private var kbd = KeyboardManager.shared

    // Inputs
    @State private var weight: Mass
    @State private var height: Length
    @State private var ageText: String
    @State private var stepsText: String

    // UI
    @State private var showingResult = false
    @State private var resultCalories: Double?
    @State private var activeCard: ActiveCard = .none

    // MARK: - Init
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)

        let storedWeightKg = userData.currentMeasurementValue(for: .weight).actualValue

        _weight    = State(initialValue: Mass(kg: storedWeightKg))
        _height    = State(initialValue: userData.physical.height)
        _ageText   = State(initialValue: userData.profile.age > 0 ? "\(userData.profile.age)" : "")
        _stepsText = State(initialValue: userData.physical.avgSteps > 0 ? "\(userData.physical.avgSteps)" : "")
    }

    var body: some View {
        let height = screenHeight * 0.1

        VStack {
            ScrollView {
                ageCard
                    .padding(.top)
                weightCard
                heightCard
                stepsCard
                
                
                if !kbd.isVisible {
                    Spacer(minLength: height)
                    
                    RectangularButton(
                        title: "Calculate Daily Caloric Intake",
                        enabled: isCalculateEnabled,
                        action: calculateAndShow
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
        .navigationBarTitle("Daily Kcal Calculator", displayMode: .inline)
        .overlay {
            if showingResult, let calories = resultCalories {
                CalcResultView(title: "Daily Caloric Intake", singleResult: "\(Int(calories)) Calories", dismissAction: {
                    persistInputs()
                    showingResult = false
                    dismiss()
                }) 
            }
        }
    }

    // MARK: - Derived

    private var isCalculateEnabled: Bool {
        guard let age = Int(ageText), age > 0, let steps = Int(stepsText), steps >= 0
        else { return false }

        return weight.inKg > 0 && height.inCm > 0 && steps >= 0
    }

    // MARK: - Actions

    private func calculateAndShow() {
        guard let age   = Int(ageText), let steps = Int(stepsText)
        else { return }

        let bmr = BMR.calculateBMR(
            gender: userData.physical.gender,
            weightKg: weight.inKg,
            heightCm: height.inCm,
            age: Double(age)
        )

        // Your original rule: +100 kcal per 1,000 steps
        let total = bmr + (Double(steps) * 0.1)
        resultCalories = round(total)
        userData.updateMeasurementValue(for: .caloricIntake, with: resultCalories ?? 0)
        showingResult = true
    }

    private func persistInputs() {
        // Weight (kg always)
        let roundedKg = round(weight.inKg * 100) / 100
        userData.updateMeasurementValue(for: .weight, with: roundedKg)

        // Height (cm int)
        userData.physical.height = height

        // Steps / Age
        userData.physical.avgSteps = Int(stepsText) ?? 0
        userData.profile.age       = Int(ageText) ?? 0
    }

    // MARK: - Cards

    private var ageCard: some View {
        MeasurementCard(
            title: "Age",
            isActive: activeCard == .age,
            onTap: { toggle(.age) },
            onClose: closePicker,
            valueView: {
                Text(ageText.isEmpty ? "—" : "\(ageText) yrs")
            },
            content: {
                TextField("Age in years", text: $ageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
        )
    }

    private var weightCard: some View {
        MeasurementCard(
            title: "Weight",
            isActive: activeCard == .weight,
            onTap: { toggle(.weight) },
            onClose: closePicker,
            valueView: {
                Text(summary(for: weight, unit: UnitSystem.current.weightUnit))
            },
            content: {
                WeightSelectorRow(weight: $weight)
            }
        )
    }

    private var heightCard: some View {
        MeasurementCard(
            title: "Height",
            isActive: activeCard == .height,
            onTap: { toggle(.height) },
            onClose: closePicker,
            valueView: {
                height.heightFormatted.foregroundStyle(.gray)
            },
            content: {
                HeightSelectorRow(height: $height)
            }
        )
    }

    private var stepsCard: some View {
        MeasurementCard(
            title: "Average Daily Steps",
            isActive: activeCard == .steps,
            onTap: { toggle(.steps) },
            onClose: closePicker,
            valueView: {
                Text(stepsText.isEmpty ? "—" : stepsText)
            },
            content: {
                TextField("Avg Steps per Day", text: $stepsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
        )
    }

    // MARK: - Helpers

    private func summary(for mass: Mass, unit: String) -> String {
        let value = mass.displayString
        return value.isEmpty ? "—" : "\(value) \(unit)"
    }

    private func toggle(_ card: ActiveCard) {
        activeCard = activeCard == card ? .none : card
    }

    private func closePicker() {
        kbd.dismiss()
        activeCard = .none
    }

    private enum ActiveCard {
        case none, age, weight, height, steps
    }
}
