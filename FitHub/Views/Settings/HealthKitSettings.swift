//
//  HealthKit.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct HealthKitSettings: View {
    @ObservedObject var healthKitManager: HealthKitManager // Pass the instance of HealthKitManager
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Button(action: {
                    //healthKitManager.requestAuthorization()
                }) {
                    Text("Initialize HealthKit")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("HealthKit Settings").navigationBarTitleDisplayMode(.inline)
        }
    }
}
