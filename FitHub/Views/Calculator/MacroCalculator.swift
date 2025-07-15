//
//  MacroCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct MacroCalculator: View {
    @ObservedObject var userData: UserData
    @StateObject private var kbd = KeyboardManager.shared
    @State private var weight: String
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var age: String
    @State private var bmi: Double
    @State private var caloricIntake: Double
    @State private var result: (calories: Double, carbs: Double, proteins: Double, fats: Double)? = nil
    @State private var showingResult: Bool = false
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        _weight = State(initialValue: String(Format.smartFormat(userData.currentMeasurementValue(for: .weight))))
        _heightFeet = State(initialValue: userData.physical.heightFeet)
        _heightInches = State(initialValue: userData.physical.heightInches)
        _age = State(initialValue: String(userData.profile.age))
        _bmi = State(initialValue: userData.currentMeasurementValue(for: .bmi))
        _caloricIntake = State(initialValue: userData.currentMeasurementValue(for: .caloricIntake))
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                TextField("Weight (lbs)", text: $weight)
                    .keyboardType(.numberPad)
            } header: {
                Text("Enter your Age and Weight")
            }
            
            Section {
                HeightPicker(feet: $heightFeet, inches: $heightInches)
            } header: {
                Text("Enter your height")
            }
            
            Section {
                Picker("Activity Level", selection: $userData.physical.activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                        
                    }
                }
                if userData.physical.activityLevel != .select {
                    Text(userData.physical.activityLevel.description).font(.subheadline).foregroundColor(.gray)
                }
            } header: {
                Text("Select your Activity Level")
            }
            
            Section {
                // No rows in this section—just a footer
                EmptyView()
            } footer: {
                if !kbd.isVisible {
                    ActionButton(
                        title: "Calculate Macros",
                        enabled: isCalculateEnabled,
                        action: {
                            buttonPress()
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
        .overlay(
            Group {
                if showingResult {
                    if let result = result {
                        MacroResultView(
                            calories: result.calories,
                            carbs: result.carbs,
                            proteins: result.proteins,
                            fats: result.fats,
                            dismissAction: { showingResult = false }
                        )
                        .padding(.all)
                    }
                }
            }
        )
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Macro Calculator", displayMode: .inline)
    }
    
    private func buttonPress() {
        userData.profile.age = Int(age) ?? 0
        
        let currentWeight = userData.currentMeasurementValue(for: .weight).rounded()
        let newWeight = Double(weight)?.rounded()
        
        if currentWeight != newWeight {
            userData.updateMeasurementValue(for: .weight, with: Double(weight) ?? currentWeight, shouldSave: false)
        }
        // check if this value even exists first
        bmi = userData.currentMeasurementValue(for: .bmi)
        
        if userData.currentMeasurementValue(for: .caloricIntake) == 0 {
            caloricIntake = calculateDailyCaloricIntake()
            userData.updateMeasurementValue(for: .caloricIntake, with: caloricIntake, shouldSave: false)
        } else {
            caloricIntake = userData.currentMeasurementValue(for: .caloricIntake)
        }
        
        userData.physical.heightFeet = heightFeet
        userData.physical.heightInches = heightInches
                
        result = calculateMacros()
        showingResult = true
    }
    
    func calculateMacros() -> (calories: Double, carbs: Double, proteins: Double, fats: Double)? {
        guard let age = Int(age),
              let weight = Double(weight) else { return nil }
        
        // BMR calculation using Mifflin-St Jeor Equation
        let bmr: Double
        if userData.physical.gender == .male {
            bmr = 10 * (weight * 0.453592) + 6.25 * ((Double(heightFeet) * 30.48) + (Double(heightInches) * 2.54)) - 5 * Double(age) + 5
        } else {
            bmr = 10 * (weight * 0.453592) + 6.25 * ((Double(heightFeet) * 30.48) + (Double(heightInches) * 2.54)) - 5 * Double(age) - 161
        }
        
        // Daily calorie needs
        let calories = bmr * userData.physical.activityLevel.multiplier
        
        // Adjust for goals
        // needs modification
        let adjustedCalories: Double
        switch userData.physical.goal {
        case .buildMuscle:
            adjustedCalories = calories - 500
        case .buildMuscleGetStronger:
            adjustedCalories = calories + 500
        default:
            adjustedCalories = calories
        }
        
        // Macronutrient distribution
        let carbs = (adjustedCalories * 0.5) / 4
        let proteins = (adjustedCalories * 0.3) / 4
        let fats = (adjustedCalories * 0.2) / 9
        
        userData.physical.carbs = carbs
        userData.physical.proteins = proteins
        userData.physical.fats = fats
        userData.updateMeasurementValue(for: .caloricIntake, with: adjustedCalories, shouldSave: false)
        userData.saveToFile()
        
        return (calories: adjustedCalories, carbs: carbs, proteins: proteins, fats: fats)
    }
    
    func calculateDailyCaloricIntake() -> Double {
        let weightValue = Double(weight) ?? 0
        let heightValue = (heightFeet * 12) + heightInches
        let ageValue = Int(age) ?? 0
        let stepsValue = Double(userData.physical.avgSteps == 0 ? userData.physical.activityLevel.estimatedSteps : userData.physical.avgSteps)
        
        // BMR calculation using Mifflin-St Jeor Equation
        let bmr: Double
        if userData.physical.gender == .male {
            bmr = 66 + (6.23 * weightValue) + (12.7 * Double(heightValue)) - (6.8 * Double(ageValue))
        } else {
            bmr = 655 + (4.35 * weightValue) + (4.7 * Double(heightValue)) - (4.7 * Double(ageValue))
        }
        
        // Caloric needs based on activity level
        let calories = bmr + Double(100 * stepsValue / 1000)
        
        return calories
    }
    
    private var isCalculateEnabled: Bool {
        // Check if weight and height values have been entered
        return !weight.isEmpty && !age.isEmpty && (heightFeet > 0 || heightInches > 0) && userData.physical.activityLevel != .select
    }
    
    struct MacroResultView: View {
        @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
        let calories: Double
        let carbs: Double
        let proteins: Double
        let fats: Double
        var dismissAction: () -> Void
        
        var body: some View {
            VStack {
                Text("Your Macros").font(.headline)
                Text("Calories: \(Int(round(calories)))") + Text(" kcal").fontWeight(.light)
                Text("Carbohydrates: \(Int(round(carbs)))") + Text(" g").fontWeight(.light)
                Text("Proteins: \(Int(round(proteins)))") + Text(" g").fontWeight(.light)
                Text("Fats: \(Int(round(fats)))") + Text(" g").fontWeight(.light)
                            
                RingView(dailyCaloricIntake: calories, carbs: carbs, fats: fats, proteins: proteins)
                    .padding()
                ActionButton(title: "Done", action: { dismissAction() })
            }
            .padding()
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
    }
}


