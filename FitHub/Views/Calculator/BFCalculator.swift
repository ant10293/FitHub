//
//  BFCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct BFCalculator: View {
    @ObservedObject var userData: UserData
    @StateObject private var kbd = KeyboardManager.shared
    @State private var waist: String = ""
    @State private var neck: String = ""
    @State private var hip: String = ""
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var showingResult: Bool = false
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        _waist = State(initialValue: userData.currentMeasurementValue(for: .waist) == 0 ? "" : String(Format.smartFormat(userData.currentMeasurementValue(for: .waist))))
        _neck = State(initialValue: userData.currentMeasurementValue(for: .neck) == 0 ? "" : String(Format.smartFormat(userData.currentMeasurementValue(for: .neck))))
        _hip = State(initialValue: userData.currentMeasurementValue(for: .hips) == 0 ? "" : String(Format.smartFormat(userData.currentMeasurementValue(for: .hips))))
        _heightFeet = State(initialValue: userData.physical.heightFeet)
        _heightInches = State(initialValue: userData.physical.heightInches)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Waist (inches)", text: $waist)
                    .keyboardType(.decimalPad)
                TextField("Neck (inches)", text: $neck)
                    .keyboardType(.decimalPad)
                if userData.physical.gender == .female {
                    TextField("Hip (inches)", text: $hip)
                        .keyboardType(.decimalPad)
                }
            } header: {
                Text("Enter Waist and Neck Measurements")
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
                        title: "Calculate Body Fat %",
                        enabled: isCalculateEnabled,
                        action: {
                            calculatebodyFatPercentage()
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
        .navigationBarTitle("Body Fat % Calculator", displayMode: .inline)
        .overlay(
            Group {
                if showingResult {
                    BodyFatResultView(bodyFat: userData.currentMeasurementValue(for: .bodyFatPercentage)) {
                        self.showingResult = false
                    }
                }
            }
        )
    }
    
    private var isCalculateEnabled: Bool {
        // For males, we do not need the hip measurement
        if userData.physical.gender == .male {
            return !waist.isEmpty && !neck.isEmpty && (heightFeet > 0 || heightInches > 0)
        }
        
        // For females, all fields including hip are required
        return !waist.isEmpty && !neck.isEmpty && !hip.isEmpty && (heightFeet > 0 || heightInches > 0)
    }
    
    private func calculatebodyFatPercentage() {
        let heightValue = Double(heightInches).addingProduct(Double(heightFeet), 12)
        let waistValue = Double(waist) ?? 0
        let neckValue = Double(neck) ?? 0
        let hipValue = Double(hip) ?? 0
        
        let bfP: Double
        if userData.physical.gender == .male {
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
    
    struct BodyFatResultView: View {
        @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
        let bodyFat: Double
        var dismissAction: () -> Void
        
        var body: some View {
            VStack {
                Text("Body Fat Percentage").font(.headline)
                Text("\(bodyFat, specifier: "%.2f") %").font(.title2)
                
                ActionButton(title: "Done", action: { dismissAction() })
                    .padding()
            }
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.25)
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
    }
}


