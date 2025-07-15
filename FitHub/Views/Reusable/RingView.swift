//
//  RingView.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/6/25.
//

import SwiftUI

struct RingView: View {
    var dailyCaloricIntake: Double
    var carbs: Double
    var fats: Double
    var proteins: Double
    
    var body: some View {
        VStack {
            ZStack {
                //    if dailyCaloricIntake == 0 {
                if carbs == 0 && fats == 0 && proteins == 0 {
                    Circle()
                        .stroke(Color.gray, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    VStack {
                        if dailyCaloricIntake == 0 {
                            //Text("0")
                            Text("N/A")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        else {
                            Text("\(Int(dailyCaloricIntake))")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("kcal")
                                .font(.subheadline)
                        }
                    }
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
                    VStack {
                        Text("\(Int(dailyCaloricIntake))")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("kcal")
                            .font(.subheadline)
                    }
                }
            }
            .frame(width: 200, height: 200)
            
            HStack {
                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                    Text("Carbs")
                        .font(.caption)
                }
                VStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 20, height: 20)
                    Text("Fats")
                        .font(.caption)
                }
                VStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    Text("Proteins")
                        .font(.caption)
                }
            }
            .padding(.top, 10)
        }
    }
    private var carbsCalories: Double { return carbs * 4 }
    private var fatsCalories: Double { return fats * 9 }
    private var proteinsCalories: Double { return proteins * 4 }
    private var carbsRatio: Double { return carbsCalories / dailyCaloricIntake }
    private var fatsRatio: Double { return fatsCalories / dailyCaloricIntake }
    private var proteinsRatio: Double { return proteinsCalories / dailyCaloricIntake }
}
