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
    @StateObject private var kbd = KeyboardManager.shared
    @State private var showingUpdate1RMView: Bool = false
    @State private var showingList: Bool = false
    let exercise: Exercise

    var body: some View {
        let perf = ctx.exercises.allExercisePerformance[exercise.id]

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
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .overlay(alignment: .center) {
            if showingUpdate1RMView {
                UpdateMaxEditor(
                    exercise: exercise,
                    onSave: { newMax, date in
                        kbd.dismiss()
                        ctx.exercises.updateExercisePerformance(for: exercise, newValue: newMax, setOn: date, shouldSave: true)
                        showingUpdate1RMView = false
                    },
                    onCancel: {
                        kbd.dismiss()
                        showingUpdate1RMView = false
                    }
                )
            }
        }
        .overlay(alignment: .bottomLeading) {
            if !kbd.isVisible && !showingUpdate1RMView {
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
