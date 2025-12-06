//
//  OneRMCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct OneRMCalculator: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var toast = ToastManager()
    @StateObject private var kbd = KeyboardManager.shared
    @State private var weightLifted: Mass = .init(kg: 0)   // canonical
    @State private var repsText: String = ""              
    @State private var exerciseToSave: Exercise?
    @State private var tappedExercise: Exercise?
    @State private var calculatedOneRepMax: Mass?
    @State private var isCalculated = false
    @State private var showingConfirmationPopup = false
    @State private var showingExerciseSelection = false

    var body: some View {
        ZStack {
            if toast.showingSaveConfirmation {
                InfoBanner(title: "1RM Saved Successfully!").zIndex(1)
            }
            
            Form {
                if !isCalculated {
                    // ─── Inputs ─────────────────────────────────────────────
                    Section {
                        TextField("Enter Weight (\(UnitSystem.current.weightUnit))", text: $weightLifted.asText())
                        .keyboardType(.decimalPad)
                    } header: {
                        Text("Weight Lifted")
                            .textCase(.none)
                            .font(.headline)
                    }
                    
                    Section {
                        TextField("Enter Reps", text: $repsText)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("Reps Performed")
                            .textCase(.none)
                            .font(.headline)
                    } footer: {
                        ErrorFooter(message: repsErrorMessage)
                    }

                    // ─── Calculate button ─────────────────────────────────
                    Section {
                        if !isCalculated && !kbd.isVisible {
                            RectangularButton(
                                title: "Calculate One Rep Max",
                                enabled: isCalculateEnabled,
                                action: calculate
                            )
                            .padding(.vertical)
                            .listRowBackground(Color.clear)
                        }
                    }

                } else {
                    // ─── Results ───────────────────────────────────────────
                    if let oneRM = calculatedOneRepMax {
                        (Text("Calculated 1RM: ").bold()
                         + oneRM.formattedText()
                         )

                        Section {
                            MaxTable(peak: .oneRepMax(oneRM))
                        } header: {
                            Text("1RM Percentages")
                        }

                        Section {
                            Button {
                                showingExerciseSelection = true
                            } label: {
                                HStack {
                                    Text("Select Exercise")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                            }
                        } header: {
                            Text("Save 1RM to Exercise")
                        }
                    }
                }
            }
            .padding(.top)
            .disabled(toast.showingSaveConfirmation)
            .blur(radius: toast.showingSaveConfirmation ? 10 : 0)
        }
        .navigationBarTitle("1 Rep Max Calculator", displayMode: .inline)
        .toolbar {
            if isCalculated {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: resetView) {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .imageScale(.large)
                    }
                }
            }
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .sheet(isPresented: $showingExerciseSelection) {
            ExerciseSelection(
                initialCategory: .resistanceType(.weighted),
                mode: .oneRMCalculator,
                onDone: { exercises in
                    if let first = exercises.first {
                        exerciseTap(first)
                    }
                    showingExerciseSelection = false
                }
            )
        }
        .alert(isPresented: $showingConfirmationPopup) {
            Alert(
                title: Text("Update 1RM"),
                message: Text("Save this 1RM for \(exerciseToSave?.name ?? "")?"),
                primaryButton: .default(Text("Save")) {
                    if let exercise = exerciseToSave,
                       let oneRM = calculatedOneRepMax,
                       let repsVal = Int(repsText)
                    {
                        ctx.exercises.updateExercisePerformance(
                            for: exercise,
                            newValue: .oneRepMax(oneRM), // 1RM in kg
                            loadXmetric: LoadXMetric(load: .weight(weightLifted), metric: .reps(repsVal))
                        )
                        ctx.exercises.savePerformanceData()
                        toast.showSaveConfirmation(duration: 2) {
                            resetView()
                            dismiss()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var isCalculateEnabled: Bool {
        let repsVal = Int(repsText) ?? 0
        return weightLifted.inKg > 0 && repsVal > 1
    }

    private var repsErrorMessage: String? {
        guard !repsText.isEmpty else { return nil }
        guard let r = Int(repsText), r > 1, !repsText.contains(".") else {
            return "Reps must be an integer greater than 1."
        }
        return nil
    }

    // MARK: - Actions
    private func calculate() {
        let repsVal = Int(repsText) ?? 0

        let oneRMKg = OneRMFormula.calculateOneRepMax(
            weight: weightLifted,
            reps: repsVal,
            formula: .brzycki
        )
        calculatedOneRepMax = oneRMKg
        
        isCalculated = true
    }

    private func exerciseTap(_ exercise: Exercise) {
        tappedExercise = exercise
        toast.manageTap { tappedExercise = nil }
        exerciseToSave = exercise
        // Defer alert presentation slightly so it isn't racing with sheet dismissal
        DispatchQueue.main.async {
            showingConfirmationPopup = true
        }
    }

    private func resetView() {
        weightLifted = Mass(kg: 0)
        repsText = ""
        calculatedOneRepMax = nil
        isCalculated = false
        exerciseToSave = nil
    }
}

