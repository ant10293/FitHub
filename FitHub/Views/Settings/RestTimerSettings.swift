//
//  RestTimerSettings.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct RestTimerSettings: View {
    @ObservedObject var userData: UserData
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    let initialRestPeriod: Int
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        
        let totalSeconds = userData.workoutPrefs.customRestPeriod ?? FitnessGoal.determineRestPeriod(for: userData.physical.goal)
        _hours = State(initialValue: totalSeconds / 3600)
        _minutes = State(initialValue: (totalSeconds % 3600) / 60)
        _seconds = State(initialValue: totalSeconds % 60)
        initialRestPeriod = totalSeconds
    }
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $userData.settings.restTimerEnabled) {
                    Text("Rest Timer")
                }
                .padding(.horizontal)
                .onChange(of: userData.settings.restTimerEnabled) { 
                    userData.saveSingleStructToFile(\.settings, for: .settings)
                }
            }
            
            if userData.settings.restTimerEnabled {
                VStack {
                    Text("Rest Period")
                        .font(.headline)
                    RestPicker(minutes: $minutes, seconds: $seconds, frameWidth: 120)
                    .onChange(of: minutes) {
                        updateRestPeriod()
                    }
                    .onChange(of: seconds) {
                        updateRestPeriod()
                    }
                }
                .centerHorizontally()
            }
        }
        .navigationBarTitle("Rest Timer Settings", displayMode: .inline)
        .onDisappear {
            // save if needed
            if initialRestPeriod != userData.workoutPrefs.customRestPeriod {
                userData.saveSingleStructToFile(\.settings, for: .settings)
            }
        }
    }
    
    private func updateRestPeriod() {
        let totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        userData.workoutPrefs.customRestPeriod = totalSeconds
    }
}
