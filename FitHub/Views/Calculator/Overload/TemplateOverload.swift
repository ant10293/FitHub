//
//  TemplateOverload.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/19/25.
//
import SwiftUI

struct TemplateOverload: View {
    let processedExercises: [Exercise]
    let previousWeekExercises: [Exercise]?
    let templateName: String

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(templateName)
                        .font(.title2).fontWeight(.bold)
                        .padding(.bottom, 10)

                    if processedExercises.isEmpty {
                        HStack {
                            Spacer()
                            Text("No Exercises Available for this Template.")
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                        .cardContainer(cornerRadius: 10, backgroundColor: Color(UIColor.secondarySystemBackground))
                    } else {
                        ForEach(processedExercises) { exercise in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                // FIXME: change header labels (e.g. Load: Weight, Distance - Metric: Reps, Time, Speed)
                                // Headers (unchanged visuals)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 5) {
                                    Text("Set")
                                        .font(.caption).fontWeight(.semibold).foregroundStyle(.gray)
                                    Text("Load")
                                        .font(.caption).fontWeight(.semibold).foregroundStyle(.gray)
                                    Text("Reps")   // keep label "Reps" for identical visuals
                                        .font(.caption).fontWeight(.semibold).foregroundStyle(.gray)
                                }

                                // Rows
                                LazyVGrid(
                                    columns: [
                                        GridItem(.adaptive(minimum: 80), spacing: 10),
                                        GridItem(.adaptive(minimum: 80), spacing: 10),
                                        GridItem(.adaptive(minimum: 80), spacing: 10)
                                    ],
                                    spacing: 5
                                ) {
                                    ForEach(exercise.setDetails) { set in
                                        let prevSet = previousWeekExercises?
                                            .first(where: { $0.id == exercise.id })?
                                            .setDetails
                                            .first(where: { $0.setNumber == set.setNumber })

                                        Group {
                                            // 1) Set #
                                            Text("\(set.setNumber)")

                                            // 2) Load (weight or distance)
                                            if let prevLoad = prevSet?.load,
                                               prevLoad != set.load {
                                                HStack(spacing: 2) {
                                                    Text(prevLoad.displayString).foregroundStyle(.gray)
                                                    Text("→")
                                                    set.load.formattedText
                                                        .foregroundStyle(set.load.actualValue > prevLoad.actualValue ? .green : .red)
                                                }
                                            } else {
                                                set.load.formattedText
                                            }

                                            // FIXME: planned should include unit
                                            // 3) Metric (reps OR hold), compare only if same kind
                                            if let prev = prevSet?.planned {
                                                let (prevStr, prevVal) = metricStringAndValue(prev)
                                                let (curStr,  curVal)  = metricStringAndValue(set.planned)

                                                if curVal != prevVal {
                                                    HStack(spacing: 2) {
                                                        Text(prevStr).foregroundStyle(.gray)
                                                        Text("→")
                                                        Text(curStr)
                                                            .foregroundStyle(curVal > prevVal ? .green :
                                                                             (curVal < prevVal ? .red : .primary))
                                                    }
                                                } else {
                                                    // No change → just show the current value, no arrow
                                                    Text(curStr)
                                                }
                                            } else {
                                                Text(set.planned.fieldString)
                                            }
                                        }
                                        .font(.caption)
                                    }
                                }
                                .padding(.vertical, 5)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
        }
    }

    /// Return a display string and a numeric value for comparison.
    private func metricStringAndValue(_ m: SetMetric) -> (String, Double) {
        return (m.fieldString, m.actualValue)
    }
}

