//
//  OverloadStyle.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct OverloadSettings: View {
    @ObservedObject var userData: UserData
    var fromCalculator: Bool = false
    
    var body: some View {
        List {
            if !fromCalculator {
                Section {
                    Toggle("Progressive Overload", isOn: $userData.settings.progressiveOverload)
                } footer: {
                    Text("When enabled, trainer templates will be automatically updated weekly based on your performance.")
                }
            }
            
            Section {
                Picker("Style", selection: $userData.settings.progressiveOverloadStyle) {
                    ForEach(ProgressiveOverloadStyle.allCases, id: \.self) { style in
                        Text(style.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            } header: {
                Text("Overload Style")
            } footer: {
                if let styleWarning {
                    WarningFooter(message: styleWarning)
                } else {
                    Text(userData.settings.progressiveOverloadStyle.desc)
                }
            }
            
            /*
             Section {
             let factor = Binding(
             get: {  userData.settings.customOverloadFactor ?? defaultFactor },
             set: { newFactor in
             userData.settings.customOverloadFactor = (newFactor == defaultFactor) ? nil : newFactor
             }
             )
             
             HStack {
             Text("\(intensityPercent)")
             Slider(value: factor, in: 0.5...1.5, step: 0.05)
             }
             
             } header: {
             Text("Overload Intensity")
             } footer: {
             Text("Scales how aggressive weekly changes are. Nil or 100% is baseline.")
             }
             */
            
            Section {
                Stepper("\(userData.settings.progressiveOverloadPeriod) weeks", value: $userData.settings.progressiveOverloadPeriod, in: 2...12)
            } header: {
                Text("Overload Period")
            } footer: {
                Text("The typical period is 6 weeks, but you can adjust it based on your preference.")
            }
            /*
            if !fromCalculator {
                Section {
                    Stepper("\(userData.settings.stagnationPeriod) weeks", value: $userData.settings.stagnationPeriod, in: 1...12)
                } header: {
                    Text("Stagnation Duration")
                } footer: {
                    Text("Duration without improvement for an exercise until forced overloading begins.")
                }
            }
            */
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Progressive Overload", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { reset() }) {
                    Text("Reset")
                        .foregroundStyle(isDefault ? Color.gray : Color.red)        // make the label red
                        .disabled(isDefault)
                }
            }
        }
    }
    
    private var intensityPercent: String {
        let raw = userData.settings.customOverloadFactor ?? 1.0
        let pct = Int((raw * 100).rounded())
        return "\(pct)%"
    }
   
    private var styleWarning: String? {
        let overloadStyle = userData.settings.progressiveOverloadStyle
        guard overloadStyle == .decreaseReps else { return nil }
        let rsDefault = RepsAndSets.defaultRepsAndSets(for: userData.physical.goal)
        let dist = userData.workoutPrefs.customDistribution ?? rsDefault.distribution
        let reps = userData.workoutPrefs.customRepsRange ?? rsDefault.reps
        let rs = RepsAndSets(reps: reps, sets: rsDefault.sets, rest: rsDefault.rest, distribution:  dist)
        let range = reps.overallRange(filteredBy: dist)
        
        let isIncompatible = ProgressiveOverloadStyle.incompatibleOverloadStyle(
            overloadStyle: overloadStyle,
            overloadPeriod: userData.settings.progressiveOverloadPeriod,
            rAndS: rs
        )
        if isIncompatible {
            return "Your current rep range of \(Format.formatRange(range: range)) will not allow this style. Consider increasing your rep range or decreasing the overload period."
        } else {
            return nil
        }
    }
    
    private func reset() {
        userData.settings.progressiveOverload = true
        userData.settings.progressiveOverloadStyle = .dynamic
        userData.settings.progressiveOverloadPeriod = 6
        //userData.settings.stagnationPeriod = 4
        userData.settings.customOverloadFactor = nil
    }
    
    private var isDefault: Bool {
        return userData.settings.progressiveOverloadStyle == .dynamic
        && userData.settings.progressiveOverload
        && userData.settings.progressiveOverloadPeriod == 6
        //&& userData.settings.stagnationPeriod == 4
        && userData.settings.customOverloadFactor == nil
    }
}
