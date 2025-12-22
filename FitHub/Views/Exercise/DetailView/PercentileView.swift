//
//  PercentileView.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/3/25.
//

import SwiftUI

struct PercentileView: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var selectedView: ViewOption = .standards
    let exercise: Exercise

    var body: some View {
        let maxValue = ctx.exercises.peakMetric(for: exercise.id) ?? exercise.getPeakMetric(metricValue: 0)
        let bw = Mass(kg: ctx.userData.currentMeasurementValue(for: .weight).actualValue)

        VStack {
            switch selectedView {
            case .standards:
                StrengthPercentileView(
                    maxValue: maxValue,
                    age: ctx.userData.profile.age,
                    bodyweight: bw,
                    gender: ctx.userData.physical.gender,
                    exercise: exercise,
                    maxValuesAge: CSVLoader.getMaxValues(for: exercise, key: .age, value: Double(ctx.userData.profile.age), userData: ctx.userData),
                    maxValuesBW: CSVLoader.getMaxValues(for: exercise, key: .bodyweight, value: bw.inKg, userData: ctx.userData),
                    percentile: CSVLoader.calculateExercisePercentile(for: exercise, maxValue: maxValue.actualValue, userData: ctx.userData)
                )

            case .percentages:
                Text("\(exercise.performanceTitle(includeInstruction: false)) Percentages")
                    .font(.title2)
                    .padding(.vertical)

                Text(maxValue.percentileHeader)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding([.bottom, .horizontal])

                MaxTable(peak: maxValue)
                    .padding(.vertical)
            }

            Picker("Options", selection: $selectedView) {
                ForEach(ViewOption.allCases) { v in
                    Text(v.rawValue).tag(v)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
        .observesUnitSystem()
    }

    private enum ViewOption: String, CaseIterable, Identifiable {
        case standards = "Standards"
        case percentages = "Percentages"

        var id: String { self.rawValue }
    }
}
