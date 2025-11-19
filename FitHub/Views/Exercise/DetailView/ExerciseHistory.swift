//
//  ExerciseHistory.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/17/25.
//

import SwiftUI

struct ExerciseHistory: View {
    @State private var selectedSortOption: CompletedExerciseSortOption = .mostRecent
    let completedWorkouts: [CompletedWorkout]
    let exerciseId: UUID

    var body: some View {
        VStack {
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
                if sortedExercise.isEmpty {
                    Text("No recent sets available for this exercise.")
                        .foregroundStyle(.gray)
                        .cardContainer()
                } else {
                    ForEach(sortedExercise, id: \.self) { workout in
                        VStack(alignment: .leading) {
                            Text("\(workout.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Text("\(workout.template.name)")
                            ForEach(workout.template.exercises.filter { $0.id == exerciseId }) { ex in
                                VStack {
                                    CompletedDetails.exerciseSets(
                                        exercise: ex,
                                        warmup: false,
                                        prs: workout.updatedMax
                                    )
                                }
                                .cardContainer()
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
            workout.template.exercises.contains(where: { $0.id == exerciseId })
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
