//
//  RingView.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/6/25.
//

import SwiftUI

struct RingView: View {
    let kcal: Double
    let carbs: Double
    let fats: Double
    let proteins: Double
    
    var body: some View {
        let height = screenHeight
        
        VStack {
            ZStack {
                if carbs == 0 && fats == 0 && proteins == 0 {
                    Circle()
                        .stroke(Color.gray, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    
                    kcalLabel
                } else {
                    Circle()
                        .trim(from: 0, to: CGFloat(carbsRatio))
                        .stroke(Color.blue, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: CGFloat(carbsRatio), to: CGFloat(carbsRatio + fatsRatio))
                        .stroke(Color.yellow, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: CGFloat(carbsRatio + fatsRatio), to: 1)
                        .stroke(Color.red, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    
                    kcalLabel
                }
            }
            .frame(height: height * 0.25)
            
            HStack {
                legendLabel(label: "Carbs", color: .blue)
                legendLabel(label: "Fats", color: .yellow)
                legendLabel(label: "Proteins", color: .red)
            }
            .padding(.top, 10)
        }
    }

    private var kcalLabel: some View {
        VStack {
            Text(kcal <= 0 ? "N/A" : "\(Int(kcal))")
                .font(.title)
                .fontWeight(.bold)
            Text("kcal")
                .font(.subheadline)
        }
    }
    
    private func legendLabel(label: String, color: Color) -> some View {
        let size = screenWidth * 0.05
        
        return VStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            Text(label)
                .font(.caption)
        }
    }
    
    private var carbsCalories: Double { return carbs * 4 }
    private var fatsCalories: Double { return fats * 9 }
    private var proteinsCalories: Double { return proteins * 4 }
    private var carbsRatio: Double { return carbsCalories / kcal }
    private var fatsRatio: Double { return fatsCalories / kcal }
    private var proteinsRatio: Double { return proteinsCalories / kcal }
}
