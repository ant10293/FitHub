//
//  WeekView.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/5/25.
//

import SwiftUI

struct WeekView: View {
    @ObservedObject var userData: UserData
    @State private var selectedTemplate: SelectedTemplate?

    var body: some View {
        VStack(alignment: .leading) {
            Text("This Week's Workouts")
                .font(.headline)
                .padding(.leading)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(WeekWorkout(userData: userData, selectedTemplate: $selectedTemplate))
                .padding(.horizontal)
                .overlay(alignment: .center, content: {
                    WeekLegend()
                        .padding(.top, 150)
                })
        }
    }
}
