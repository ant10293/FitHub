//
//  MacroCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct MacroCalculator: View {
    @ObservedObject var userData: UserData
    @State private var showingResult: Bool = false
    @State private var weight: String
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var age: String
    @State private var result: (calories: Double, carbs: Double, proteins: Double, fats: Double)? = nil
    @State private var bmi: Double
    @State private var caloricIntake: Double
    @State private var isKeyboardVisible: Bool = false
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        _weight = State(initialValue: String(smartFormat(userData.currentMeasurementValue(for: .weight))))
        _heightFeet = State(initialValue: userData.heightFeet)
        _heightInches = State(initialValue: userData.heightInches)
        _age = State(initialValue: String(userData.age))
        _bmi = State(initialValue: userData.currentMeasurementValue(for: .bmi))
        _caloricIntake = State(initialValue: userData.currentMeasurementValue(for: .caloricIntake))
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Enter your Age and Weight")) {
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Enter your height")) {
                    HeightPicker(feet: $heightFeet, inches: $heightInches)
                }
                
                Section(header: Text("Select your Activity Level")) {
                    Picker("Activity Level", selection: $userData.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                            
                        }
                    }
                    if userData.activityLevel != .select {
                        Text(userData.activityLevel.description).font(.subheadline).foregroundColor(.gray)
                    }
                }
            }
            if !isKeyboardVisible {
                Button(action: {
                    buttonPress()
                }) {
                    Text("Calculate Macros")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(!isCalculateEnabled ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(!isCalculateEnabled) // Disable the button if inputs are not valid
                .padding(.horizontal)
                .padding(.bottom, 25)
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
                            userData: userData,
                            calories: result.calories,
                            carbs: result.carbs,
                            proteins: result.proteins,
                            fats: result.fats,
                            dismissAction: { showingResult = false }
                        ).padding(.all)
                    }
                }
            }
        )
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Macro Calculator", displayMode: .inline)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
    }
    private func buttonPress() {
        userData.age = Int(age) ?? 0
        
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
        
        userData.heightFeet = heightFeet
        userData.heightInches = heightInches
        
        userData.saveToFile()
        
        result = calculateMacros()
        showingResult = true
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func calculateMacros() -> (calories: Double, carbs: Double, proteins: Double, fats: Double)? {
        guard let age = Int(age),
              let weight = Double(weight) else { return nil }
        
        // BMR calculation using Mifflin-St Jeor Equation
        let bmr: Double
        if userData.gender == .male {
            bmr = 10 * (weight * 0.453592) + 6.25 * ((Double(heightFeet) * 30.48) + (Double(heightInches) * 2.54)) - 5 * Double(age) + 5
        } else {
            bmr = 10 * (weight * 0.453592) + 6.25 * ((Double(heightFeet) * 30.48) + (Double(heightInches) * 2.54)) - 5 * Double(age) - 161
        }
        
        // Daily calorie needs
        let calories = bmr * userData.activityLevel.multiplier
        
        // Adjust for goals
        // needs modification
        let adjustedCalories: Double
        switch userData.goal {
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
        
        return (calories: adjustedCalories, carbs: carbs, proteins: proteins, fats: fats)
    }
    
    func calculateDailyCaloricIntake() -> Double {
        let weightValue = Double(weight) ?? 0
        let heightValue = (heightFeet * 12) + heightInches
        let ageValue = Int(age) ?? 0
        let stepsValue = Double(userData.avgSteps == 0 ? userData.activityLevel.estimatedSteps : userData.avgSteps)
        
        // BMR calculation using Mifflin-St Jeor Equation
        let bmr: Double
        if userData.gender == .male {
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
        return !weight.isEmpty && !age.isEmpty && (heightFeet > 0 || heightInches > 0) && userData.activityLevel != .select
    }
}


struct MacroResultView: View {
    @ObservedObject var userData: UserData
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    let calories: Double
    let carbs: Double
    let proteins: Double
    let fats: Double
    var dismissAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Your Macros")
                .font(.headline)
            Text("Calories: \(Int(calories)) kcal")
            Text("Carbohydrates: \(Int(carbs)) g")
            Text("Proteins: \(Int(proteins)) g")
            Text("Fats: \(Int(fats)) g")
                .padding(.bottom)
            
            RingView(dailyCaloricIntake: calories, carbs: carbs, fats: fats, proteins: proteins)
            .padding(.horizontal)
            .padding(.bottom)
            
            Button(action: {
                userData.carbs = carbs
                userData.proteins = proteins
                userData.fats = fats
                userData.updateMeasurementValue(for: .caloricIntake, with: calories, shouldSave: false)
                userData.saveToFile()
                                
                dismissAction()
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity) // Make the text span the entire width of the button
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
