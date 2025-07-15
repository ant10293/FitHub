//
//  OverloadStyle.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct OverloadSettings: View {
    @ObservedObject var userData: UserData
        
    var body: some View {
        List {
            Section {
                Toggle("Progressive Overload", isOn: $userData.settings.progressiveOverload)
                .onChange(of: userData.settings.progressiveOverload) {
                    userData.saveSingleStructToFile(\.settings, for: .settings)
                }
            } footer: {
                Text("When enabled, trainer templates will be automatically updated weekly based on your performance.")
            }
            
            Section {
                Picker("Style", selection: $userData.settings.progressiveOverloadStyle) {
                    ForEach(ProgressiveOverloadStyle.allCases, id: \.self) { style in
                        Text(style.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: userData.settings.progressiveOverloadStyle) { oldValue, newValue in
                    if oldValue != newValue {
                        userData.saveSingleStructToFile(\.settings, for: .settings)
                    }
                }
            } header: {
                Text("Overload Style")
            } footer: {
                Text(userData.settings.progressiveOverloadStyle.desc)
            }
            
            Section {
                Stepper("\(userData.settings.progressiveOverloadPeriod) weeks", value: $userData.settings.progressiveOverloadPeriod, in: 1...12)
                .onChange(of: userData.settings.progressiveOverloadPeriod) {
                    userData.saveSingleStructToFile(\.settings, for: .settings)
                }
            } header: {
                Text("Overload Period")
            } footer: {
                Text("The typical period is 6 weeks, but you can adjust it based on your preference.")
            }
            
            Section {
                Stepper("\(userData.settings.stagnationPeriod) weeks", value: $userData.settings.stagnationPeriod, in: 1...12)
                .onChange(of: userData.settings.stagnationPeriod) {
                    userData.saveSingleStructToFile(\.settings, for: .settings)
                }
            } header: {
                Text("Stagnation Duration")
            } footer: {
                Text("Duration without improvement for an exercise until forced overloading begins.")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Progressive Overload", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { reset() }) {
                    Text("Reset")
                        .foregroundColor(isDefault() ? Color.gray : Color.red)        // make the label red
                        .disabled(isDefault())
                }
            }
        }
    }
    
    private func reset() {
        userData.settings.progressiveOverload = true
        userData.settings.progressiveOverloadStyle = .dynamic
        userData.settings.progressiveOverloadPeriod = 6
        userData.settings.stagnationPeriod = 4
    }
    
    private func isDefault() -> Bool {
        return userData.settings.progressiveOverloadStyle == .dynamic
        && userData.settings.progressiveOverload
        && userData.settings.progressiveOverloadPeriod == 6
        && userData.settings.stagnationPeriod == 4
    }
}
