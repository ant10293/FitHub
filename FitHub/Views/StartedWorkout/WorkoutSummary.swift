//
//  WorkoutSummary.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/19/24.
//

import SwiftUI
import Charts

struct WorkoutSummary: View {
    let totalVolume: Double
    let totalWeight: Double
    let totalReps: Int
    let totalTime: String
    let exercisePRs: [String]
    let exercises: [Exercise] // Add exercises to the view
    let onDone: () -> Void

    var body: some View {
        VStack {
            Text("Workout Summary")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Pass exercises to the BarChartView
            BarChartView(exercises: exercises, prExerciseNames: exercisePRs)
            
            /*if numPRs > 0 {
                HStack {
                    Text("\(numPRs) \("PR")\(numPRs > 1 ? "s" : "")")
                        .bold()
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color.yellow)
                }
            }*/
            
            VStack(spacing: 20) {
                StatRow(title: "Total Weight Lifted", value: String(format: "%.2f", totalVolume).trimmingCharacters(in: CharacterSet(charactersIn: "0")).trimmingCharacters(in: CharacterSet(charactersIn: ".")) + " lbs")
                StatRow(title: "Total Reps Completed", value: "\(totalReps)")
                StatRow(title: "Time Elapsed", value: totalTime)
            }
            .padding()
            
            Button(action: {
                onDone()
            }) {
                Text("Done")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom)
            
        }
        .background(Color(.systemBackground).opacity(0.95))
        .cornerRadius(20)
        .padding()
        .shadow(radius: 5)
    }
}

struct BarChartView: View {
    let exercises: [Exercise]
    let prExerciseNames: [String] // List of exercise names that had a PR

    // Compute the total weight lifted for each exercise
    var totalWeights: [Double] {
        exercises.map { exercise in
            exercise.setDetails.reduce(0) { total, set in
                total + (set.weight * Double(set.reps))
            }
        }
    }
    // Compute shortened names by extracting unique words
    var shortenedExerciseNames: [String] {
        let wordFrequencies = exercises
            .flatMap { $0.name.split(separator: " ") }
            .reduce(into: [String: Int]()) { counts, word in
                counts[String(word), default: 0] += 1
            }
        
        return exercises.map { exercise in
            let words = exercise.name.split(separator: " ").map(String.init)
            let uniqueWords = words.filter { wordFrequencies[$0] == 1 }
            return uniqueWords.isEmpty ? exercise.name : uniqueWords.joined(separator: " ")
        }
    }
    
    var maxY: Double {
        let maxWeight = totalWeights.max() ?? 0
        return maxWeight + (maxWeight * 0.1) // 10% padding on max weight
    }
    
    var body: some View {
        VStack {
            Text("Total Weight Lifted per Exercise")
                .font(.headline)
            
            // Plot the total weight lifted for each exercise
            Chart {
                ForEach(exercises.indices, id: \.self) { index in
                    let exercise = exercises[index]
                    let totalWeight = totalWeights[index]
                    let annotationPosition: AnnotationPosition = exercise.usesWeight ? .overlay : .top  // Change the second case if needed.
                    let annotationAlignment: Alignment = exercise.usesWeight ? .top : .top  // Change the second case as desired.

                    BarMark(
                        x: .value("Exercise", shortenedExerciseNames[index]), // Use shortened names
                        
                        y: .value("Total Weight", totalWeight)
                    )
                    .annotation(position: annotationPosition, alignment: annotationAlignment) {
                       if prExerciseNames.contains(exercise.name) {
                           Image(systemName: "trophy.fill")
                               .foregroundColor(.yellow)
                       }
                   }
                }
            }
            .chartYScale(domain: 0...maxY) // Adjust the y-axis scale dynamically
            .frame(height: 150)
        }
        .padding()
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.horizontal)
    }
}
