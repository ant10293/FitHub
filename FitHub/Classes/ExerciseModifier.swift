import Foundation
import SwiftUI

// favorite exercise
// disliked exercise
// replace exercise
// replace exercise with specific exercise
// remove exercise

import Foundation
import SwiftUI

/// Instance-based helper.  Hold a single copy wherever you need it
/// (`let modifier = ExerciseModifier()`).
struct ExerciseModifier {
    
    // MARK: Public façade
    // ─────────────────────────────────────────────────────────────
    /// Replace `target` inside `template` with *the first* similar exercise.
    /// Returns `true` if something was replaced.
    @MainActor @discardableResult
    func replace(target: Exercise, in template: inout WorkoutTemplate, ctx: AppContext, replaced: inout [String]) -> Exercise? {
        guard let idx = template.exercises.firstIndex(where: { $0.id == target.id }) else { return nil }

        // Build candidate pool
        let candidates = ctx.exercises.similarExercises(to: target, user: ctx.userData, equipmentData: ctx.equipment, existing: template.exercises, replaced: Set(replaced))

        guard let newEx = candidates.first else { return nil }

        let detailed = Self.detailed(from: newEx, ctx: ctx)

        template.exercises[idx] = detailed
        replaced.append(target.name)
        
        _ = ctx.userData.updateTemplate(template: template)
        
        return detailed
    }

    /// Replace *a specific* exercise by name.
    @MainActor func replaceSpecific(currentExercise: Exercise, with newExercise: Exercise, in template: inout WorkoutTemplate, ctx: AppContext) {
        guard let idx = template.exercises.firstIndex(where: { $0.id == currentExercise.id }) else { return }

        let detailed = Self.detailed(from: newExercise, ctx: ctx)

        template.exercises[idx] = detailed
        _ = ctx.userData.updateTemplate(template: template)
    }

    /// Remove the exercise entirely.
    func remove(_ exercise: Exercise, from template: inout WorkoutTemplate, user: UserData) -> String {
        template.exercises.removeAll { $0.id == exercise.id }
        removeSupersetForDeletedExercise(exercise, from: &template)
        _ = user.updateTemplate(template: template)
        return exercise.name
    }
    
    private func removeSupersetForDeletedExercise(_ deletedExercise: Exercise, from template: inout WorkoutTemplate) {
        let deletedID = deletedExercise.id.uuidString

        for index in template.exercises.indices {
            if template.exercises[index].isSupersettedWith == deletedID {
                template.exercises[index].isSupersettedWith = nil
            }
        }
    }

    /// Toggle favourite / dislike — same API you had before.
    func toggleFavorite(for exerciseId: UUID, userData: UserData) {
        if let i = userData.evaluation.favoriteExercises.firstIndex(of: exerciseId) {
            userData.evaluation.favoriteExercises.remove(at: i)
        } else {
            userData.evaluation.dislikedExercises.removeAll { $0 == exerciseId }
            userData.evaluation.favoriteExercises.append(exerciseId)
        }
        userData.saveSingleStructToFile(\.evaluation, for: .evaluation)
    }

    func toggleDislike(for exerciseId: UUID, userData: UserData) {
        if let i = userData.evaluation.dislikedExercises.firstIndex(of: exerciseId) {
            userData.evaluation.dislikedExercises.remove(at: i)
        } else {
            userData.evaluation.favoriteExercises.removeAll { $0 == exerciseId }
            userData.evaluation.dislikedExercises.append(exerciseId)
        }
        userData.saveSingleStructToFile(\.evaluation, for: .evaluation)
    }

    // MARK:  Static helpers
    // ─────────────────────────────────────────────────────────────

    /// Make a fully–detailed exercise via the old `calculateDetailedExercise`.
    @MainActor private static func detailed(from exercise: Exercise, ctx: AppContext) -> Exercise {
        let rAndS = RepsAndSets.determineRepsAndSets(
            customRestPeriod: ctx.userData.workoutPrefs.customRestPeriod,
            goal:             ctx.userData.physical.goal,
            customRepsRange:  ctx.userData.workoutPrefs.customRepsRange,
            customSets:       ctx.userData.workoutPrefs.customSets)

        return ctx.userData.calculateDetailedExercise(exerciseData: ctx.exercises, equipmentData: ctx.equipment, exercise: exercise, repsAndSets: rAndS, nextWeek: false)
    }
    
    // for ExerciseSetDetail:
    func handleSupersetSelection(for exercise: inout Exercise, with newValue: String, in template: inout WorkoutTemplate) {
        let oldPartnerID = exercise.isSupersettedWith          // may be `nil`
        let myIDString = exercise.id.uuidString              // safe copy
        
        // ─────────────────────────────────────────────────────────────────────
        // 1. Break the OLD two-way link (if any) when the partner changes
        // ---------------------------------------------------------------------
        if let oldID = oldPartnerID, oldID != newValue {
            if let idx = template.exercises.firstIndex(where: { $0.id.uuidString == oldID }) {
                template.exercises[idx].isSupersettedWith = nil
            }
        }
        
        // ─────────────────────────────────────────────────────────────────────
        if newValue == "None" {
            // 2. Clear *my* link
            exercise.isSupersettedWith = nil
            
            // 3. Clear anyone that points **to me**
            if let idx = template.exercises.firstIndex(where: { $0.isSupersettedWith == myIDString }) {
                template.exercises[idx].isSupersettedWith = nil
            }
            return
        }
        
        // ─────────────────────────────────────────────────────────────────────
        // 4. Establish the NEW two-way link
        // ---------------------------------------------------------------------
        exercise.isSupersettedWith = newValue                  // I → partner
        
        if let idx = template.exercises.firstIndex(where: { $0.id.uuidString == newValue }) {
            template.exercises[idx].isSupersettedWith = myIDString   // partner → me
        }
    }
    
    func addNewSet(_ exercise: Exercise, from template: inout WorkoutTemplate, user: UserData) {
        if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }) {
            let currentSets = template.exercises[index].sets
            let newSet = SetDetail(setNumber: currentSets + 1, weight: 0, reps: 0)
            template.exercises[index].setDetails.append(newSet)
            _ = user.updateTemplate(template: template)
        }
    }
    
    func deleteSet(_ exercise: Exercise, from template: inout WorkoutTemplate, user: UserData) {
        if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }) {
            guard !template.exercises[index].setDetails.isEmpty else { return }
            template.exercises[index].setDetails.removeLast()
            _ = user.updateTemplate(template: template)
        }
    }
}


