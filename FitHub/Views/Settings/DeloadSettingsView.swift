//
//  DeloadSettingsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/17/25.
//

import SwiftUI

struct DeloadSettingsView: View {
    @ObservedObject var userData: UserData
    @State private var deloadIntensity: Int
    
    init(userData: UserData) {
        self.userData = userData
        _deloadIntensity = State(initialValue: userData.settings.deloadIntensity)
    }
    
    var body: some View {
        List {
            // ── AUTO DELOAD ────────────────────────────────────────────────
            Section {
                Toggle("Auto-Deloading", isOn: $userData.settings.allowDeloading)
            } footer: {
                Text("When Auto-Deload is on, the trainer will inject a lighter “deload” week into your plan whenever your progress stalls.")
            }
            
            // ── DELOAD INTENSITY % ────────────────────────────────────────
            Section {
                HStack {
                    Text("\(deloadIntensity)%")
                        .monospacedDigit()
                    Slider(
                        value: Binding(
                            get: { Double(deloadIntensity) },
                            set: { newValue in
                                deloadIntensity = Int(newValue)
                                userData.settings.deloadIntensity = Int(newValue)
                            }
                        ),
                        in: 1...100,
                        step: 1
                    )
                    .accessibilityValue("\(deloadIntensity) percent")
                }
            } header: {
                Text("Deload Intensity")
            } footer: {
                Text("Fraction of your usual training load to apply in a deload week; all working-set weights are multiplied by this value.")
            }
            
            // ── PERIOD UNTIL DELOAD ───────────────────────────────────────
            Section {
                Stepper(
                    "\(userData.settings.periodUntilDeload) weeks",
                    value: $userData.settings.periodUntilDeload,
                    in: 2...12
                )
            } header: {
                Text("Stall Window")
            } footer: {
                Text("Number of consecutive weeks without progress before a deload week is automatically scheduled.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitle("Volume Deload", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") { reset() }
                    .foregroundStyle(isDefault ? .gray : .red)
                    .disabled(isDefault)
            }
        }
    }
    
    private func reset() {
        userData.settings.allowDeloading = true
        userData.settings.periodUntilDeload = 4
        userData.settings.deloadIntensity = 85
        deloadIntensity = 85
    }
    
    private var isDefault: Bool {
        return userData.settings.allowDeloading
        && userData.settings.periodUntilDeload == 4
        && userData.settings.deloadIntensity == 85
    }
}


