//
//  BMICalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct BMICalculator: View {
    @ObservedObject var userData: UserData
    @StateObject private var kbd = KeyboardManager.shared
    @State private var weight: String
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var roundedBMI: Double = 0.0
    @State private var showingResult: Bool = false
    @State private var isButtonPressed: Bool = false
    
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        // Initialize with existing user data if available
        _weight = State(initialValue: String(Format.smartFormat(userData.currentMeasurementValue(for: .weight))))
        _heightFeet = State(initialValue: userData.physical.heightFeet)
        _heightInches = State(initialValue: userData.physical.heightInches)
    }
    
    var body: some View {
        Form {
            Section {
                HStack{
                    TextField("Weight in pounds (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                }
            } header: {
                Text("Enter your Weight")
            }
            
            Section {
                HeightPicker(feet: $heightFeet, inches: $heightInches)
            } header: {
                Text("Enter your Height")
            }
            
            Section {
                // No rows in this section—just a footer
                EmptyView()
            } footer: {
                if !kbd.isVisible {
                    ActionButton(
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
                    BMIResultView(bmi: roundedBMI) {
                        self.showingResult = false
                        
                        let currentWeight = userData.currentMeasurementValue(for: .weight).rounded()
                        let newWeight = Double(weight)?.rounded()
                        
                        if currentWeight != newWeight {
                            userData.updateMeasurementValue(for: .weight, with: Double(weight) ?? currentWeight, shouldSave: true)
                        }
                    }
                }
            }
        )
        .navigationBarTitle("BMI Calculator", displayMode: .inline)
    }
    
    private var isCalculateEnabled: Bool {
        // Check if weight and height values have been entered
        return !weight.isEmpty && (heightFeet > 0 || heightInches > 0)
    }

    private func calculateAndUpdateBMI() {
        var bmi: Double = 0
        if let weightAsDouble = Double(weight) {
            bmi = BMI.calculateBMI(heightInches: heightInches, heightFeet: heightFeet, weight: weightAsDouble)
        } 
        roundedBMI = round(bmi * 100) / 100.0
        
        // Retrieve the current BMI from userData for comparison
        let currentBMI = userData.currentMeasurementValue(for: .bmi)
        
        // Update only if the BMI has changed
        if currentBMI != roundedBMI {
            userData.updateMeasurementValue(for: .bmi, with: roundedBMI, shouldSave: true)
        }
        userData.physical.heightFeet = heightFeet
        userData.physical.heightInches = heightInches
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

                ActionButton(title: "Done", action: { dismissAction() })
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


