//
//  KcalCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//
import SwiftUI

struct KcalCalculator: View {
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
        Form {
            // Age
            Section {
                TextField("Age in years", text: digitsBinding($ageText))
                    .keyboardType(.numberPad)
            } header: {
                Text("Enter Age")
            }

            // Weight
            Section {
                WeightSelectorRow(weight: $weight)
            } header: {
                Text("Enter Weight")
            }

            // Height
            Section {
                HeightSelectorRow(height: $height)
            } header: {
                Text("Enter your Height")
            }

            // Steps
            Section {
                TextField("Avg Steps per Day", text: digitsBinding($stepsText))
                    .keyboardType(.numberPad)
            } header: {
                Text("Enter Steps per Day")
            }

            // Calculate
            Section {
                EmptyView()
            } footer: {
                if !kbd.isVisible {
                    RectangularButton(
                        title: "Calculate Daily Caloric Intake",
                        enabled: isCalculateEnabled,
                        action: calculateAndShow
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
        .navigationBarTitle("Daily Caloric Intake Calculator", displayMode: .inline)
        .overlay {
            if showingResult, let calories = resultCalories {
                ResultView(calories: calories) {
                    persistInputs()
                    showingResult = false
                }
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
        userData.updateMeasurementValue(for: .caloricIntake, with: resultCalories ?? 0, shouldSave: false)
        showingResult = true
    }

    private func persistInputs() {
        // Weight (kg always)
        let roundedKg = round(weight.inKg * 100) / 100
        userData.updateMeasurementValue(for: .weight, with: roundedKg, shouldSave: false)

        // Height (cm int)
        userData.physical.height = height

        // Steps / Age
        userData.physical.avgSteps = Int(stepsText) ?? 0
        userData.profile.age       = Int(ageText) ?? 0

        userData.saveToFile()
    }

    // MARK: - Bindings

    /// Wraps a `String` state into a digits-only binding.
    private func digitsBinding(_ src: Binding<String>) -> Binding<String> {
        Binding(
            get: { src.wrappedValue },
            set: { new in
                src.wrappedValue = new.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
            }
        )
    }

    // MARK: - Result view

    struct ResultView: View {
        @Environment(\.colorScheme) var colorScheme
        let calories: Double
        var dismissAction: () -> Void

        var body: some View {
            VStack {
                Text("Daily Caloric Intake").font(.headline)
                Text("\(Int(calories)) Calories").font(.title2)

                RectangularButton(title: "Done", action: dismissAction)
                    .padding(.horizontal)
            }
            .frame(width: UIScreen.main.bounds.width * 0.8,
                   height: UIScreen.main.bounds.height * 0.25)
            .background(colorScheme == .dark
                        ? Color(UIColor.secondarySystemBackground)
                        : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
    }
}



