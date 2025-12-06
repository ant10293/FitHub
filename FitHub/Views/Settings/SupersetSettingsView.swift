//
//  SupersetSettingsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/1/25.
//

import SwiftUI

struct SupersetSettingsView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) private var dismiss
    @State private var enabled: Bool
    @State private var equipmentOption: SupersetEquipmentOption
    @State private var muscleOption: SupersetMuscleOption
    @State private var ratio: Int
    @State private var restTime: TimeSpan
    @State private var showRestPicker: Bool = false
    let supersetRest: RestType = .superset
    
    init(userData: UserData) {
        self.userData = userData
        _enabled = State(initialValue: userData.workoutPrefs.supersetSettings.enabled)
        _equipmentOption = State(initialValue: userData.workoutPrefs.supersetSettings.equipmentOption)
        _muscleOption = State(initialValue: userData.workoutPrefs.supersetSettings.muscleOption)
        _ratio = State(initialValue: userData.workoutPrefs.supersetSettings.ratio)
        
        let resolved = userData.workoutPrefs.customRestPeriods ?? userData.physical.goal.defaultRest
        _restTime = State(initialValue: TimeSpan(seconds: resolved.rest(for: .superset)))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // ── ENABLE SUPERSETS ───────────────────────────────────────────────
                Section {
                    Toggle("Enable Supersets", isOn: $enabled)
                        .onChange(of: enabled) { oldValue, newValue in
                            userData.workoutPrefs.supersetSettings.enabled = newValue
                        }
                } footer: {
                    Text("Enable superset pairing in workout generation.")
                }
                
                if enabled {
                    // ── EQUIPMENT OPTION ────────────────────────────────────────────────
                    Section {
                        Picker("Equipment Matching", selection: $equipmentOption) {
                            ForEach(SupersetEquipmentOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: equipmentOption) { oldValue, newValue in
                            if oldValue != newValue {
                                userData.workoutPrefs.supersetSettings.equipmentOption = newValue
                            }
                        }
                    } header: {
                        Text("Equipment")
                    } footer: {
                        Text(equipmentOption.description)
                    }
                    
                    // ── MUSCLE OPTION ────────────────────────────────────────────────
                    Section {
                        Picker("Muscle Targeting", selection: $muscleOption) {
                            ForEach(SupersetMuscleOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: muscleOption) { oldValue, newValue in
                            if oldValue != newValue {
                                userData.workoutPrefs.supersetSettings.muscleOption = newValue
                            }
                        }
                    } header: {
                        Text("Muscle Targeting")
                    } footer: {
                        Text(muscleOption.description)
                    }
                    
                    // ── RATIO ───────────────────────────────────────────────────────
                    Section {
                        HStack {
                            Text("\(ratio)%")
                                .monospacedDigit()
                            Slider(
                                value: Binding(
                                    get: { Double(ratio) },
                                    set: { newValue in
                                        let clamped = max(0, min(Int(newValue), 100))
                                        ratio = clamped
                                        userData.workoutPrefs.supersetSettings.ratio = clamped
                                    }
                                ),
                                in: 0...100,
                                step: 5
                            )
                        }
                    } header: {
                        Text("Superset Limit")
                    } footer: {
                        Text("Maximum percentage of exercises that can be supersetted. For example, with 10 exercises and 20% selected, up to 2 exercises can be supersetted (1 pair).")
                    }
                    
                    // ── REST PERIOD ─────────────────────────────────────────────────
                    Section {
                        CustomDisclosure(
                            title: "Superset Rest",
                            note: supersetRest.note,
                            isActive: showRestPicker,
                            usePadding: false,
                            onTap: { showRestPicker.toggle() },
                            onClose: { showRestPicker = false },
                            valueView: {
                                Text(Format.timeString(from: restTime.inSeconds))
                                    .monospacedDigit()
                            },
                            content: {
                                MinSecPicker(time: $restTime)
                                    .onChange(of: restTime) { oldValue, newValue in
                                        updateRestPeriod()
                                    }
                            }
                        )
                    } header: {
                        Text("Rest Period")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitle("Superset Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func updateRestPeriod() {
        var custom = userData.workoutPrefs.customRestPeriods ?? userData.physical.goal.defaultRest
        custom.modify(for: supersetRest, with: restTime.inSeconds)
        if custom == userData.physical.goal.defaultRest {
            userData.workoutPrefs.customRestPeriods = nil
        } else {
            userData.workoutPrefs.customRestPeriods = custom
        }
    }
}

