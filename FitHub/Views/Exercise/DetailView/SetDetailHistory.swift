//
//  SetDetailHistory.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/21/25.
//

import SwiftUI

struct SetDetailHistory: View {
    @State private var selectedSortOption: CompletedExerciseSortOption = .mostRecent
    let exerciseId: UUID
    let completedWorkouts: [CompletedWorkout]

    var body: some View {
        VStack {
            if sortedExercise.isEmpty {
                EmptyState(
                    systemName: "nosign",
                    title: "No recent sets available for this exercise.",
                    subtitle: "Include this exercise in your next workout to see your performed sets here."
                )
                .centerVertically()
            } else {
                HStack {
                    Text("Sort by")
                        .bold()
                    Picker("Sort by", selection: $selectedSortOption) {
                        ForEach(CompletedExerciseSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .centerHorizontally()

                ScrollView {
                    ForEach(sortedExercise, id: \.self) { workout in
                        VStack(alignment: .leading, spacing: 12) {
                            
                            ForEach(workout.template.exercises.filter { $0.id == exerciseId }) { ex in
                                ExerciseSetsDisclosure(
                                    exercise: ex,
                                    workoutDate: workout.date,
                                    workoutName: workout.template.name,
                                    prs: workout.updatedMax
                                )
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }

    private var sortedExercise: [CompletedWorkout] {
        let filteredWorkouts = completedWorkouts.filter { workout in
            workout.template.exercises.contains(where: { $0.id == exerciseId && !$0.noSetsCompleted })
        }
        
        switch selectedSortOption {
        case .mostRecent:
            return filteredWorkouts.sorted { $0.date > $1.date }
        case .leastRecent:
            return filteredWorkouts.sorted { $0.date < $1.date }
        case .thisWeek:
            let weekOfYear = CalendarUtility.shared.weekOfYear(from: Date())
            return filteredWorkouts.filter {
                CalendarUtility.shared.weekOfYear(from: $0.date) == weekOfYear
            }
        case .thisMonth:
            let currentMonth = CalendarUtility.shared.month(from: Date())
            return filteredWorkouts.filter {
                CalendarUtility.shared.month(from: $0.date) == currentMonth
            }
        case .mostSets:
            return filteredWorkouts.sorted {
                let setsInFirst = $0.template.exercises.reduce(0) { $0 + $1.workingSets }
                let setsInSecond = $1.template.exercises.reduce(0) { $0 + $1.workingSets }
                return setsInFirst > setsInSecond
            }
        case .leastSets:
            return filteredWorkouts.sorted {
                let setsInFirst = $0.template.exercises.reduce(0) { $0 + $1.workingSets }
                let setsInSecond = $1.template.exercises.reduce(0) { $0 + $1.workingSets }
                return setsInFirst < setsInSecond
            }
        }
    }
}

private struct ExerciseSetsDisclosure: View {
    let exercise: Exercise
    let workoutDate: Date
    let workoutName: String
    let prs: [PerformanceUpdate]
    @State private var isExpanded = false
    
    var body: some View {
        TappableDisclosure(isExpanded: $isExpanded) {
            // LABEL
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if !prs.isEmpty {
                        Image(systemName: "trophy.fill")
                    }
                    Text(exercise.name)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                
                Text("\(workoutDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Text("\(workoutName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(Format.countText(exercise.setsCompleted, base: "set")) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } content: {
            // CONTENT
            VStack {
                CompletedDetails.exerciseSets(
                    exercise: exercise,
                    warmup: false,
                    prs: prs
                )
            }
            .padding(.top, 8)
        }
        .cardContainer()
    }
}
