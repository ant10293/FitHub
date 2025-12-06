//
//  BMICalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct BMICalculator: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @StateObject private var kbd = KeyboardManager.shared
    @State private var weight: Mass
    @State private var height: Length
    @State private var bmi: Double = 0.0
    @State private var showingResult: Bool = false
    @State private var isButtonPressed: Bool = false
    @State private var activeCard: ActiveCard = .none
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        // Initialize with existing user data if available
        let weight =  userData.currentMeasurementValue(for: .weight).actualValue
        _weight = State(initialValue: Mass(kg: weight))
        _height = State(initialValue: userData.physical.height)
    }
    
    var body: some View {
        let height = screenHeight * 0.1

        VStack {
            ScrollView {
                weightCard
                    .padding(.top)
                heightCard
                
                
                if !kbd.isVisible {
                    Spacer(minLength: height)

                    RectangularButton(
                        title: "Calculate BMI",
                        enabled: isCalculateEnabled,
                        action: {
                            calculateAndUpdateBMI()
                            showingResult = true
                        }
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
        .overlay(
            Group {
                if showingResult {
                    CalcResultView(title: "Your BMI", singleResult: String(format: "%.2f", bmi), dismissAction: {
                        showingResult = false
                        dismiss()
                    }) {
                            BMICategoryTable(userBMI: bmi)
                                .padding(.bottom)
                                .frame(height: height)
                    }
                }
            }
        )
        .navigationBarTitle("BMI Calculator", displayMode: .inline)
    }
    
    private var isCalculateEnabled: Bool { return weight.inKg > 0 && height.inCm > 0 }

    private func calculateAndUpdateBMI() {
        bmi = BMI.calculateBMI(heightCm: height.inCm, weightKg: weight.inKg)
        
        userData.updateMeasurementValue(for: .bmi, with: bmi)
        userData.updateMeasurementValue(for: .weight, with: weight.inKg)

        userData.physical.height = height
    }
    
    // MARK: - Cards
    
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
        case none, weight, height
    }
}
