//
//  ExerciseRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/30/25.
//

// needs to replace
// StartedWorkoutView - ExerciseRowView
// SimilarExercisesView - SimilarExerciseRowView
// Workout Generation - generationRowContent
// TemplatePopup - popUpRowContent
// FavoriteExercisesView - favRowContent
// ExerciseSelection - selectionRowContent
// OneRMCalculator - RowContent
// ExerciseView - ExerciseRow

import SwiftUI

// MARK: - Core type (no defaults)

struct ExerciseRow<Accessory: View, Detail: View>: View {
    // ------------------------------------------------------------------
    // Stored vars
    // ------------------------------------------------------------------
    let exercise: Exercise
    let secondary: Bool
    let heartOverlay: Bool
    let favState: FavoriteState
    let imageSize: CGFloat
    let lineLimit: Int
    let accessory: () -> Accessory
    let detail:    () -> Detail
    var onTap: () -> Void
    
    // ------------------------------------------------------------------
    // Designated init  (only one — keep it simple)
    // ------------------------------------------------------------------
    init(_ exercise: Exercise,
         secondary: Bool = false,
         heartOverlay: Bool = false,
         favState: FavoriteState = .unmarked,
         imageSize: CGFloat = 0.12,
         lineLimit: Int = 2,
         @ViewBuilder accessory: @escaping () -> Accessory,
         @ViewBuilder detail:    @escaping () -> Detail,
         onTap: @escaping () -> Void = {}) {
        
        self.exercise  = exercise
        self.secondary = secondary
        self.heartOverlay = heartOverlay
        self.favState = favState
        self.imageSize = imageSize
        self.lineLimit = lineLimit
        self.accessory = accessory
        self.detail    = detail
        self.onTap     = onTap
    }
    
    // ------------------------------------------------------------------
    // Body
    // ------------------------------------------------------------------
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                exercise.fullImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(alignment: .bottomTrailing, content: {
                        if heartOverlay {
                            if favState == .favorite {
                                Image(systemName: "heart.fill")
                                    .imageScale(.small)
                                    .foregroundColor(.red)
                            } else if favState == .disliked {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .imageScale(.small)
                                    .foregroundColor(.blue)
                            }
                        }
                    })

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(secondary ? .subheadline : .headline)
                        .lineLimit(lineLimit)
                        .minimumScaleFactor(0.7)
                    
                    detail()                   // empty → auto-disappears
                }
                
                Spacer(minLength: 8)
                accessory()                   // empty → auto-disappears
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 1) {
                onTap()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Convenience overloads (give us “defaults” without the compiler pain)

extension ExerciseRow where Accessory == EmptyView, Detail == EmptyView {
    /// No accessory, no detail
    init(_ exercise: Exercise,
         onTap: @escaping () -> Void = {}) {
        self.init(exercise,
                  accessory: { EmptyView() },
                  detail:    { EmptyView() },
                  onTap: onTap)
    }
}

extension ExerciseRow where Detail == EmptyView {
    /// Accessory only
    init(_ exercise: Exercise,
         @ViewBuilder accessory: @escaping () -> Accessory,
         onTap: @escaping () -> Void = {}) {
        self.init(exercise,
                  accessory: accessory,
                  detail:    { EmptyView() },
                  onTap: onTap)
    }
}
