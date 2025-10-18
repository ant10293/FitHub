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
        // TODO: add other settings + describe what each does
        card {
            Toggle("Hide RPE slider", isOn: $userData.settings.hideRpeSlider)
                .padding()
        }
        .padding(.horizontal)
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
    }
    
    func resetAll() {
        userData.settings.hideRpeSlider = false
    }
}

