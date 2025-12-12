//
//  AboutView.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/3/25.
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var showingAdjustmentsView: Bool = false
    @State private var isLoading: Bool = false
    @Binding var loadedExercises: [Exercise]?
    private let modifier = ExerciseModifier()
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {   // <- single vertical spacing source
                // IMAGE + RATING
                VStack(alignment: .leading, spacing: 4) {
                    ExEquipImage(image: exercise.fullImage, button: .expand)
                        .centerHorizontally()

                    RatingIcon(
                        exercise: exercise,
                        favState: FavoriteState.getState(for: exercise, userData: ctx.userData),
                        size: .large,
                        onFavorite: {
                            modifier.toggleFavorite(for: exercise.id, userData: ctx.userData)
                        },
                        onDislike: {
                            modifier.toggleDislike(for: exercise.id, userData: ctx.userData)
                        }
                    )
                    .centerHorizontally()
                }

                // HOW TO PERFORM
                VStack(alignment: .leading, spacing: 4) {
                    Text("How to perform").bold()

                    if !exercise.instructions.steps.isEmpty {
                        NumberedListView(
                            items: exercise.instructions.steps,
                            numberingStyle: .oneDot
                        )
                    } else {
                        Text("No instructions available.")
                            .foregroundStyle(Color.secondary)
                    }
                }

                // LIMB MOVEMENT TYPE
                if let limbMovementType = exercise.limbMovementType {
                    VStack(alignment: .leading, spacing: 4) {
                        limbMovementType.displayInfoText
                    }
                }

                // DIFFICULTY
                VStack(alignment: .leading, spacing: 4) {
                    (Text("Difficulty: ").bold() + Text(exercise.difficulty.fullName))
                }

                VStack(alignment: .leading, spacing: 4) {
                    if !exercise.primaryMuscleEngagements.isEmpty {
                        exercise.primaryMusclesFormatted
                            .multilineTextAlignment(.leading)
                    }
                    if !exercise.secondaryMuscleEngagements.isEmpty {
                        exercise.secondaryMusclesFormatted
                            .multilineTextAlignment(.leading)
                    }
                }

                // EQUIPMENT REQUIRED
                if !exercise.equipmentRequired.isEmpty {
                    let equipment = ctx.equipment.equipmentForExercise(
                        exercise,
                        inclusion: .dynamic,
                        available: ctx.userData.evaluation.availableEquipment
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        EquipmentScrollRow(equipment: equipment, title: "Equipment Required")
                    }
                }

                // EQUIPMENT ADJUSTMENTS BUTTON
                if ctx.equipment.hasEquipmentAdjustments(for: exercise) {
                    VStack(alignment: .leading, spacing: 4) {
                        LabelButton(
                            title: "Equipment Adjustments",
                            systemImage: "slider.horizontal.3",
                            tint: .green,
                            controlSize: .large,
                            action: { showingAdjustmentsView.toggle() }
                        )
                    }
                }

                // SIMILAR EXERCISES
                VStack(alignment: .leading, spacing: 4) {
                    SimilarExercisesRow(loadedExercises: $loadedExercises, exercise: exercise)
                }
            }
        }
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exercise: exercise)
        }
    }
}
