//
//  WeekView.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/5/25.
//

import SwiftUI

struct WeekView: View {
    @ObservedObject var userData: UserData
    @Binding var selectedTemplate: SelectedTemplate?

    var body: some View {
        VStack(alignment: .leading) {
            Text("This Week's Workouts")
                .font(.headline)
                .padding(.leading)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: screenHeight * 0.25)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(WeekWorkout(userData: userData, selectedTemplate: $selectedTemplate))
                .padding(.horizontal)
                .overlay(alignment: .bottom) {
                    weekLegend
                }
        }
    }

    private var weekLegend: some View {
        HStack(spacing: 15) {
            LegendItem(color: .blue, label: "Planned")
            LegendItem(color: .green, label: "Completed")
            LegendItem(color: .red, label: "Missed")
        }
        .padding()
    }

    private struct LegendItem: View {
        var color: Color
        var label: String

        var body: some View {
            let size = screenWidth * 0.03

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: size, height: size)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.primary)
            }
        }
    }
}
