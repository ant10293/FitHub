//
//  StrengthLevelView.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/15/25.
//

import SwiftUI

struct StrengthLevelView: View {
    @EnvironmentObject private var ctx: AppContext
    
    var body: some View {
        List {
            // ───────── Strength Level Picker ─────────
            Section {
                Picker("Strength Level", selection: Binding(
                    get: { ctx.userData.evaluation.strengthLevel },
                    set: { newValue in
                        ctx.userData.evaluation.strengthLevel = newValue
                    }
                )) {
                    ForEach(StrengthLevel.allCases, id: \.self) { level in
                        Text(level.fullName).tag(level)
                    }
                }
            } header: {
                Text("Current Strength Level")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your overall strength level is used for workout generation and exercise recommendations.")
                    if let date = ctx.userData.evaluation.determineStrengthLevelDate {
                        Text("Determined on \(Format.formatDate(date, timeStyle: .none))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // ───────── Exercise Level Mapping ─────────
            if let exerciseLvlMapping = ctx.userData.evaluation.exerciseLvlMapping, !exerciseLvlMapping.isEmpty {
                Section {
                    // Each strength level gets its own disclosure group (show all, even if empty)
                    ForEach(StrengthLevel.allCases, id: \.self) { level in
                        let exerciseIDs = exerciseLvlMapping[level] ?? []
                        DisclosureGroup {
                            if exerciseIDs.isEmpty {
                                Text("No exercises in this category.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(exerciseIDs, id: \.self) { exerciseID in
                                    if let exercise = ctx.exercises.exercise(for: exerciseID) {
                                        let date = ctx.exercises.performanceData(for: exercise.id)?.currentMax?.date
                                        VStack(alignment: .leading) {
                                            Text(exercise.name)
                                                .font(.body)
                                            if let date {
                                                Text(Format.formatDate(date, timeStyle: .none))
                                                    .foregroundStyle(.secondary)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }                                
                            }
                        } label: {
                            HStack {
                                Text(level.fullName)
                                Spacer()
                                Text("\(exerciseIDs.count)")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(exerciseIDs.isEmpty)
                    }
                    
                    // "Not Determined" group for exercises without a level
                    let notDeterminedExercises = getNotDeterminedExercises(exerciseLvlMapping)
                    if !notDeterminedExercises.isEmpty {
                        DisclosureGroup {
                            ForEach(notDeterminedExercises, id: \.self) { exerciseID in
                                if let exercise = ctx.exercises.exercise(for: exerciseID) {
                                    Text(exercise.name)
                                        .font(.body)
                                }
                            }
                        } label: {
                            HStack {
                                Text("Not Determined")
                                Spacer()
                                Text("\(notDeterminedExercises.count)")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Exercise Level Mapping")
                } footer: {
                    Text("Exercises are categorized by strength level based on your performance data. This mapping is updated automatically when you complete workouts.")
                }
            } else {
                Section {
                    Text("No exercise level mapping available.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } header: {
                    Text("Exercise Level Mapping")
                } footer: {
                    Text("Complete workouts to generate exercise level mappings based on your performance.")
                }
            }
        }
        .navigationBarTitle("Strength Level", displayMode: .inline)
    }
    
    /// Returns exercise IDs that have performance data but aren't in the exercise level mapping
    private func getNotDeterminedExercises(_ mapping: [StrengthLevel: [Exercise.ID]]) -> [Exercise.ID] {
        // Collect all exercise IDs that are in the mapping
        let allMappedIDs = Set(mapping.values.flatMap { $0 })
        
        // Find exercises that have performance data but aren't in the mapping
        // These are exercises that have been used but haven't been evaluated yet
        let allExercises = ctx.exercises.allExercises
        let notDetermined = allExercises
            .filter { exercise in
                // Exercise has performance data but isn't in the mapping
                !allMappedIDs.contains(exercise.id)
            }
            .map { $0.id }
        
        return notDetermined
    }
}

