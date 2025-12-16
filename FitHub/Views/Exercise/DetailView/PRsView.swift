//
//  PRsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/3/25.
//

import SwiftUI

struct PRsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var ctx: AppContext
    @State private var showingUpdate1RMView: Bool = false
    @State private var showingList: Bool = false
    let exercise: Exercise

    var body: some View {
        let perf = ctx.exercises.performanceData(for: exercise.id)

        VStack {
            if !showingList {
                ExercisePerformanceGraph(exercise: exercise, performance: perf)
            } else {
                ExercisePerformanceView(
                    exercise: exercise,
                    performance: perf,
                    onDelete: { entryID in
                        ctx.exercises.deleteEntry(id: entryID, exercise: exercise)
                    },
                    onSetMax: { entryID in
                        ctx.exercises.setAsCurrentMax(id: entryID, exercise: exercise)
                    }
                )
            }

            if !showingUpdate1RMView {
                RectangularButton(
                    title: "Update Max",
                    systemImage: "square.and.pencil",
                    width: .fit,
                    action: {
                        showingUpdate1RMView = true
                    }
                )
                .clipShape(.capsule)
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showingUpdate1RMView) {
            UpdateMaxEditor(
                exercise: exercise,
                onSave: { newMax, date in
                    ctx.exercises.updateExercisePerformance(for: exercise, newValue: newMax, setOn: date, shouldSave: true)
                    showingUpdate1RMView = false
                },
                onCancel: {
                    showingUpdate1RMView = false
                }
            )
        }
        .overlay(alignment: .bottomLeading) {
            if !showingUpdate1RMView {
                FloatingButton(
                    image: showingList ? "chart.bar" : "list.bullet.rectangle",
                    foreground: .blue,
                    background: colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white,
                    action: {
                        showingList.toggle()
                    }
                )
            }
        }
    }
}
