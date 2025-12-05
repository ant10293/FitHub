//
//  WarmupSettingsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/1/25.
//

import SwiftUI

struct WarmupSettingsView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) private var dismiss
    @State private var includeSets: Bool
    @State private var minIntensity: Int
    @State private var maxIntensity: Int
    @State private var setCountModifier: WarmupSetCountModifier
    @State private var exerciseSelection: WarmupExerciseSelection
    
    init(userData: UserData) {
        self.userData = userData
        _includeSets = State(initialValue: userData.workoutPrefs.warmupSettings.includeSets)
        _minIntensity = State(initialValue: userData.workoutPrefs.warmupSettings.minIntensity)
        _maxIntensity = State(initialValue: userData.workoutPrefs.warmupSettings.maxIntensity)
        _setCountModifier = State(initialValue: userData.workoutPrefs.warmupSettings.setCountModifier)
        _exerciseSelection = State(initialValue: userData.workoutPrefs.warmupSettings.exerciseSelection)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // ── INCLUDE WARMUP SETS ───────────────────────────────────────────
                Section {
                    Toggle("Include Warmup Sets", isOn: $includeSets)
                        .onChange(of: includeSets) { oldValue, newValue in
                            userData.workoutPrefs.warmupSettings.includeSets = newValue
                        }
                } footer: {
                    Text("Enable warmup sets in workout generation.")
                }
                
                if includeSets {
                    // ── MIN INTENSITY ────────────────────────────────────────────────
                    Section {
                        HStack {
                            Text("\(minIntensity)%")
                                .monospacedDigit()
                            Slider(
                                value: Binding(
                                    get: { Double(minIntensity) },
                                    set: { newValue in
                                        let clamped = max(1, min(Int(newValue), maxIntensity-1))
                                        minIntensity = clamped
                                        userData.workoutPrefs.warmupSettings.minIntensity = clamped
                                    }
                                ),
                                in: 1...100,
                                step: 1
                            )
                        }
                    } header: {
                        Text("Minimum Intensity")
                    } footer: {
                        if minIntensity < 40 {
                            WarningFooter(message: "Using too little intensity defeats the purpose of warmup sets. They should prepare your muscles for the working sets, not be too easy.")
                        } else {
                            Text("Lowest percentage of the first working set's weight used for the first warmup set. Reps remain the same as the first working set.")
                        }
                    }
                    
                    // ── MAX INTENSITY ────────────────────────────────────────────────
                    Section {
                        HStack {
                            Text("\(maxIntensity)%")
                                .monospacedDigit()
                            Slider(
                                value: Binding(
                                    get: { Double(maxIntensity) },
                                    set: { newValue in
                                        let clamped = max(minIntensity+1, min(Int(newValue), 99))
                                        maxIntensity = clamped
                                        userData.workoutPrefs.warmupSettings.maxIntensity = clamped
                                    }
                                ),
                                in: 1...99,
                                step: 1
                            )
                        }
                    } header: {
                        Text("Maximum Intensity")
                    } footer: {
                        if maxIntensity > 80 {
                            WarningFooter(message: "Using too much intensity defeats the purpose of warmup sets. They should prepare your muscles for the working sets, not cause excessive fatigue.")
                        } else {
                            Text("Highest percentage of the first working set's weight used for the last warmup set. Reps remain the same as the first working set.")
                        }
                    }
                    
                    // ── SET COUNT MODIFIER ───────────────────────────────────────────
                    Section {
                        Picker("Proportion of working sets", selection: $setCountModifier) {
                            ForEach(WarmupSetCountModifier.allCases, id: \.self) { modifier in
                                Text(modifier.displayName).tag(modifier)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: setCountModifier) { oldValue, newValue in
                            if oldValue != newValue {
                                userData.workoutPrefs.warmupSettings.setCountModifier = newValue
                            }
                        }
                    } header: {
                        Text("Warmup Set Count")
                    } footer: {
                        Text("Fraction of working sets to use for warmup. For example, with 4 working sets and 1/2 selected, you'll have 2 warmup sets.")
                    }
                    
                    // ── EXERCISE SELECTION ───────────────────────────────────────────
                    Section {
                        Picker("Exercise Selection", selection: $exerciseSelection) {
                            ForEach(WarmupExerciseSelection.allCases, id: \.self) { selection in
                                Text(selection.rawValue).tag(selection)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .onChange(of: exerciseSelection) { oldValue, newValue in
                            if oldValue != newValue {
                                userData.workoutPrefs.warmupSettings.exerciseSelection = newValue
                            }
                        }
                    } header: {
                        Text("Exercises with Warmup Sets")
                    } footer: {
                        Text(exerciseSelection.description)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitle("Warmup Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

