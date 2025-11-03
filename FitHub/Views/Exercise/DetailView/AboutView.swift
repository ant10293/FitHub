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
    private let modifier = ExerciseModifier()
    let exercise: Exercise
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
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

                Text("How to perform: ").bold() // Placeholder text
                Group {
                    if let printedInstructions = exercise.instructions.formattedString() {
                        Text(printedInstructions)
                    } else {
                        Text("No instructions available.")
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.bottom)
                
                if let limbMovementType = exercise.limbMovementType {
                    limbMovementType.displayInfoText
                        .padding(.bottom)
                }
                
                (Text("Difficulty: ").bold() + Text(exercise.difficulty.fullName))
                    .padding(.bottom)
                
                if !exercise.primaryMuscleEngagements.isEmpty {
                    exercise.primaryMusclesFormatted
                        .multilineTextAlignment(.leading)
                }
                
                if !exercise.secondaryMuscleEngagements.isEmpty {
                    exercise.secondaryMusclesFormatted
                        .multilineTextAlignment(.leading)
                }
                
                if !exercise.equipmentRequired.isEmpty {
                    let equipment = ctx.equipment.equipmentForExercise(exercise)
                    EquipmentScrollRow(equipment: equipment, title: "Equipment Required")
                        .padding(.vertical)
                }
                
                if ctx.equipment.hasEquipmentAdjustments(for: exercise) {
                    LabelButton(
                        title: "Equipment Adjustments",
                        systemImage: "slider.horizontal.3",
                        tint: .green,
                        controlSize: .large,
                        action: { showingAdjustmentsView.toggle() }
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exercise: exercise)
        }
    }
}
