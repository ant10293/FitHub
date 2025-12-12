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
                .padding(.top)

            // Use precomputed per-exercise totals from summary
            BarChartView(
                exercises: exercises,
                prExerciseIDs: summary.exercisePRs,
                timeByExercise: summary.timeByExercise
            )

            VStack(spacing: 20) {
                StatRow(title: "Total Weight Lifted", text: summary.totalVolume.formattedText())
                StatRow(title: "Total Reps Completed", value: "\(summary.totalReps)")
                StatRow(title: "Time Elapsed", value: summary.totalTime.displayString)
            }
            //.padding()

            RectangularButton(title: "Close", bgColor: .blue, action: onDone)
                .padding()

        }
        .background(Color(.secondarySystemBackground))
        .opacity(0.8)
    }

    private struct BarChartView: View {
        let exercises: [Exercise]
        let prExerciseIDs: [UUID]
        let timeByExercise: [UUID: Int]

        private var maxSeconds: Int {
            exercises.compactMap { timeByExercise[$0.id] }.max() ?? 0
        }

        private var useSeconds: Bool { maxSeconds < 60 }

        private var chartData: [Double] {
            exercises.map { ex in
                let seconds = timeByExercise[ex.id] ?? 0
                return useSeconds ? Double(seconds) : Double(seconds) / 60.0
            }
        }

        private var exerciseLabels: [String] {
            exercises.indices.map { "\($0 + 1)" }
        }

        private var maxY: Double {
            let maxValue = chartData.max() ?? 0
            return maxValue + (maxValue * 0.1) // 10% headroom
        }

        var body: some View {
            VStack {
                Text("Time Spent per Exercise")
                    .font(.headline)

                Chart {
                    ForEach(exercises.indices, id: \.self) { index in
                        let exercise = exercises[index]
                        let timeValue = chartData[index]

                        let isShortBar = timeValue < maxY * 0.30
                        let annotationPosition: AnnotationPosition = isShortBar ? .top : .overlay
                        let annotationAlignment: Alignment = isShortBar ? .bottom : .top

                        BarMark(
                            x: .value("Exercise", exerciseLabels[index]),
                            y: .value(useSeconds ? "Time (sec)" : "Time (min)", timeValue)
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
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(useSeconds ? "\(Int(doubleValue))s" : "\(Int(doubleValue))m")
                            }
                        }
                    }
                }
                .frame(height: screenWidth * 0.33)

                // Show exercise names below chart with vertically aligned indexes
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: screenWidth * 0.04) {
                        ForEach(exercises.indices, id: \.self) { index in
                            VStack(spacing: screenWidth * 0.01) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(exercises[index].name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: screenWidth * 0.15, alignment: .top)
                        }
                    }
                    .padding(.horizontal)
                }
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
                Text(title).fontWeight(.semibold)
                Spacer()
                if let value = value {
                    Text(value)
                } else if let text = text {
                    text
                }
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
    }
}
