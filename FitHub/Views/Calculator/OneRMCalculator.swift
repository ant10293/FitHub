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
    @State private var weightLifted: Mass = .init(kg: 0)   // canonical
    @State private var repsText: String = ""               // keep as text for the TF
    @State private var searchText: String = ""
    @State private var exerciseToSave: Exercise?
    @State private var tappedExercise: Exercise?
    @State private var calculatedOneRepMax: Mass?
    @State private var isCalculated = false
    @State private var showingConfirmationPopup = false

    var body: some View {
        ZStack {
            if ctx.toast.showingSaveConfirmation {
                InfoBanner(text: "1RM Saved Successfully!").zIndex(1)
            }

            let unitLabel = UnitSystem.current.weightUnit

            Form {
                if !isCalculated {
                    // ─── Inputs ─────────────────────────────────────────────
                    Section {
                        TextField("Enter Weight (\(unitLabel))", text: $weightLifted.asText())
                        .keyboardType(.decimalPad)
                    } header: {
                        Text("Weight Lifted")
                    }
                    
                    Section {
                        TextField("Enter Reps", text: digitsBinding($repsText))
                            .keyboardType(.numberPad)
                    } header: {
                        Text("Reps Performed")
                    } footer: {
                        if let msg = repsErrorMessage {
                            Text(msg).foregroundStyle(.red)
                        }
                    }

                    // ─── Calculate button ─────────────────────────────────
                    Section {
                        EmptyView()
                    } footer: {
                        if !isCalculated && !kbd.isVisible {
                            ActionButton(
                                title: "Calculate One Rep Max",
                                enabled: isCalculateEnabled,
                                action: calculate
                            )
                            .padding(.vertical)
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
                            SearchBar(text: $searchText, placeholder: "Search Exercises")

                            ForEach(filteredExercises) { exercise in
                                ExerciseRow(
                                    exercise,
                                    heartOverlay: true,
                                    favState: FavoriteState.getState(for: exercise, userData: ctx.userData),
                                    accessory: { EmptyView() },
                                    detail: {
                                        let cur = ctx.exercises.peakMetric(for: exercise.id)?.displayValue ?? 0.0
                                        Text("Current 1RM: ").foregroundStyle(.gray)
                                        + Text(cur > 0 ? Format.smartFormat(cur) : "-")
                                        + Text(" \(unitLabel)").fontWeight(.light)
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
            .disabled(ctx.toast.showingSaveConfirmation)
            .blur(radius: ctx.toast.showingSaveConfirmation ? 10 : 0)
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
                            newValue: .oneRepMax(oneRM),               // 1RM in kg
                            repsXweight: RepsXWeight(reps: repsVal, weight: weightLifted)
                        )
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

    // MARK: - Filters / Derived

    private var filteredExercises: [Exercise] {
        ctx.exercises.filteredExercises(
            searchText: searchText,
            selectedCategory: .resistanceType(.weighted),
            userData: ctx.userData,
            equipmentData: ctx.equipment
        )
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
        ctx.toast.manageTap { tappedExercise = nil }
        exerciseToSave = exercise
        showingConfirmationPopup = true
    }

    private func resetView() {
        weightLifted = Mass(kg: 0)
        repsText = ""
        calculatedOneRepMax = nil
        isCalculated = false
        searchText = ""
        exerciseToSave = nil
    }

    // MARK: - Small utils

    private func digitsBinding(_ src: Binding<String>) -> Binding<String> {
        Binding(
            get: { src.wrappedValue },
            set: { src.wrappedValue = $0.replacingOccurrences(of: "\\D", with: "", options: .regularExpression) }
        )
    }
}

