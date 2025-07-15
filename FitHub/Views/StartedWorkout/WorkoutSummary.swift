//
//  WorkoutSummary.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/19/24.
//

import SwiftUI
import Charts


struct WorkoutSummary: View {
    let summary: WorkoutSummaryData
    let exercises: [Exercise]
    let onDone: () -> Void

    var body: some View {
        VStack {
            Text("Workout Summary")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Pass exercises to the BarChartView
            BarChartView(exercises: exercises, prExerciseNames: summary.exercisePRs)
            
            VStack(spacing: 20) {
                StatRow(title: "Total Weight Lifted", value: String(format: "%.2f", summary.totalVolume).trimmingCharacters(in: CharacterSet(charactersIn: "0")).trimmingCharacters(in: CharacterSet(charactersIn: ".")) + " lbs")
                StatRow(title: "Total Reps Completed", value: "\(summary.totalReps)")
                StatRow(title: "Time Elapsed", value: summary.totalTime)
            }
            .padding()
            
            ActionButton(title: "Done", color: .blue, action: onDone)
                .padding()
            
        }
        .background(Color(.systemBackground).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding()
        .shadow(radius: 5)
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
                        
                        let isShortBar    = totalWeight < maxY * 0.30     // 30 % threshold
                        let annotationPosition : AnnotationPosition = isShortBar ? .top     : .overlay
                        let annotationAlignment : Alignment = isShortBar ? .bottom  : .top

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
}




