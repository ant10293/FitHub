//
//  ChangeTheme.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ChangeTheme: View {
    @ObservedObject var userData: UserData
    
    var body: some View {
        VStack {
            Picker("Theme", selection: $userData.settings.selectedTheme) {
                ForEach(Themes.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Text("Default mode will follow the device's theme settings.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.top)
        }
        .padding()
        .navigationBarTitle("Change Theme", displayMode: .inline)
    }
}
