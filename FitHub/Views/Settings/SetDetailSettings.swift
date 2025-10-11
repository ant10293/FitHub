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
    }
}

