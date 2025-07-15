//
//  ChangeLanguage.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ChangeLanguage: View {
    @ObservedObject var userData: UserData
    
    var body: some View {
        VStack {
            
            Picker("Language", selection: $userData.settings.userLanguage) {
                ForEach(Languages.allCases, id: \.self) { language in
                    Text(language.rawValue).tag(language)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
        .navigationBarTitle("Change Language", displayMode: .inline)
    }
}
