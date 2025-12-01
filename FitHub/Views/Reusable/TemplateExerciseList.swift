//
//  TemplateExerciseList.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/1/25.
//

import SwiftUI

/// A reusable view that enumerates exercises from a template with superset visualization support
struct TemplateExerciseList<Accessory: View, Detail: View>: View {
    let exercises: [Exercise]
    let userData: UserData
    let secondary: Bool
    let heartOverlay: Bool
    let imageSize: CGFloat
    let lineLimit: Int
    let accessory: (Exercise) -> Accessory
    let detail: (Exercise) -> Detail
    let onTap: (Exercise, Int) -> Void
    let applyRowModifiers: (Exercise, Int, Bool, AnyView) -> AnyView
    
    init(
        exercises: [Exercise],
        userData: UserData,
        secondary: Bool = false,
        heartOverlay: Bool = true,
        imageSize: CGFloat = 0.12,
        lineLimit: Int = 2,
        @ViewBuilder accessory: @escaping (Exercise) -> Accessory,
        @ViewBuilder detail: @escaping (Exercise) -> Detail,
        onTap: @escaping (Exercise, Int) -> Void = { _, _ in },
        applyRowModifiers: @escaping (Exercise, Int, Bool, AnyView) -> AnyView = { _, _, _, view in view }
    ) {
        self.exercises = exercises
        self.userData = userData
        self.secondary = secondary
        self.heartOverlay = heartOverlay
        self.imageSize = imageSize
        self.lineLimit = lineLimit
        self.accessory = accessory
        self.detail = detail
        self.onTap = onTap
        self.applyRowModifiers = applyRowModifiers
    }
    
    var body: some View {
        List {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                let nextExercise = (index + 1 < exercises.count) ? exercises[index + 1] : nil
                let previousExercise = (index > 0) ? exercises[index - 1] : nil
                let isFirstInSuperset = nextExercise != nil && (
                    exercise.isSupersettedWith == nextExercise?.id.uuidString ||
                    nextExercise?.isSupersettedWith == exercise.id.uuidString
                )
                let isSecondInSuperset = previousExercise != nil && (
                    exercise.isSupersettedWith == previousExercise?.id.uuidString ||
                    previousExercise?.isSupersettedWith == exercise.id.uuidString
                )
                
                // Regular exercise row
                let baseRow = ExerciseRow(
                    exercise,
                    secondary: secondary,
                    heartOverlay: heartOverlay,
                    favState: FavoriteState.getState(for: exercise, userData: userData),
                    imageSize: imageSize,
                    lineLimit: lineLimit,
                    nextExercise: nextExercise
                ) {
                    accessory(exercise)
                } detail: {
                    detail(exercise)
                } onTap: {
                    onTap(exercise, index)
                }
                
                let modifiedRow = applyRowModifiers(exercise, index, isFirstInSuperset, AnyView(baseRow))
                    .listRowSeparator(isFirstInSuperset ? .hidden : .automatic, edges: isFirstInSuperset ? .bottom : .all)
                
                // Apply negative padding to reduce spacing for supersetted exercises
                if isFirstInSuperset {
                    // First exercise: reduce bottom spacing
                    modifiedRow
                        .padding(.bottom, -8)
                } else if isSecondInSuperset {
                    // Second exercise: reduce top spacing
                    modifiedRow
                        .padding(.top, -8)
                } else {
                    modifiedRow
                }
                
                // Superset badge row - inserted between the two supersetted exercises
                if isFirstInSuperset {
                    HStack(spacing: 4) {
                        Text("Supersetted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(.systemBackground)))
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden, edges: .all) // Hide separators above and below
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // Remove all insets
                }
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
    }
}

