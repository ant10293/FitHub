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
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        // Initialize with existing user data if available
        let weight =  userData.currentMeasurementValue(for: .weight).actualValue
        _weight = State(initialValue: Mass(kg: weight))
        _height = State(initialValue: userData.physical.height)
    }
    
    var body: some View {
        Form {
            Section {
                WeightSelectorRow(weight: $weight)
            } header: {
                Text("Enter your Weight")
            }
            
            Section {
                HeightSelectorRow(height: $height)
            } header: {
                Text("Enter your Height")
            }
            
            Section {
                // No rows in this section—just a footer
                EmptyView()
            } footer: {
                if !kbd.isVisible {
                    RectangularButton(
                        title: "Calculate BMI",
                        enabled: isCalculateEnabled,
                        action: {
                            calculateAndUpdateBMI()
                            showingResult = true
                        }
                    )
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
            }
        }
        .disabled(showingResult)
        .blur(radius: showingResult ? 10 : 0)
        .background(Color(UIColor.systemGroupedBackground)) // make button background color match list
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .overlay(
            Group {
                if showingResult {
                    BMIResultView(bmi: bmi) {
                        showingResult = false
                        dismiss()
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
    
    struct BMIResultView: View {
        @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
        let bmi: Double
        var dismissAction: () -> Void
        
        var body: some View {
            VStack(spacing: 10) {
                Text("Your BMI").font(.headline).padding(.top)
                Text(String(format: "%.2f", bmi)).font(.title)
                
                BMICategoryTable(userBMI: bmi)
                    .frame(height: UIScreen.main.bounds.height * 0.1)

                RectangularButton(title: "Done", action: { dismissAction() })
                    .padding(.vertical)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4)
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
    }
}
