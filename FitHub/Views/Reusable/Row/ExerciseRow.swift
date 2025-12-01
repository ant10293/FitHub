//
//  ExerciseRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/30/25.
//

// needs to replace
// StartedWorkoutView - neView
// SimilarExercisesView - SimilarExerciseRowView
// Workout Generation - generationRowContent
// TemplatePopup - popUpRowContent
// FavoriteExercisesView - favRowContent
// ExerciseSelection - selectionRowContent
// OneRMCalculator - RowContent
// ExerciseView - ExerciseRow

import SwiftUI

// MARK: - Core type (no defaults)
// TODO: put this in a wrapper that handles ExerciseDetailView sheet. Ensure no conflict with ExEquipImage
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
    let nextExercise: Exercise? // Used to check if next exercise is superset partner
    let accessory: () -> Accessory
    let detail:    () -> Detail
    let onTap: () -> Void
    
    // ------------------------------------------------------------------
    // Designated init  (only one — keep it simple)
    // ------------------------------------------------------------------
    init(_ exercise: Exercise,
         secondary: Bool = false,
         heartOverlay: Bool = false,
         favState: FavoriteState = .unmarked,
         imageSize: CGFloat = 0.12,
         lineLimit: Int = 2,
         nextExercise: Exercise? = nil,
         @ViewBuilder accessory: @escaping () -> Accessory,
         @ViewBuilder detail:    @escaping () -> Detail,
         onTap: @escaping () -> Void = {}
    ) {
        self.exercise  = exercise
        self.secondary = secondary
        self.heartOverlay = heartOverlay
        self.favState = favState
        self.imageSize = imageSize
        self.lineLimit = lineLimit
        self.nextExercise = nextExercise
        self.accessory = accessory
        self.detail    = detail
        self.onTap     = onTap
    }
    
    private var resolvedState: FavoriteState {
        if !heartOverlay { return .unmarked }
        else { return favState }
    }
    
    /// Check if this exercise is the first in a consecutive superset pair
    private var isFirstInSuperset: Bool {
        guard let next = nextExercise else { return false }
        // Check if current exercise is supersetted with next, or next is supersetted with current
        return exercise.isSupersettedWith == next.id.uuidString || next.isSupersettedWith == exercise.id.uuidString
    }
    
    // ------------------------------------------------------------------
    // Body
    // ------------------------------------------------------------------
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                exercise.fullImageView(favState: resolvedState)
                    .frame(width: UIScreen.main.bounds.width * imageSize)

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

struct ExerciseRowDetails: View {
    let exercise: Exercise
    let peak: PeakMetric?
    let showAliases: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showAliases, let aliases = exercise.aliases, !aliases.isEmpty {
                (
                    Text(aliases.count == 1 ? "Alias: " : "Aliases: ")
                        .fontWeight(.semibold)
                    +
                    Text(aliases.joined(separator: ", "))
                        .foregroundStyle(.gray)
                )
                .font(.caption)
            }
            
            // 🏆 1RM
            if let peak {
                (
                    Text(Image(systemName: "trophy.fill"))
                    + Text(" ")
                    + peak.formattedText
                )
                .font(.caption2)
            }
        }
    }
}

// MARK: - Convenience overloads (give us “defaults” without the compiler pain)
extension ExerciseRow where Accessory == EmptyView, Detail == EmptyView {
    /// No accessory, no detail
    init(_ exercise: Exercise,
         nextExercise: Exercise? = nil,
         onTap: @escaping () -> Void = {}) {
        self.init(exercise,
                  nextExercise: nextExercise,
                  accessory: { EmptyView() },
                  detail:    { EmptyView() },
                  onTap: onTap)
    }
}

extension ExerciseRow where Detail == EmptyView {
    /// Accessory only
    init(_ exercise: Exercise,
         nextExercise: Exercise? = nil,
         @ViewBuilder accessory: @escaping () -> Accessory,
         onTap: @escaping () -> Void = {}) {
        self.init(exercise,
                  nextExercise: nextExercise,
                  accessory: accessory,
                  detail:    { EmptyView() },
                  onTap: onTap)
    }
}

