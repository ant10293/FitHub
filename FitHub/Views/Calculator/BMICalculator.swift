//
//  BMICalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct BMICalculator: View {
    @ObservedObject var userData: UserData
    @State private var weight: String
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var showingResult: Bool = false
    @State private var isButtonPressed = false
    @State private var isKeyboardVisible = false // Track keyboard visibility
    
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        // Initialize with existing user data if available
        _weight = State(initialValue: String(smartFormat(userData.currentMeasurementValue(for: .weight))))
        _heightFeet = State(initialValue: userData.heightFeet)
        _heightInches = State(initialValue: userData.heightInches)
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Enter your Weight")) {
                    HStack{
                        TextField("Weight in pounds (lbs)", text: $weight)
                            .keyboardType(.decimalPad)
                    }
                }
                Section(header: Text("Enter your Height")) {
                    HeightPicker(feet: $heightFeet, inches: $heightInches)
                }
            }
            if !isKeyboardVisible {
                Button(action: {
                    self.calculateAndUpdateBMI()
                    self.showingResult = true
                }) {
                    Text("Calculate BMI")
                        .font(.headline) // Set the font for the button text
                        .foregroundColor(.white) // Ensure the text color is white
                        .frame(maxWidth: .infinity) // Make the button span the entire width
                        .padding() // Add padding for better touch area
                        .background(!isCalculateEnabled ? Color.gray : Color.blue) // Dynamically change background color
                        .cornerRadius(10) // Apply rounded corners
                }
                .disabled(!isCalculateEnabled) // Disable the button when inputs are invalid
                .padding(.bottom, 50) // Add padding at the bottom
                .padding(.horizontal) // Add horizontal padding for alignment
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
                    BMIResultView() {
                        self.showingResult = false
                        
                        let currentWeight = userData.currentMeasurementValue(for: .weight).rounded()
                        let newWeight = Double(weight)?.rounded()
                        
                        if currentWeight != newWeight {
                            userData.updateMeasurementValue(for: .weight, with: Double(weight) ?? currentWeight, shouldSave: true)
                        }
                    }
                    .frame(width: 320, height: 200)
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
        let calculatedBMI = calculateBMI(heightInches: heightInches, heightFeet: heightFeet, weight: weight)
        let roundedBMI = round(calculatedBMI * 100) / 100.0
        
        // Retrieve the current BMI from userData for comparison
        let currentBMI = userData.currentMeasurementValue(for: .bmi)
        
        // Update only if the BMI has changed
        if currentBMI != roundedBMI {
            userData.updateMeasurementValue(for: .bmi, with: roundedBMI, shouldSave: true)
        }
        userData.heightFeet = heightFeet
        userData.heightInches = heightInches
    }
    
    private func calculateBMI(heightInches: Int, heightFeet: Int, weight: String) -> Double {
        let totalInches = (heightFeet * 12) + heightInches
        guard let w = Double(weight), totalInches > 0 else { return 0 }
        
        return (w / Double(totalInches * totalInches)) * 703
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


struct BMIResultView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    var dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Your BMI")
                .font(.headline)
                .padding(.top)
            Text(String(format: "%.2f", userData.currentMeasurementValue(for: .bmi)))
                .font(.title)
            
            BMICategoryTable(userBMI: userData.currentMeasurementValue(for: .bmi))
                .frame(height: 60)
            
            Button(action: {
                dismissAction()
            }) {
                Text("Done")
                    .font(.headline) // Set the font style for the button text
                    .foregroundColor(.white) // Ensure the text color is white
                    .frame(maxWidth: .infinity) // Make the button span the full width
                    .padding() // Add padding for a larger tappable area
                    .background(Color.blue) // Set the button's background color
                    .cornerRadius(10) // Apply rounded corners for a better appearance
            }
            .padding(.bottom) // Add bottom padding to separate it from other UI elements
        }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
