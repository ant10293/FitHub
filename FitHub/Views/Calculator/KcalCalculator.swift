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
    @State private var showingResult: Bool = false
    @State private var weight: String
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var avgSteps: String = ""
    @State private var age: String
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        // Initialize with existing user data if available
        _weight = State(initialValue: String(Format.smartFormat(userData.currentMeasurementValue(for: .weight))))
        _avgSteps = State(initialValue: userData.physical.avgSteps == 0 ? "" : String(userData.physical.avgSteps))
        _heightFeet = State(initialValue: userData.physical.heightFeet)
        _heightInches = State(initialValue: userData.physical.heightInches)
        _age = State(initialValue: String(userData.profile.age))
    }
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        Form {
            Section {
                TextField("Age in years", text: $age)
                    .keyboardType(.numberPad)
                
                TextField("Weight in pounds (lbs)", text: $weight)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Enter Age and Weight")
            }
            
            Section {
                HeightPicker(feet: $heightFeet, inches: $heightInches)
            } header: {
                Text("Enter your Height")
            }
            
            Section {
                TextField("Avg Steps per Day", text: stepsBinding)
                    .keyboardType(.numberPad)
            } header: {
                Text("Enter Steps per Day")
            }
            
            Section {
                EmptyView()
            } footer: {
                if !kbd.isVisible {
                    ActionButton(
                        title: "Calculate Daily Caloric Intake",
                        enabled: isCalculateEnabled,
                        action: {
                            calculateDailyCaloricIntake()
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
                    ResultView(calories: userData.currentMeasurementValue(for: .caloricIntake)) {
                        self.showingResult = false
                        
                        let currentWeight = userData.currentMeasurementValue(for: .weight).rounded()
                        let newWeight = Double(weight)?.rounded()
                        
                        if currentWeight != newWeight {
                            userData.updateMeasurementValue(for: .weight, with: Double(weight) ?? currentWeight, shouldSave: false)
                        }
                        userData.physical.heightFeet = heightFeet
                        userData.physical.heightInches = heightInches
                        userData.physical.avgSteps = Int(avgSteps) ?? 0
                        userData.profile.age = Int(age) ?? 0
                        
                        userData.saveToFile()
                    }
                }
            }
        )
        .navigationBarTitle("Daily Caloric Intake Calculator", displayMode: .inline)
    }
    
    private var isCalculateEnabled: Bool {
        // Check if all fields have valid values
        return !weight.isEmpty && (heightFeet > 0 || heightInches > 0) && !avgSteps.isEmpty && !age.isEmpty
    }
    
    private var stepsBinding: Binding<String> {
        Binding<String>(
            get: {
                // Return an empty string if steps is 0
                let number = Double(self.avgSteps) ?? 0
                return number == 0 ? "" : self.numberFormatter.string(from: NSNumber(value: number)) ?? ""
            },
            set: {
                // Remove non-digit characters before setting the value to ensure we only get numbers
                let digits = $0.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
                self.avgSteps = digits
            }
        )
    }
    
    private func calculateDailyCaloricIntake() {
        let weightValue = Double(weight) ?? 0
        let heightValue = (heightFeet * 12) + heightInches
        let ageValue = Int(age) ?? 0
        let stepsValue = Double(avgSteps) ?? 0
        
        // Compute the BMR separately for readability and compiler ease
        let bmr = calculateBMR(gender: userData.physical.gender, weight: weightValue, height: Double(heightValue), age: ageValue)
        
        // Calculate the total including steps and round the result to the nearest whole number
        let totalCalories = bmr + Double(100 * stepsValue / 1000)
        let roundedTotalCalories = round(totalCalories * 100) / 100.0
        
        userData.updateMeasurementValue(for: .caloricIntake, with: roundedTotalCalories, shouldSave: true)
    }
    
    private func calculateBMR(gender: Gender, weight: Double, height: Double, age: Int) -> Double {
        if gender == .male {
            return 66 + (6.23 * weight) + (12.7 * height) - (6.8 * Double(age))
        } else {
            return 655 + (4.35 * weight) + (4.7 * height) - (4.7 * Double(age))
        }
    }
    
    struct ResultView: View {
        @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
        let calories: Double
        var dismissAction: () -> Void
        
        var body: some View {
            VStack {
                Text("Daily Caloric Intake").font(.headline)
                Text("\(Int(calories)) Calories").font(.title2)
                
                ActionButton(title: "Done", action: { dismissAction() })
                    .padding(.horizontal)
                
            }
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.25)
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
    }
}

