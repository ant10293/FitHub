//
//  SetDetailIntensity.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/29/25.
//

import SwiftUI

struct SetDetailIntensity: View {
    @ObservedObject var userData: UserData
    @State private var setStructure: SetStructures
    @State private var minIntensity: Int
    @State private var maxIntensity: Int
    @State private var fixedIntensity: Int
    @State private var topSet: TopSetOption
    
    init(userData: UserData) {
        self.userData = userData
        _setStructure = State(initialValue: userData.workoutPrefs.setStructure)
        _minIntensity = State(initialValue: userData.settings.setIntensity.minIntensity)
        _maxIntensity = State(initialValue: userData.settings.setIntensity.maxIntensity)
        _fixedIntensity = State(initialValue: userData.settings.setIntensity.fixedIntensity)
        _topSet = State(initialValue: userData.settings.setIntensity.topSet)
    }

    var body: some View {
        List {
            Section {
                Picker("Set Structure", selection: $setStructure) {
                    ForEach(SetStructures.allCases, id: \.self) { structure in
                        Text(structure.rawValue).tag(structure)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: setStructure) { oldValue, newValue in
                    if oldValue != newValue {
                        userData.workoutPrefs.setStructure = newValue
                    }
                }
            } header: {
                Text("Structure")
            } footer: {
                Text(setStructure.desc)
            }
            
            if setStructure == .fixed || topSet == .allSets {
                // ── FIXED INTENSITY ───────────────────────────────────────────────
                Section {
                    HStack {
                        Text("\(fixedIntensity)%")
                            .monospacedDigit()
                        Slider(
                            value: Binding(
                                get: { Double(fixedIntensity) },
                                set: { newValue in
                                    fixedIntensity = Int(newValue)
                                    userData.settings.setIntensity.fixedIntensity = Int(newValue)
                                }
                            ),
                            in: 1...100,
                            step: 1
                        )
                        .accessibilityValue("\(fixedIntensity) percent")
                    }
                } header: {
                    Text("Fixed Intensity")
                } footer: {
                    Text("Percentage of your max used for all sets.")
                }
            } else {
                // ── MIN INTENSITY ────────────────────────────────────────────────
                Section {
                    HStack {
                        Text("\(minIntensity)%")
                            .monospacedDigit()
                        Slider(
                            value: Binding(
                                get: { Double(minIntensity) },
                                set: { newValue in
                                    let clamped = max(1, min(Int(newValue), maxIntensity))
                                    minIntensity = clamped
                                    userData.settings.setIntensity.minIntensity = clamped
                                }
                            ),
                            in: 1...100,
                            step: 1
                        )
                        .accessibilityValue("\(minIntensity) percent")
                    }
                } header: {
                    Text("Minimum Intensity")
                } footer: {
                    Text("Lowest percentage of your max used for working sets.")
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
                                    let clamped = max(minIntensity, min(Int(newValue), 100))
                                    maxIntensity = clamped
                                    userData.settings.setIntensity.maxIntensity = clamped
                                }
                            ),
                            in: 1...100,
                            step: 1
                        )
                        .accessibilityValue("\(maxIntensity) percent")
                    }
                } header: {
                    Text("Maximum Intensity")
                } footer: {
                    Text("Highest percentage of your max used for your top set.")
                }
            }
            
            // ── TOP SET ───────────────────────────────────────────────────────
            Section {
                Picker("Top Set", selection: $topSet) {
                    ForEach(TopSetOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: topSet) { oldValue, newValue in
                    if oldValue != newValue {
                        userData.settings.setIntensity.topSet = newValue
                    }
                }
            } header: {
                Text("Top Set Position")
            } footer: {
                if setStructure == .fixed && topSet != .allSets {
                    WarningFooter(message: "Fixed set structure is not compatible with the current selection. 'All Sets' will be used instead.")
                } else {
                    Text(topSet.footerText)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitle("Set Intensity", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") { reset() }
                    .foregroundStyle(isDefault ? .gray : .red)
                    .disabled(isDefault)
            }
        }
    }
    
    private var isDefault: Bool {
        userData.workoutPrefs.setStructure == .pyramid &&
        userData.settings.setIntensity == SetIntensitySettings()
    }
    
    private func reset() {
        setStructure = .pyramid
        minIntensity = 70
        maxIntensity = 90
        fixedIntensity = 80
        topSet = .lastSet
        userData.workoutPrefs.setStructure = .pyramid
        userData.settings.setIntensity = SetIntensitySettings()
    }
}

