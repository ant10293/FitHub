//
//  ChangeTheme.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct ChangeTheme: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack {
            
            Picker("Theme", selection: $userData.selectedTheme) {
                ForEach(Themes.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Text("Default mode will follow the device's theme settings.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .padding()
        .navigationTitle("Change Theme").navigationBarTitleDisplayMode(.inline)
    }
}
