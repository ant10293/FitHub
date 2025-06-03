//
//  EnterMaxReps.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EnterMaxReps: View {
    @ObservedObject var userData: UserData
    @State private var situpReps: String = ""
    @State private var squatReps: String = ""
    @State private var pushupReps: String = ""
    @ObservedObject var exerciseData: ExerciseData
    @State private var isKeyboardVisible: Bool = false
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea(.all)
                .zIndex(0)
            
            VStack(spacing: 20) {
                
                //Spacer()
                Text("This is how many reps you can do consecutively in each bodyweight exercise.")
                    .font(.headline)
                    .padding()
                    .multilineTextAlignment(.center)

                VStack(spacing: 15) {
                    InputField(label: "Push ups", value: $pushupReps)
                    InputField(label: "Sit ups", value: $situpReps)
                    InputField(label: "Squats", value: $squatReps)
                }
                
                if !isKeyboardVisible {
                    Button(action: handleSubmit) {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pushupReps.isEmpty && situpReps.isEmpty && squatReps.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                            .font(.headline)
                    }
                    .disabled(pushupReps.isEmpty && situpReps.isEmpty && squatReps.isEmpty)
                    .padding(.vertical, 30)
                    .padding()
                }
                
                Spacer()
                
            }
            //.background(Color(UIColor.secondarySystemBackground)).ignoresSafeArea(.all)
            .navigationBarTitle("Enter your Max Reps", displayMode: .large)
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear(perform: removeKeyboardObservers)
            .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
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
    
    private func handleSubmit() {
        var maxValuesEntered = false
        
        if let situps = Double(situpReps) {
            exerciseData.updateExercisePerformance(for: "Sit-Up", newValue: situps, csvEstimate: false)
            maxValuesEntered = true
        }
        
        if let pushups = Double(pushupReps) {
            exerciseData.updateExercisePerformance(for: "Push-Up", newValue: pushups, csvEstimate: false)
            maxValuesEntered = true
        }
        
        if let squats = Double(squatReps) {
            exerciseData.updateExercisePerformance(for: "Bodyweight Squat", newValue: squats, csvEstimate: false)
            maxValuesEntered = true
        }
        
        if maxValuesEntered {
            exerciseData.savePerformanceData()
            userData.maxRepsEntered = true
            userData.saveSingleVariableToFile(\.maxRepsEntered, for: .maxRepsEntered)
            onFinish()
        }
    }
    
    @ViewBuilder
    private func InputField(label: String, value: Binding<String>) -> some View {
        HStack {
            Spacer(minLength: 20)
            Text(label)
            TextField("Enter Reps", text: value)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Spacer(minLength: 20)
        }
    }
}

