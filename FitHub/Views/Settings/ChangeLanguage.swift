//
//  ChangeLanguage.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ChangeLanguage: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack {
            
            Picker("Language", selection: $userData.userLanguage) {
                ForEach(Languages.allCases, id: \.self) { language in
                    Text(language.rawValue).tag(language)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
        .navigationTitle("Change Language").navigationBarTitleDisplayMode(.inline)
    }
}
