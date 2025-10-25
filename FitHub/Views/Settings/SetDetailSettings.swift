//
//  SetDetailSettings.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/8/25.
//

import SwiftUI

struct SetDetailSettings: View {
    @ObservedObject var userData: UserData
    
    var body: some View {
        List {
            Section {
                Toggle("Hide RPE slider", isOn: $userData.settings.hideRpeSlider)
            } footer: {
                Text("Removes the RPE control from Set Detail so you’re not prompted to rate effort during/after sets.")
            }
            
            Section {
                Toggle("Hide Completed Input", isOn: $userData.settings.hideCompletedInput)
            } footer: {
                Text("Hides the “Completed” fields (reps, time). When a set is marked finished, its completed values will automatically match the planned ones.")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("SetDetail Settings", displayMode: .inline)
        .toolbar {
             ToolbarItem(placement: .topBarTrailing) {
                 Button("Reset") { resetAll() }
                     .foregroundStyle(isDefault ? Color.gray : Color.red)        // make the label red
                     .disabled(isDefault)       // disable when no items
             }
         }
    }
    
    var isDefault: Bool {
        userData.settings.hideRpeSlider == false
        && userData.settings.hideCompletedInput == false
    }
    
    func resetAll() {
        userData.settings.hideRpeSlider = false
        userData.settings.hideCompletedInput = false
    }
}

