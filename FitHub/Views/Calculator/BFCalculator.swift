//
//  BFCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct BFCalculator: View {
    @ObservedObject var userData: UserData
    @State private var waist: String = ""
    @State private var neck: String = ""
    @State private var hip: String = ""
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var showingResult: Bool = false
    @State private var isKeyboardVisible = false // Track keyboard visibility
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        _waist = State(initialValue: userData.currentMeasurementValue(for: .waist) == 0 ? "" : String(smartFormat(userData.currentMeasurementValue(for: .waist))))
        _neck = State(initialValue: userData.currentMeasurementValue(for: .neck) == 0 ? "" : String(smartFormat(userData.currentMeasurementValue(for: .neck))))
        _hip = State(initialValue: userData.currentMeasurementValue(for: .hips) == 0 ? "" : String(smartFormat(userData.currentMeasurementValue(for: .hips))))
        _heightFeet = State(initialValue: userData.heightFeet)
        _heightInches = State(initialValue: userData.heightInches)
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Enter Waist and Neck Measurements")) {
                    
                    TextField("Waist (inches)", text: $waist)
                        .keyboardType(.decimalPad)
                    TextField("Neck (inches)", text: $neck)
                        .keyboardType(.decimalPad)
                    if userData.gender == .female {
                        TextField("Hip (inches)", text: $hip)
                            .keyboardType(.decimalPad)
                    }
                }
                Section(header: Text("Enter your Height")) {
                    HeightPicker(feet: $heightFeet, inches: $heightInches)
                }
            }
            if !isKeyboardVisible {
                Button(action: {
                    calculateBodyFatPercentage()
                    showingResult = true
                }) {
                    Text("Calculate Body Fat %")
                        .font(.headline) // Prominent and readable font
                        .foregroundColor(.white) // Ensure the text color contrasts with the background
                        .frame(maxWidth: .infinity) // Make the button span the full width
                        .padding() // Add padding to enlarge the tappable area
                        .background(!isCalculateEnabled ? Color.gray : Color.blue) // Gray if disabled, blue if enabled
                        .cornerRadius(10) // Rounded corners for a modern look
                }
                .disabled(!isCalculateEnabled) // Disable the button if inputs are invalid
                .padding(.bottom, 50) // Space between the button and content below
                .padding(.horizontal) // Align with other elements horizontally
            }
        }
        .disabled(showingResult)
        .blur(radius: showingResult ? 10 : 0)
        .background(Color(UIColor.systemGroupedBackground)) // make button background color match list
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Body Fat % Calculator", displayMode: .inline)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
        .overlay(
            Group {
                if showingResult {
                    BodyFatResultView(bodyFat: userData.currentMeasurementValue(for: .bodyFatPercentage)) {
                        self.showingResult = false
                    }
                    .frame(width: 300, height: 200)
                }
            }
        )
    }
    private var isCalculateEnabled: Bool {
        // For males, we do not need the hip measurement
        if userData.gender == .male {
            return !waist.isEmpty && !neck.isEmpty && (heightFeet > 0 || heightInches > 0)
        }
        
        // For females, all fields including hip are required
        return !waist.isEmpty && !neck.isEmpty && !hip.isEmpty && (heightFeet > 0 || heightInches > 0)
    }
    
    
    private func calculateBodyFatPercentage() {
        let heightValue = Double(heightInches).addingProduct(Double(heightFeet), 12)
        let waistValue = Double(waist) ?? 0
        let neckValue = Double(neck) ?? 0
        let hipValue = Double(hip) ?? 0
        
        let bfP: Double
        if userData.gender == .male {
            let logWaistNeck = log10(waistValue - neckValue)
            
            let logHeight = log10(heightValue)
            bfP = 86.010 * logWaistNeck - 70.041 * logHeight + 36.76
            
        } else {
            let logWaistHipNeck = log10(waistValue + hipValue - neckValue)
            let logHeight = log10(heightValue)
            
            bfP = 163.205 * logWaistHipNeck - 97.684 * logHeight - 78.387
            
        }
        
        // Update bodyfat if it's different
        if userData.currentMeasurementValue(for: .bodyFatPercentage) != bfP {
            userData.updateMeasurementValue(for: .bodyFatPercentage, with: bfP, shouldSave: true)
        }
        
        // Update waist size if it's different
        if userData.currentMeasurementValue(for: .waist) != waistValue {
            userData.updateMeasurementValue(for: .waist, with: waistValue, shouldSave: true)
        }
        
        // Update neck size if it's different
        if userData.currentMeasurementValue(for: .neck) != neckValue {
            userData.updateMeasurementValue(for: .neck, with: neckValue, shouldSave: true)
        }
        
        // Update hip size if it's different
        if userData.currentMeasurementValue(for: .hips) != hipValue {
            userData.updateMeasurementValue(for: .hips, with: hipValue, shouldSave: true)
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

struct BodyFatResultView: View {
    let bodyFat: Double
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    var dismissAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Body Fat Percentage")
                .font(.headline)
            Text("\(bodyFat, specifier: "%.2f") %")
                .font(.title2)
            Button(action: {
                dismissAction()
            }) {
                Text("Done")
                    .font(.headline) // Prominent and readable text
                    .foregroundColor(.white) // Ensure the text color contrasts with the background
                    .frame(maxWidth: .infinity) // Make the button span the full width
                    .padding() // Add padding to enlarge the tappable area
                    .background(Color.blue) // Background color
                    .cornerRadius(10) // Rounded corners for a modern look
            }
            .padding(.horizontal) // Align with other elements horizontally
            .padding(.bottom, 20) // Space between the button and content below
        }
        .frame(width: 300, height: 200)
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
