//
//  WarmupSettingsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/1/25.
//

import SwiftUI

struct WarmupSettingsView: View {
    @ObservedObject var userData: UserData
    @State private var minIntensity: Int
    @State private var maxIntensity: Int
    @State private var setCountModifier: WarmupSetCountModifier
    
    init(userData: UserData) {
        self.userData = userData
        _minIntensity = State(initialValue: userData.settings.warmupSettings.minIntensity)
        _maxIntensity = State(initialValue: userData.settings.warmupSettings.maxIntensity)
        _setCountModifier = State(initialValue: userData.settings.warmupSettings.setCountModifier)
    }
    
    var body: some View {
        List {
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
                                userData.settings.warmupSettings.minIntensity = clamped
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
                                let clamped = max(minIntensity, min(Int(newValue), 99))
                                maxIntensity = clamped
                                userData.settings.warmupSettings.maxIntensity = clamped
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
                Picker("Set Count", selection: $setCountModifier) {
                    ForEach(WarmupSetCountModifier.allCases, id: \.self) { modifier in
                        Text(modifier.displayName).tag(modifier)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: setCountModifier) { oldValue, newValue in
                    if oldValue != newValue {
                        userData.settings.warmupSettings.setCountModifier = newValue
                    }
                }
            } header: {
                Text("Warmup Set Count")
            } footer: {
                Text("Fraction of working sets to use for warmup. For example, with 4 working sets and 1/2 selected, you'll have 2 warmup sets.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitle("Warmup Settings", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") { reset() }
                    .foregroundStyle(isDefault ? .gray : .red)
                    .disabled(isDefault)
            }
        }
    }
    
    private var isDefault: Bool {
        userData.settings.warmupSettings == WarmupSettings()
    }
    
    private func reset() {
        minIntensity = 50
        maxIntensity = 75
        setCountModifier = .oneHalf
        userData.settings.warmupSettings = WarmupSettings()
    }
}

