//
//  OverloadStyle.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct OverloadStyle: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List {
            
            Section {
                Toggle("Enable Progressive Overload", isOn: $userData.progressiveOverload)
                    .onChange(of: userData.progressiveOverload) {
                        userData.saveSingleVariableToFile(\.progressiveOverload, for: .progressiveOverload)
                    }
             }
            
            Section(header: Text("Overload Style")) {
                Picker("Style", selection: $userData.progressiveOverloadStyle)
                {
                    ForEach(ProgressiveOverloadStyle.allCases, id: \.self) { style in
                        Text(style.rawValue)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil) // Ensure text can wrap to multiple lines
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: userData.progressiveOverloadStyle) { oldValue, newValue in
                    if oldValue != newValue {
                        userData.saveSingleVariableToFile(\.progressiveOverloadStyle, for: .progressiveOverloadStyle)
                    }
                }
                
                Text(userData.progressiveOverloadStyle.desc)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            
            Section(header: Text("Overload Period")) {
                Stepper("Weeks: \(userData.progressiveOverloadPeriod)", value: $userData.progressiveOverloadPeriod, in: 1...12)
                    .onChange(of: userData.progressiveOverloadPeriod) {
                        userData.saveSingleVariableToFile(\.progressiveOverloadPeriod, for: .progressiveOverloadPeriod)
                    }
                
                Text("The typical period is 4 weeks, but you can adjust it based on your preference.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Stagnation Duration")) {
                Stepper("Weeks: \(userData.stagnationPeriod)", value: $userData.stagnationPeriod, in: 1...12)
                    .onChange(of: userData.stagnationPeriod) {
                        userData.saveSingleVariableToFile(\.stagnationPeriod, for: .stagnationPeriod)
                    }
                
                Text("Duration without improvement for an exercise until forced overloading begins.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Progressive Overload").navigationBarTitleDisplayMode(.inline)
    }
}
