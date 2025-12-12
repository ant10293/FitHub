//
//  BMICategoryTable.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/4/25.
//

import SwiftUI

struct BMICategoryTable: View {
    let userBMI: Double

    // Define BMI categories, ranges, and colors
    let categories: [(name: String, displayRange: String, color: Color)] = [
        ("Underweight", "<18.5", .blue),
        ("Normal Weight", "18.5 - 24.9", .green),
        ("Overweight\n", "25.0 - 29.9", .yellow),
        ("Obese\n", "30.0 - 34.9", .orange),
        ("Extremely Obese", "35<", .red)
    ]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(categories, id: \.name) { category in
                    VStack {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)

                        Text(category.displayRange)
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: geometry.size.width / CGFloat(categories.count), height: geometry.size.height)
                    .background(category.color)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                GeometryReader { innerGeometry in
                    let categoryIndex = getBMICategoryIndex()
                    let columnWidth = innerGeometry.size.width / CGFloat(categories.count)

                    // Gray overlay for user's category
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: columnWidth + 5, height: innerGeometry.size.height + 5)
                        .position(x: columnWidth * (CGFloat(categoryIndex) + 0.5), y: innerGeometry.size.height / 2)
                }
            )
        }
    }
    // Function to determine which BMI category the user belongs to
    private func getBMICategoryIndex() -> Int {
        if userBMI < 18.5 {
            return 0 // Underweight
        } else if userBMI < 25.0 {
            return 1 // Normal Weight
        } else if userBMI < 30.0 {
            return 2 // Overweight
        } else if userBMI < 35.0 {
            return 3 // Obese
        } else {
            return 4 // Extremely Obese
        }
    }
}
