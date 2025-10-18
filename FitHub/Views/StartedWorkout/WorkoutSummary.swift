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

            // Use precomputed per-exercise totals from summary
            BarChartView(
                exercises: exercises,
                prExerciseIDs: summary.exercisePRs,
                weightByExercise: summary.weightByExercise
            )

            VStack(spacing: 20) {
                StatRow(title: "Total Weight Lifted", text: summary.totalVolume.formattedText())
                StatRow(title: "Total Reps Completed", value: "\(summary.totalReps)")
                StatRow(title: "Time Elapsed", value: summary.totalTime.displayString)
            }
            .padding()

            RectangularButton(title: "Close", bgColor: .blue, action: onDone)
                .padding()

        }
        .cardContainer(cornerRadius: 20, shadowRadius: 5, backgroundColor: Color(.secondarySystemBackground))
        .opacity(0.8)
    }

    private struct BarChartView: View {
        let exercises: [Exercise]
        let prExerciseIDs: [UUID]
        let weightByExercise: [UUID: Double]

        private var totalWeights: [Double] {
            exercises.map { ex in
                let v = weightByExercise[ex.id] ?? 0
                return Mass(kg: v).displayValue
            }
        }

        private var shortenedExerciseNames: [String] {
            let wordFrequencies = exercises
                .flatMap { $0.name.split(separator: " ") }
                .reduce(into: [String: Int]()) { counts, word in
                    counts[String(word), default: 0] += 1
                }

            return exercises.map { exercise in
                let words = exercise.name.split(separator: " ").map(String.init)
                let unique = words.filter { wordFrequencies[$0] == 1 }
                return unique.isEmpty ? exercise.name : unique.joined(separator: " ")
            }
        }

        private var maxY: Double {
            let maxWeight = totalWeights.max() ?? 0
            return maxWeight + (maxWeight * 0.1) // 10% headroom
        }

        var body: some View {
            VStack {
                Text("Total Weight Lifted per Exercise")
                    .font(.headline)

                Chart {
                    ForEach(exercises.indices, id: \.self) { index in
                        let exercise = exercises[index]
                        let totalWeight = totalWeights[index]

                        let isShortBar = totalWeight < maxY * 0.30
                        let annotationPosition: AnnotationPosition = isShortBar ? .top : .overlay
                        let annotationAlignment: Alignment = isShortBar ? .bottom : .top

                        BarMark(
                            x: .value("Exercise", shortenedExerciseNames[index]),
                            y: .value("Total Weight", totalWeight)
                        )
                        .annotation(position: annotationPosition, alignment: annotationAlignment) {
                            if prExerciseIDs.contains(exercise.id) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(Color.gold)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...maxY)
                .frame(height: UIScreen.main.bounds.width * 0.33)
            }
            .padding()
        }
    }

    private struct StatRow: View {
        let title: String
        var value: String?
        var text: Text?

        var body: some View {
            HStack {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Spacer()
                if let value = value {
                    Text(value).font(.subheadline)
                } else if let text = text {
                    text.font(.subheadline)
                }
            }
            .padding(.horizontal)
        }
    }
}
