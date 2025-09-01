//
//  MuscleRest.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct MuscleRest: View {
    @ObservedObject var userData: UserData
        
    var body: some View {
        VStack {
            Stepper("Rest Duration: \(userData.settings.muscleRestDuration) hours", value: $userData.settings.muscleRestDuration, in: 24...168)
                .onChange(of: userData.settings.muscleRestDuration) {
                    userData.saveSingleStructToFile(\.settings, for: .settings)
                }
                .padding()
            
            Text("The typical rest duration is 48 hours, but you can adjust it to suit your recovery needs.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.top)
        }
        .padding()
        .navigationBarTitle("Muscle Rest Duration", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    userData.settings.muscleRestDuration = 48
                }) {
                    Text("Reset")
                        .foregroundStyle(isDefault ? Color.gray : Color.red)        // make the label red
                        .disabled(isDefault)
                }
            }
        }
    }
    
    private var isDefault: Bool { userData.settings.muscleRestDuration == 48 }
}
