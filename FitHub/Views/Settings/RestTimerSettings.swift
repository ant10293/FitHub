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
        ScrollView {
            VStack(spacing: 12) {
                // Master toggle
                card {
                    HStack {
                        Text("Rest Timer").font(.headline)
                        Spacer()
                        Toggle("", isOn: $userData.settings.restTimerEnabled)
                            .labelsHidden()
                            .onChange(of: userData.settings.restTimerEnabled) {
                                userData.saveSingleStructToFile(\.settings, for: .settings)
                            }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .padding()
                
                if userData.settings.restTimerEnabled {
                    // One collapsible row per RestType
                    VStack(spacing: 10) {
                        ForEach(RestType.allCases) { kind in
                            restRow(kind: kind)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationBarTitle("Rest Timer Settings", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    reset()
                }
                .foregroundStyle(.red)
            }
        }
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
    }
    
    func onAppear() {
        initialCustom = userData.workoutPrefs.customRestPeriods
        if let open = activeEditor { loadPicker(from: open) }
    }
    
    func onDisappear() {
        if initialCustom != userData.workoutPrefs.customRestPeriods {
            userData.saveSingleStructToFile(\.workoutPrefs, for: .workoutPrefs)
        }
    }
    
    func reset() {
        userData.settings.restTimerEnabled = true
        userData.workoutPrefs.customRestPeriods = nil
        if let open = activeEditor { loadPicker(from: open) }
        userData.saveToFile()
    }
    
    func restRow(kind: RestType) -> some View {
        card {
            VStack(spacing: 0) {
                // Header (collapsed summary)
                Button {
                    toggleEditor(kind)
                } label: {
                    VStack {
                        HStack {
                            Text(kind.rawValue).font(.headline)
                            Spacer()
                            Text(Format.timeString(from: resolved.rest(for: kind)))
                                .foregroundStyle(.gray)
                                .monospacedDigit()
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(activeEditor == kind ? 90 : 0))
                                .animation(.easeInOut(duration: 0.15), value: activeEditor == kind)
                        }
                        Text(kind.note)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .frame(alignment: .leading)
                    }
                    .padding()
                }
                .contentShape(Rectangle())
                
                // Disclosure editor
                if activeEditor == kind {
                    VStack(spacing: 10) {
                        MinSecPicker(time: $editTime)
                            .onChange(of: editTime) { savePicker(into: kind) }
                        
                        HStack {
                            Spacer()
                            FloatingButton(
                                image: "checkmark",
                                action: { activeEditor = nil }
                            )
                            .padding(.trailing)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .padding(.horizontal)
    }
    
    var resolved: RestPeriods {
        userData.workoutPrefs.customRestPeriods ?? userData.physical.goal.defaultRest
    }
    
    func toggleEditor(_ kind: RestType) {
        if activeEditor == kind {
            activeEditor = nil
        } else {
            activeEditor = kind
            loadPicker(from: kind)
        }
    }
    
    func loadPicker(from kind: RestType) {
        let total = max(0, resolved.rest(for: kind)) // seconds
        editTime = TimeSpan(seconds: total)
    }
    
    func savePicker(into kind: RestType) {
        var custom = resolved
        custom.modify(for: kind, with: editTime.inSeconds)
        userData.workoutPrefs.customRestPeriods = custom
    }
}
