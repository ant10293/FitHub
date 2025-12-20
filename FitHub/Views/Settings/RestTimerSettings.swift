//
//  RestTimerSettings.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct RestTimerSettings: View {
    @ObservedObject var userData: UserData
    @State private var activeEditor: RestType? = nil
    @State private var editTime: TimeSpan = .init(seconds: 0)
    @State private var initialCustom: RestPeriods?

    var body: some View {
        List {
            Section {
                Toggle("Rest Timer", isOn: $userData.settings.restTimerEnabled)
            } footer: {
                Text("Enable rest timer during workouts.")
            }

            if userData.settings.restTimerEnabled {
                ForEach(RestType.allCases) { kind in
                    restRow(kind: kind)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitle("Rest Timer Settings", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    reset()
                }
                .foregroundStyle(isDefault ? Color.gray : Color.red)
                .disabled(isDefault)
            }
        }
        .onAppear(perform: onAppear)
    }

    private func restRow(kind: RestType) -> some View {
        Section {
            CustomDisclosure(
                title: kind.rawValue,
                note: kind.note,
                isActive: activeEditor == kind,
                usePadding: false,
                onTap: { toggleEditor(kind) },
                onClose: { activeEditor = nil },
                valueView: {
                    Text(Format.timeString(from: resolved.rest(for: kind)))
                        .foregroundStyle(.gray)
                        .monospacedDigit()
                },
                content: {
                    MinSecPicker(time: $editTime)
                        .onChange(of: editTime) {
                            savePicker(into: kind)
                        }
                }
            )
        }
    }

    private var isDefault: Bool {
        userData.workoutPrefs.customRestPeriods == nil
        && userData.settings.restTimerEnabled == true
    }

    private func onAppear() {
        initialCustom = userData.workoutPrefs.customRestPeriods
        if let open = activeEditor { loadPicker(from: open) }
    }

    private func reset() {
        userData.settings.restTimerEnabled = true
        userData.workoutPrefs.customRestPeriods = nil
        if let open = activeEditor { loadPicker(from: open) }
    }

    private var resolved: RestPeriods {
        userData.workoutPrefs.customRestPeriods ?? defaultRest
    }

    private var defaultRest: RestPeriods {
       userData.physical.goal.defaultRest
    }

    private func toggleEditor(_ kind: RestType) {
        if activeEditor == kind {
            activeEditor = nil
        } else {
            activeEditor = kind
            loadPicker(from: kind)
        }
    }

    private func loadPicker(from kind: RestType) {
        let total = max(0, resolved.rest(for: kind)) // seconds
        editTime = TimeSpan(seconds: total)
    }

    private func savePicker(into kind: RestType) {
        var custom = resolved
        custom.modify(for: kind, with: editTime.inSeconds)
        if custom == defaultRest {
            userData.workoutPrefs.customRestPeriods = nil
        } else {
            userData.workoutPrefs.customRestPeriods = custom
        }
    }
}
