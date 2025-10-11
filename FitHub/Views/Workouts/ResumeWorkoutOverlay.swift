//
//  ResumeWorkoutOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/5/25.
//

import SwiftUI

struct ResumeWorkoutOverlay: View {
    let cancel: () -> Void
    let resume: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Text("You still have a workout in progress.")
                    .font(.title2)
                    .padding(.bottom, 10)
                    .multilineTextAlignment(.center)
                Text("Would you like to resume this workout?")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                HStack {
                    RectangularButton(title: "Cancel", bgColor: .red, action: cancel)
                    RectangularButton(title: "Resume", bgColor: .blue, action: resume)
                }
                .padding(.top, 10)
            }
            .cardContainer(cornerRadius: 10, shadowRadius: 10)
            .frame(width: UIScreen.main.bounds.width * 0.8)
            
            Spacer()
        }
    }
}


