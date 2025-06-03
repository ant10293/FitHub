//
//  KcalCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct KcalCalculator: View {
    @ObservedObject var userData: UserData
    @State private var showingResult: Bool = false
    @State private var weight: String
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var avgSteps: String = ""
    @State private var age: String
    @State private var isKeyboardVisible = false // Track keyboard visibility
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        // Initialize with existing user data if available
        _weight = State(initialValue: String(smartFormat(userData.currentMeasurementValue(for: .weight))))
        _avgSteps = State(initialValue: userData.avgSteps == 0 ? "" : String(userData.avgSteps))
        _heightFeet = State(initialValue: userData.heightFeet)
        _heightInches = State(initialValue: userData.heightInches)
        _age = State(initialValue: String(userData.age))
    }
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Enter Age and Weight")) {
                    TextField("Age in years", text: $age)
                        .keyboardType(.numberPad)
                    
                    TextField("Weight in pounds (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Enter your Height")) {
                    HeightPicker(feet: $heightFeet, inches: $heightInches)
                }
                
                Section(header: Text("Enter Steps per Day")) {
                    TextField("Avg Steps per Day", text: stepsBinding)
                        .keyboardType(.numberPad)
                }
            }
            
            if !isKeyboardVisible {
                Button(action: {
                    calculateDailyCaloricIntake()
                    showingResult = true
                }) {
                    Text("Calculate Daily Caloric Intake")
                        .font(.headline) // Set the font style for the button text
                        .foregroundColor(.white) // Ensure the text color is white
                        .frame(maxWidth: .infinity) // Make the button span the full width
                        .padding() // Add padding for a larger tappable area
                        .background(isCalculateEnabled ? Color.blue : Color.gray) // Background color changes based on the state
                        .cornerRadius(10) // Apply rounded corners
                }
                .disabled(!isCalculateEnabled) // Disable the button if inputs are not valid
                .padding(.bottom, 50) // Add bottom padding for separation
                .padding(.horizontal) // Add horizontal padding for consistent alignment
            }
        }
        .disabled(showingResult)
        .blur(radius: showingResult ? 10 : 0)
        .background(Color(UIColor.systemGroupedBackground)) // make button background color match list
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
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
                        userData.heightFeet = heightFeet
                        userData.heightInches = heightInches
                        userData.avgSteps = Int(avgSteps) ?? 0
                        userData.age = Int(age) ?? 0
                        
                        userData.saveToFile()
                    }
                    .frame(width: 300, height: 200)
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
        let bmr = calculateBMR(gender: userData.gender, weight: weightValue, height: Double(heightValue), age: ageValue)
        
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
}

struct ResultView: View {
    let calories: Double
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    var dismissAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Daily Caloric Intake")
                .font(.headline)
            Text("\(Int(calories)) Calories")
                .font(.title2)
            Button(action: {
                dismissAction()
            }) {
                Text("Done")
                    .font(.headline) // Set a prominent font style for the button text
                    .foregroundColor(.white) // Ensure the text is visible
                    .frame(maxWidth: .infinity) // Make the button span the full width
                    .padding() // Add padding to make the button area larger
                    .background(Color.blue) // Add the background color
                    .cornerRadius(10) // Apply rounded corners for better aesthetics
            }
            .padding(.horizontal) // Add horizontal padding to align with other elements
            
        }
        .frame(width: 300, height: 200)
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
