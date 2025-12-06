//
//  TemplateExerciseList.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/1/25.
//

import SwiftUI

/// A reusable view that enumerates exercises from a template with superset visualization support
struct TemplateExerciseList<Accessory: View, Detail: View>: View {
    @State private var selectedExercise: Exercise?
    let template: WorkoutTemplate
    let userData: UserData
    let secondary: Bool
    let heartOverlay: Bool
    let imageSize: CGFloat
    let lineLimit: Int
    let showCount: Bool
    let tapAction: TapAction
    let accessory: (Exercise) -> Accessory
    let detail: (Exercise) -> Detail
    let onTap: (Exercise, Int) -> Void
    
    init(
        template: WorkoutTemplate,
        userData: UserData,
        secondary: Bool = false,
        heartOverlay: Bool = true,
        imageSize: CGFloat = 0.12,
        lineLimit: Int = 2,
        showCount: Bool = true,
        tapAction: TapAction = .viewDetail,
        @ViewBuilder accessory: @escaping (Exercise) -> Accessory = { _ in EmptyView() },
        @ViewBuilder detail: @escaping (Exercise) -> Detail,
        onTap: @escaping (Exercise, Int) -> Void = { _, _ in }
    ) {
        self.template = template
        self.userData = userData
        self.secondary = secondary
        self.heartOverlay = heartOverlay
        self.imageSize = imageSize
        self.lineLimit = lineLimit
        self.showCount = showCount
        self.tapAction = tapAction
        self.accessory = accessory
        self.detail = detail
        self.onTap = onTap
    }
    
    enum TapAction { case showOverlay, viewDetail }
    
    var body: some View {
        List {
            Section {
                ForEach(Array(template.exercises.enumerated()), id: \.element.id) { index, exercise in
                    let nextExercise = (index + 1 < template.exercises.count) ? template.exercises[index + 1] : nil
                    let previousExercise = (index > 0) ? template.exercises[index - 1] : nil
                    let isFirstInSuperset: Bool = {
                        guard let next = nextExercise else { return false }
                        return template.supersetFor(exercise: exercise) == next ||
                        template.supersetFor(exercise: next) == exercise
                    }()
                    let isSecondInSuperset: Bool = {
                        guard let previous = previousExercise else { return false }
                        return template.supersetFor(exercise: exercise) == previous ||
                        template.supersetFor(exercise: previous) == exercise
                    }()
                    
                    // Regular exercise row
                    let baseRow = ExerciseRow(
                        exercise,
                        secondary: secondary,
                        heartOverlay: heartOverlay,
                        infoOverlay: tapAction == .viewDetail,
                        favState: FavoriteState.getState(for: exercise, userData: userData),
                        imageSize: imageSize,
                        lineLimit: lineLimit,
                        nextExercise: nextExercise,
                        accessory: {
                            accessory(exercise)
                        },
                        detail: {
                            detail(exercise)
                        },
                        onTap: {
                            switch tapAction {
                            case .showOverlay:
                                onTap(exercise, index)
                            case .viewDetail:
                                selectedExercise = exercise
                            }
                        }
                    )
                    
                    let modifiedRow = baseRow
                        .id(exercise.id)
                        .disabled(exercise.isCompleted)
                        .opacity(exercise.isCompleted ? 0.25 : 1.0)
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
            } header: {
                if showCount {
                    Text(Format.countText(template.exercises.count))
                        .font(.caption)
                }
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, viewingAsSheet: true)
        }
    }
}

