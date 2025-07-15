//
//  OneRMCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI



struct OneRMCalculator: View {
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var selectedFormula: OneRMFormula = .epleys
    @State private var weightLifted: String = ""
    @State private var reps: String = ""
    @State private var searchText: String = ""
    @State private var exerciseToSave: Exercise?
    @State private var tappedExercise: Exercise?
    @State private var calculatedOneRepMax: Double?
    @State private var isCalculated: Bool = false
    @State private var showingConfirmationPopup: Bool = false
    
    var body: some View {
        ZStack {
            if ctx.toast.showingSaveConfirmation { InfoBanner(text: "1RM Saved Successfully!").zIndex(1) }
            
            Form {
                if !isCalculated {
                    Section(
                        header: Text("Enter Weight and Reps"),
                        footer: Text(repsErrorMessage ?? "")
                            .foregroundColor(.red) // or any custom color
                    ) {
                    
                        TextField("Weight lifted (lbs)", text: $weightLifted)
                            .keyboardType(.decimalPad)
                            .onChange(of: weightLifted) { oldValue, newValue in
                                weightLifted = InputLimiter.filteredWeight(old: oldValue, new: newValue)
                            }

                        TextField("Number of reps", text: $reps)
                            .keyboardType(.numberPad)
                            .onChange(of: reps) { oldValue, newValue in
                                reps = InputLimiter.filteredReps(newValue)
                            }
                    }
                    
                    Section {
                        Picker("Formula", selection: $selectedFormula) {
                            Text("Epley's").tag(OneRMFormula.epleys)
                            Text("Brzycki's").tag(OneRMFormula.brzycki)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        Text(selectedFormula.description)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    } header: {
                        Text("Select Formula")
                    }
                    
                    Section {
                        // No rows in this section—just a footer
                        EmptyView()
                    } footer: {
                        if !isCalculated && !kbd.isVisible {
                            ActionButton(
                                title: "Calculate One Rep Max",
                                enabled: isCalculateEnabled,
                                action: {
                                    calculatedOneRepMax = OneRMFormula.calculateOneRepMax(weight: Double(weightLifted) ?? 0, reps: Int(reps) ?? 0, formula: selectedFormula)
                                    isCalculated = true
                                }
                            )
                            .padding(.top, 6)
                            .padding(.bottom, 16)
                        }
                    }
                    
                } else {
                    if let oneRepMax = calculatedOneRepMax {
                        HStack {
                            Text("Calculated 1RM:").bold()
                            Text("\(oneRepMax, specifier: "%.2f") lbs")
                        }
                        
                        Section {
                            OneRMTable(oneRepMax: oneRepMax)
                        } header: {
                            Text("1RM Percentages")
                        }
                        
                        Section {
                            SearchBar(text: $searchText, placeholder: "Search Exercises")
                                .padding(.horizontal)
                            
                            ForEach(filteredExercises) { exercise in
                                // Tappable row
                                ExerciseRow(exercise, heartOverlay: false, accessory: { EmptyView() }, detail: {
                                    let oneRepMax = ctx.exercises.getMax(for: exercise.id) ?? 0.0
                                        Text("Current 1RM:").foregroundStyle(.gray) +
                                        Text(" \(oneRepMax != 0 ? String(format: "%.2f", oneRepMax) : "") ") +
                                        Text("\(oneRepMax == 0 ? "— " : "")lbs").fontWeight(.light)
                                    },
                                    onTap: { exerciseTap(exercise) }
                                )
                            }
                        } header: {
                            Text("Save 1RM to Exercise")
                        }
                    }
                }
            }
            .blur(radius: ctx.toast.showingSaveConfirmation ? 10 : 0)
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
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .alert(isPresented: $showingConfirmationPopup) {
            Alert(
                title: Text("Update 1RM"),
                message: Text("Are you sure you want to save this 1RM for \(exerciseToSave?.name ?? "")?"),
                primaryButton: .default(Text("Save")) {
                    if let exercise = exerciseToSave, let oneRepMax = calculatedOneRepMax {
                        ctx.exercises.updateExercisePerformance(for: exercise, newValue: oneRepMax, reps: Int(reps), weight: Double(weightLifted), csvEstimate: false)
                        ctx.exercises.savePerformanceData()
                        ctx.toast.showSaveConfirmation(duration: 2) {
                            resetView()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var filteredExercises: [Exercise] {
        ctx.exercises.filteredExercises(
            searchText: searchText,
            selectedCategory: .resistanceType(.weighted),
            userData: ctx.userData,
            equipmentData: ctx.equipment
        )
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
    
    private var weightErrorMessage: String? {
        if !weightLifted.isEmpty && (Double(weightLifted) == nil || Double(weightLifted) == 0) {
            return "Please enter a valid weight."
        } else {
            return nil
        }
    }
    
    private var repsErrorMessage: String? {
        if !reps.isEmpty && (Int(reps) == nil || Int(reps) == 0 || Int(reps) == 1 || reps.contains(".")) {
            return "Reps must be an integer greater than 1."
        } else {
            return nil
        }
    }
    
    private func exerciseTap(_ exercise: Exercise) {
        tappedExercise = exercise
        ctx.toast.manageTap(completion: { tappedExercise = nil })
        exerciseToSave = exercise
        showingConfirmationPopup = true
    }

    @ViewBuilder
    private func errorRow(_ message: String) -> some View {
        Group {
            Text("ERROR: ").bold() +
            Text(message)
        }
        .foregroundColor(.red)
        .font(.caption)
    }
    
    private func resetView() {
        weightLifted = ""
        reps = ""
        selectedFormula = .epleys
        calculatedOneRepMax = nil
        isCalculated = false
        searchText = ""
        exerciseToSave = nil
    }
}
