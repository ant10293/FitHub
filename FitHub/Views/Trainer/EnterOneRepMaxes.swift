//
//  EnterOneRepMaxes.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EnterOneRepMaxes: View {
    @ObservedObject var userData: UserData
    @ObservedObject var exerciseData: ExerciseData
    @State private var benchPressMax: String = ""
    @State private var squatMax: String = ""
    @State private var deadliftMax: String = ""
    @State private var isKeyboardVisible: Bool = false
    @State private var numberReps: Int = 1 // Defaulting to 1 to ensure the Text reflects initial selection correctly
    let repOptions: [Int] = Array(1...8).filter { $0 % 1 == 0 }
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text("Don't know your 1 rep max?")
                    .font(.headline)
                Text("Enter your 2-8 rep max for atleast one of")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .centerHorizontally()
                Text("the exercises below.")
                    .padding(.top, -5)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .centerHorizontally()
            }
            .padding(.top, 180)
            
            HStack(alignment: .center, spacing: 20) {
                Text("Number Of Reps")
                    .bold()
                Picker(" ", selection: $numberReps) {
                    ForEach(repOptions, id: \.self) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding(.vertical, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            
            
            VStack(spacing: 15) {
                InputField(label: "Bench Press", value: $benchPressMax)
                InputField(label: "Squat", value: $squatMax)
                InputField(label: "Deadlift", value: $deadliftMax)
            }
            
            if !isKeyboardVisible {
                Button(action: handleSubmit) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                    //.background(benchPressMax.isEmpty || squatMax.isEmpty || deadliftMax.isEmpty ? Color.gray : Color.green)
                        .background(benchPressMax.isEmpty && squatMax.isEmpty && deadliftMax.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .disabled(benchPressMax.isEmpty && squatMax.isEmpty && deadliftMax.isEmpty) // only need to enter one
                .padding(.vertical, 30)
                .padding()
            }
            Spacer()
        }
        .background(Color(UIColor.secondarySystemBackground)).ignoresSafeArea(.all)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
        .overlay(isKeyboardVisible ? dismissKeyboardButton.padding(.bottom, 35) : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Enter your \(numberReps) Rep Max", displayMode: .large)
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
    
    private func handleSubmit() {
        var maxValuesEntered = false
        
        if let benchMax = Double(benchPressMax) {
            let estimatedBench = calculateOneRepMax(weight: benchMax)
            exerciseData.updateExercisePerformance(for: "Bench Press", newValue: estimatedBench, reps: numberReps, weight: benchMax, csvEstimate: false)
            maxValuesEntered = true
        }
        
        if let squatMax = Double(squatMax) {
            let estimatedSquat = calculateOneRepMax(weight: squatMax)
            exerciseData.updateExercisePerformance(for: "Back Squat", newValue: estimatedSquat, reps: numberReps, weight: squatMax, csvEstimate: false)
            maxValuesEntered = true
        }
        
        if let deadMax = Double(deadliftMax) {
            let estimatedDeadlift = calculateOneRepMax(weight: deadMax)
            exerciseData.updateExercisePerformance(for: "Deadlift", newValue: estimatedDeadlift, reps: numberReps, weight: deadMax, csvEstimate: false)
            maxValuesEntered = true
        }
        
        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.oneRepMaxesEntered = true
            userData.saveSingleVariableToFile(\.oneRepMaxesEntered, for: .oneRepMaxesEntered)
            onFinish()
        }
    }
    
    private func calculateOneRepMax(weight: Double) -> Double {
        let estimatedMax = Double(weight) / (1.0278 - 0.0278 * Double(numberReps))
        return round(estimatedMax)
        
    }
    
    @ViewBuilder
    private func InputField(label: String, value: Binding<String>) -> some View {
        HStack {
            Spacer(minLength: 20)
            Text(label)
            TextField("Enter Weight", text: value)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Spacer(minLength: 20)
        }
    }
}
