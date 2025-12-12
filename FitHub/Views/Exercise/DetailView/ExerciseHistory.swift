//
//  ExerciseHistory.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/17/25.
//

import SwiftUI

struct ExerciseHistory: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showingGraph: Bool = false
    let exercise: Exercise
    let completedWorkouts: [CompletedWorkout]

    var body: some View {
        VStack {
            if showingGraph {
                ExerciseRPEGraph(exercise: exercise, completedWorkouts: completedWorkouts)
            } else {
                SetDetailHistory(exerciseId: exercise.id, completedWorkouts: completedWorkouts)
            }

            HStack {
                FloatingButton(
                    image: showingGraph ? "list.bullet.rectangle" : "chart.bar",
                    foreground: .blue,
                    background: colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white,
                    action: {
                        showingGraph.toggle()
                    }
                )
                Spacer()
            }
        }
    }
}
