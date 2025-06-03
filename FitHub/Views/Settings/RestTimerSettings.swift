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
    
    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        
        let totalSeconds = userData.customRestPeriod ?? FitnessGoal.determineRestPeriod(for: userData.goal) //userData.determineRestPeriod()
        _hours = State(initialValue: totalSeconds / 3600)
        _minutes = State(initialValue: (totalSeconds % 3600) / 60)
        _seconds = State(initialValue: totalSeconds % 60)
    }
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $userData.restTimerEnabled) {
                    Text("Rest Timer")
                }
                .padding(.horizontal)
                .onChange(of: userData.restTimerEnabled) { 
                    userData.saveSingleVariableToFile(\.restTimerEnabled, for: .restTimerEnabled)
                }
            }
            
            if userData.restTimerEnabled {
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
        .navigationTitle("Rest Timer Settings").navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            userData.saveSingleVariableToFile(\.customRestPeriod, for: .customRestPeriod)
        }
    }
    
    private func updateRestPeriod() {
        let totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        userData.customRestPeriod = totalSeconds
    }
}
