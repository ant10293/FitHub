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
                            let oldExercise = previousWeekExercises?
                                .first(where: { $0.id == exercise.id })
                            
                            ExerciseSetChange(newExercise: exercise, oldExercise: oldExercise)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ExerciseSetChange: View {
    let newExercise: Exercise
    let oldExercise: Exercise?
    
    var body: some View {
        let firstSet = newExercise.setDetails.first
        
        VStack(alignment: .leading, spacing: 10) {
            Text(newExercise.name)
                .font(.headline)
                .foregroundStyle(.primary)

            // Headers (unchanged visuals)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 5) {
                Text("Set")
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.gray)
                let load = firstSet?.load ?? newExercise.loadMetric
                if let unit = load.unit, let label = unit.label(for: .label)  {
                    Text(label)
                        .font(.caption).fontWeight(.semibold).foregroundStyle(.gray)
                } else {
                    Spacer()
                }
                let planned = firstSet?.planned ?? newExercise.plannedMetric
                if let label = planned.unit.label(for: .label)  {
                    Text(label)
                        .font(.caption).fontWeight(.semibold).foregroundStyle(.gray)
                }
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
                ForEach(newExercise.setDetails) { set in
                    let prevSet = oldExercise?.setDetails
                        .first(where: { $0.setNumber == set.setNumber })

                    Group {
                        // 1) Set #
                        Text("\(set.setNumber)")

                        // 2) Load (weight or distance)
                        if let prevLoad = prevSet?.load, prevLoad != set.load {
                            HStack(spacing: 2) {
                                Text(prevLoad.displayString).foregroundStyle(.gray)
                                Text("→")
                                set.load.formattedText
                                    .foregroundStyle(set.load.actualValue > prevLoad.actualValue ? .green : .red)
                            }
                        } else {
                            set.load.formattedText
                        }

                        // 3) Metric (reps OR hold), compare only if same kind
                        if let prevPlanned = prevSet?.planned, prevPlanned != set.planned  {
                            let curVal = set.planned.actualValue
                            let prevVal = prevPlanned.actualValue
                            
                            HStack(spacing: 2) {
                                Text(prevPlanned.displayString).foregroundStyle(.gray)
                                Text("→")
                                set.planned.formattedText
                                    .foregroundStyle(curVal > prevVal ? .green :
                                                     (curVal < prevVal ? .red : .primary))
                            }
                        } else {
                            set.planned.formattedText
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

