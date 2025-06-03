//
//  MuscleRest.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct MuscleRest: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack {
            Stepper("Rest Duration: \(userData.muscleRestDuration) hours", value: $userData.muscleRestDuration, in: 24...168)
                .onChange(of: userData.muscleRestDuration) {
                    userData.saveSingleVariableToFile(\.muscleRestDuration, for: .muscleRestDuration)
                }
                .padding()
            
            Text("The typical rest duration is 48 hours, but you can adjust it to suit your recovery needs.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .padding()
        .navigationTitle("Muscle Rest Duration").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    userData.muscleRestDuration = 48
                }) {
                    Text("Reset")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
