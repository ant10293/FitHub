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
                AboutSection {
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
                AboutSection {
                    Text("How to perform: ")
                        .bold()

                    if let printedInstructions = exercise.instructions.formattedString() {
                        Text(printedInstructions)
                    } else {
                        Text("No instructions available.")
                            .foregroundStyle(Color.secondary)
                    }
                }

                // LIMB MOVEMENT TYPE
                if let limbMovementType = exercise.limbMovementType {
                    AboutSection {
                        limbMovementType.displayInfoText
                    }
                }

                // DIFFICULTY
                AboutSection {
                    (Text("Difficulty: ").bold() + Text(exercise.difficulty.fullName))
                }

                AboutSection {
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
                    let equipment = ctx.equipment.equipmentForExercise(exercise)
                    AboutSection {
                        EquipmentScrollRow(equipment: equipment, title: "Equipment Required")
                    }
                }

                // EQUIPMENT ADJUSTMENTS BUTTON
                if ctx.equipment.hasEquipmentAdjustments(for: exercise) {
                    AboutSection {
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
                AboutSection {
                    SimilarExercisesRow(loadedExercises: $loadedExercises, exercise: exercise)
                }
            }
        }
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exercise: exercise)
        }
    }
}


private struct AboutSection<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content
        }
    }
}
