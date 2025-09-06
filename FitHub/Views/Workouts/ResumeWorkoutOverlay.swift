//
//  ResumeWorkoutOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/5/25.
//

import SwiftUI

struct ResumeWorkoutOverlay: View {
    var cancel: () -> Void
    var resume: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("You still have a workout in progress.")
                    .font(.title2)
                    .padding(.bottom, 10)
                Text("Would you like to resume this workout?")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                
                HStack {
                    Button(action: cancel) {
                        Text("Cancel")
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(action: resume) {
                        Text("Resume")
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}


