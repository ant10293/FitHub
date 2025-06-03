//
//  1RMCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct OneRMCalculator: View {
    @State private var weightLifted: String = ""
    @State private var reps: String = ""
    @State private var selectedFormula: OneRepMaxFormula = .landers
    @State private var calculatedOneRepMax: Double?
    @ObservedObject var userData: UserData
    @ObservedObject var exerciseData: ExerciseData
    @State private var isKeyboardVisible = false
    @State private var searchText = ""
    @State private var showingSaveConfirmation = false
    @State private var isCalculated: Bool = false
    @State private var exerciseToSave: Exercise?
    @State private var showingConfirmationPopup = false
    @State private var tappedExercise: Exercise?
    @State private var weightErrorMessage: String?
    @State private var repsErrorMessage: String?
    
    var filteredExercises: [Exercise] {
        exerciseData.allExercises.filter { exercise in
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)) && exercise.usesWeight
        }
    }
    
    var body: some View {
        ZStack {
            Form {
                if showingSaveConfirmation {
                    Section {
                        saveConfirmationView
                            .zIndex(1)  // Ensures the overlay is above all other content
                    }
                }
                
                if !isCalculated {
                    Section(header: Text("Enter Weight and Reps")) {
                        TextField("Weight lifted (lbs)", text: $weightLifted)
                            .keyboardType(.decimalPad)
                            .onChange(of: weightLifted) {
                                validateInputs()
                            }
                        
                        if let errorMessage = weightErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        TextField("Number of reps", text: $reps)
                            .keyboardType(.numberPad)
                            .onChange(of: reps) {
                                validateInputs()
                            }
                        if let errorMessage = repsErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    Section(header: Text("Select Formula")) {
                        Picker("Formula", selection: $selectedFormula) {
                            Text("Lander's").tag(OneRepMaxFormula.landers)
                            Text("Epley's").tag(OneRepMaxFormula.epleys)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                }
                
                if let oneRepMax = calculatedOneRepMax {
                    HStack {
                        Text("Calculated 1RM:").bold()
                        Text("\(oneRepMax, specifier: "%.2f") lbs")
                    }
                    
                    Section(header: Text("1RM Percentages")) {
                        MaxRecordTable(oneRepMax: oneRepMax)
                    }
                    
                    Section(header: Text("Save 1RM to Exercise")) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("Search Exercises", text: $searchText)
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = "" // Clear the search text
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .frame(alignment: .trailing)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(filteredExercises) { exercise in
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                    .bold()
                                HStack {
                                    Image(exercise.fullImagePath)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    // let oneRepMax = exerciseData.getOneRepMax(for: exercise.name) ?? 0.0
                                    let oneRepMax = exerciseData.getMax(for: exercise.name) ?? 0.0
                                    if oneRepMax == 0 {
                                        Text("Current 1RM: - lbs")
                                    } else {
                                        Text("Current 1RM: \(oneRepMax, specifier: "%.2f") lbs")
                                    }
                                }
                            }
                            .padding()
                            .background(tappedExercise == exercise ? Color.gray.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                tappedExercise = exercise
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    tappedExercise = nil
                                }
                                exerciseToSave = exercise
                                showingConfirmationPopup = true
                            }
                        }
                    }
                }
            }
            if !isCalculated && !isKeyboardVisible {
                Button(action: {
                    calculatedOneRepMax = calculateOneRepMax(weight: weightLifted, reps: reps, formula: selectedFormula)
                    isCalculated = true
                }) {
                    Text("Calculate One Rep Max")
                        .font(.headline) // Prominent and readable text
                        .foregroundColor(.white) // Ensure text contrasts with the background
                        .frame(maxWidth: .infinity) // Stretch button to fit container width
                        .padding() // Add padding for larger tappable area
                        .background(isCalculateEnabled ? Color.blue : Color.gray) // Conditional background color
                        .cornerRadius(10) // Rounded corners for a modern look
                }
                .disabled(!isCalculateEnabled) // Disable button if conditions are not met
                .padding(.horizontal) // Horizontal alignment
                .padding(.bottom, 50) // Space below the button
            }
        }
        .navigationBarTitle("1 Rep Max Calculator", displayMode: .inline)
        .toolbar {
            if isCalculated {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: resetView) {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .imageScale(.large)
                    }
                }
            }
        }
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
        .alert(isPresented: $showingConfirmationPopup) {
            Alert(
                title: Text("Update 1RM"),
                message: Text("Are you sure you want to save this 1RM for \(exerciseToSave?.name ?? "")?"),
                primaryButton: .default(Text("Save")) {
                    if let exercise = exerciseToSave, let oneRepMax = calculatedOneRepMax {
                        exerciseData.updateExercisePerformance(for: exercise.name, newValue: oneRepMax, reps: Int(reps), weight: Double(weightLifted), csvEstimate: false)
                        exerciseData.savePerformanceData()
                        showingSaveConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingSaveConfirmation = false
                            resetView()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var saveConfirmationView: some View {
        VStack {
            Text("1RM Saved Successfully!")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .frame(width: 300, height: 100)
        .background(Color.clear)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale) // Smooth transition for showing/hiding
        .centerHorizontally()  // Extension method to center the view
    }
    
    private var isCalculateEnabled: Bool {
        // Ensure weightLifted is a valid number and not empty
        guard !weightLifted.trimmingCharacters(in: .whitespaces).isEmpty, let weight = Double(weightLifted), weight > 0 else {
            
            return false
        }
        
        // Ensure reps is a valid integer, not empty, not 0 or 1, and doesn't contain a decimal
        guard !reps.trimmingCharacters(in: .whitespaces).isEmpty, let repsValue = Int(reps), repsValue > 1 else {
            return false
        }
        
        return true
    }
    
    private func validateInputs() {
        // Validate weightLifted
        if !weightLifted.isEmpty && (Double(weightLifted) == nil || Double(weightLifted) == 0) {
            weightErrorMessage = "Please enter a valid weight."
        } else {
            weightErrorMessage = nil
        }
        
        // Validate reps
        if !reps.isEmpty && (Int(reps) == nil || Int(reps) == 0 || Int(reps) == 1 || reps.contains(".")) {
            repsErrorMessage = "Reps must be an integer greater than 1."
        } else {
            repsErrorMessage = nil
        }
    }
    
    private func resetView() {
        weightLifted = ""
        reps = ""
        selectedFormula = .landers
        calculatedOneRepMax = nil
        isCalculated = false
        searchText = ""
        exerciseToSave = nil
        weightErrorMessage = nil
        repsErrorMessage = nil
    }
    
    private func calculateOneRepMax(weight: String, reps: String, formula: OneRepMaxFormula) -> Double {
        let weightInKg = (Double(weight) ?? 0) * 0.453592
        let repsCount = Double(reps) ?? 0
        
        switch formula {
        case .epleys:
            return (weightInKg * (1 + 0.0333 * repsCount)) * 2.2
        case .landers:
            return ((100 * weightInKg) / (101.3 - 2.67123 * repsCount)) * 2.2
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
