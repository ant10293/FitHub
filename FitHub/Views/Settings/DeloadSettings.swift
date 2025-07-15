//
//  DeloadSettings.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/17/25.
//

import SwiftUI


struct DeloadSettings: View {
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
                Text("When Auto-Deload is on, the trainer will inject a lighter “deload” week into your plan whenever your progress stalls and effort (RPE) keeps climbing.")
            }
            
            // ── DELOAD INTENSITY % ────────────────────────────────────────
            Section {
                HStack {
                    Text("\(deloadIntensity)%")
                    Slider(
                        value: Binding(
                            get: { Double(deloadIntensity) },
                            set: { deloadIntensity = Int($0) }
                        ),
                        in: 1...100,
                        step: 1
                    )
                    .accessibilityValue("\(deloadIntensity) percent")
                    .onChange(of: deloadIntensity) { old, new in
                        if old != new {
                            userData.settings.deloadIntensity = new
                        }
                    }
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
                    in: 1...8
                )
            } header: {
                Text("Stall Window")
            } footer: {
                Text("Number of consecutive weeks without progress—while RPE keeps rising—before a deload week is automatically scheduled.")
            }
        }
        .onChange(of: userData.settings) { old, new in
            if old != new {
                userData.saveSingleStructToFile(\.settings, for: .settings)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Progressive Overload")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") { reset() }
                    .foregroundColor(isDefault() ? .gray : .red)
                    .disabled(isDefault())
            }
        }
    }
    
    private func reset() {
        userData.settings.allowDeloading = true
        userData.settings.periodUntilDeload = 2
        userData.settings.deloadIntensity = 85
        deloadIntensity = 85
    }
    
    private func isDefault() -> Bool {
        return userData.settings.allowDeloading
        && userData.settings.periodUntilDeload == 2
        && userData.settings.deloadIntensity == 85
    }
}


