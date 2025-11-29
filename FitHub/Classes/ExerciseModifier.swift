import Foundation
import SwiftUI

// favorite exercise
// disliked exercise
// replace exercise
// replace exercise with specific exercise
// remove exercise


/// Instance-based helper.  Hold a single copy wherever you need it
/// (`let modifier = ExerciseModifier()`).
struct ExerciseModifier {
    // MARK: Result struct for background replace operation
    struct ReplaceResult {
        let newExercise: Exercise?
        let updatedTemplate: WorkoutTemplate
        let updatedReplaced: [String]
    }
    
    func replaceInBackground(
        target: Exercise,
        template: WorkoutTemplate,
        exerciseData: ExerciseData,
        equipmentData: EquipmentData,
        userData: UserData,
        replaced: [String],
        onComplete: @escaping (ReplaceResult) -> Void
    ) {
        // Capture all necessary data before going to background thread
        let availableEquipmentIDs = userData.evaluation.availableEquipment

        DispatchQueue.global(qos: .userInitiated).async {
            var workingTemplate = template
            var workingReplaced = replaced

            guard let idx = workingTemplate.exercises.firstIndex(where: { $0.id == target.id }) else {
                DispatchQueue.main.async {
                    onComplete(ReplaceResult(
                        newExercise: nil,
                        updatedTemplate: workingTemplate,
                        updatedReplaced: workingReplaced
                    ))
                }
                return
            }

            // Build candidate pool using captured data
            let candidates = exerciseData.similarExercises(
                to: target,
                equipmentData: equipmentData,
                availableEquipmentIDs: availableEquipmentIDs,
                existing: workingTemplate.exercises,
                replaced: Set(workingReplaced)
            )

            guard let newEx = candidates.first else {
                DispatchQueue.main.async {
                    onComplete(ReplaceResult(
                        newExercise: nil,
                        updatedTemplate: workingTemplate,
                        updatedReplaced: workingReplaced
                    ))
                }
                return
            }

            DispatchQueue.main.async {
                // Create detailed exercise using captured data
                let detailed = Self.detailed(exercise: newEx, exerciseData: exerciseData, equipmentData: equipmentData, userData: userData)
                workingTemplate.exercises[idx] = detailed
                workingReplaced.append(target.name)

                // Update the template in userData on main thread
                userData.updateTemplate(template: workingTemplate)

                onComplete(ReplaceResult(
                    newExercise: detailed,
                    updatedTemplate: workingTemplate,
                    updatedReplaced: workingReplaced
                ))
            }
        }
    }

    /// Replace *a specific* exercise by name.
    @MainActor func replaceSpecific(currentExercise: Exercise, with newExercise: Exercise, in template: inout WorkoutTemplate, ctx: AppContext) {
        guard let idx = template.exercises.firstIndex(where: { $0.id == currentExercise.id }) else { return }

        let detailed = Self.detailed(exercise: newExercise, ctx: ctx)

        template.exercises[idx] = detailed
        ctx.userData.updateTemplate(template: template)
    }
    
    @MainActor static func detailed(
        exercise: Exercise,
        exerciseData: ExerciseData,
        equipmentData: EquipmentData,
        userData: UserData
    ) -> Exercise {
        return userData.calculateDetailedExercise(
            exerciseData: exerciseData,
            equipmentData: equipmentData,
            exercise: exercise,
            nextWeek: false
        )
    }
    
    @MainActor static func detailed(exercise: Exercise, ctx: AppContext) -> Exercise {
        return ctx.userData.calculateDetailedExercise(
            exerciseData: ctx.exercises,
            equipmentData: ctx.equipment,
            exercise: exercise,
            nextWeek: false
        )
    }

    /// Remove the exercise entirely.
    func remove(_ exercise: Exercise, from template: inout WorkoutTemplate, user: UserData) -> String {
        template.exercises.removeAll { $0.id == exercise.id }
        removeSupersetForDeletedExercise(exercise, from: &template)
        user.updateTemplate(template: template)
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

    func toggleFavorite(for exerciseId: UUID, userData: UserData) {
        if userData.evaluation.favoriteExercises.contains(exerciseId) {
            userData.evaluation.favoriteExercises.remove(exerciseId)
        } else {
            userData.evaluation.dislikedExercises.remove(exerciseId)   // exclusivity
            userData.evaluation.favoriteExercises.insert(exerciseId)
        }
    }

    func toggleDislike(for exerciseId: UUID, userData: UserData) {
        if userData.evaluation.dislikedExercises.contains(exerciseId) {
            userData.evaluation.dislikedExercises.remove(exerciseId)
        } else {
            userData.evaluation.favoriteExercises.remove(exerciseId)   // exclusivity
            userData.evaluation.dislikedExercises.insert(exerciseId)
        }
    }
    
    /// Establish / clear a 2‑way superset relationship and keep the paired
    /// exercises adjacent. The *edited* exercise stays where it is; the
    /// partner is moved next to it (before if the partner originally came
    /// earlier in the array, after if later).
    ///
    /// Pass `"None"` in `newValue` to clear the superset.
    func handleSupersetSelection(for exercise: inout Exercise, with newValue: String, in template: inout WorkoutTemplate) {
        // ------------------------------------------------------------------
        // Locate "me" (the exercise whose picker just changed)
        // ------------------------------------------------------------------
        guard let myIdx = template.exercises.firstIndex(where: { $0.id == exercise.id }) else {
            print("Superset: edited exercise not found in template.")
            return
        }
        let myID  = exercise.id.uuidString
        var me    = template.exercises[myIdx]   // working copy
        
        // Normalize partner selection
        let newPartnerID: String? = (newValue == "None") ? nil : newValue
        
        // ------------------------------------------------------------------
        // Break OLD link if it's changing
        // ------------------------------------------------------------------
        if let oldID = me.isSupersettedWith, oldID != newPartnerID {
            if let oldPartnerIdx = template.exercises.firstIndex(where: { $0.id.uuidString == oldID }) {
                template.exercises[oldPartnerIdx].isSupersettedWith = nil
            }
            me.isSupersettedWith = nil
        }
        
        // Also clear any stray reverse link pointing *to me* unless it matches newPartnerID
        for i in template.exercises.indices where template.exercises[i].isSupersettedWith == myID && template.exercises[i].id.uuidString != newPartnerID {
            template.exercises[i].isSupersettedWith = nil
        }
        
        // ------------------------------------------------------------------
        // Clearing case → done
        // ------------------------------------------------------------------
        guard let partnerID = newPartnerID else {
            template.exercises[myIdx] = me
            exercise = me
            return
        }
        
        // Prevent self‑link
        if partnerID == myID {
            print("⚠️ Attempted to superset exercise with itself; ignoring.")
            template.exercises[myIdx] = me
            exercise = me
            return
        }
        
        // ------------------------------------------------------------------
        // Find partner
        // ------------------------------------------------------------------
        guard let partnerIdx0 = template.exercises.firstIndex(where: { $0.id.uuidString == partnerID }) else {
            print("⚠️ Superset partner id \(partnerID) not found; clearing link.")
            template.exercises[myIdx] = me
            exercise = me
            return
        }
        var partner = template.exercises[partnerIdx0]
        
        // Break partner's old link if not me
        if let pOld = partner.isSupersettedWith, pOld != myID {
            if let otherIdx = template.exercises.firstIndex(where: { $0.id.uuidString == pOld }) {
                template.exercises[otherIdx].isSupersettedWith = nil
            }
            partner.isSupersettedWith = nil
        }
        
        // ------------------------------------------------------------------
        // Link the two in local copies
        // ------------------------------------------------------------------
        me.isSupersettedWith      = partnerID
        partner.isSupersettedWith = myID
        
        // ------------------------------------------------------------------
        // Reorder so pair is adjacent (move partner next to me)
        // ------------------------------------------------------------------
        var exercises = template.exercises   // temp working array
        
        // Remove partner at its original index
        let removed = exercises.remove(at: partnerIdx0)
        
        if partnerIdx0 < myIdx {
            // Partner was *before* me → insert BEFORE current me index (which shifted -1 after removal)
            // After removal, my exercise has slid back by 1.
            let newMyIdx = myIdx - 1
            exercises.insert(removed, at: newMyIdx)
            
            // After insert: partner at newMyIdx, me at newMyIdx + 1
        } else if partnerIdx0 > myIdx {
            // Partner was *after* me → insert AFTER me (index myIdx + 1; unaffected by removal)
            exercises.insert(removed, at: myIdx + 1)
            // After insert: me at myIdx, partner at myIdx + 1
        } else {
            // Should never happen (same index), but guard anyway
            exercises.insert(removed, at: myIdx + 1)
        }
        
        // ------------------------------------------------------------------
        // Write updated copies back into their final slots
        // ------------------------------------------------------------------
        // Find final indices (post-reorder)
        guard let finalMyIdx = exercises.firstIndex(where: { $0.id.uuidString == myID }) else {
            print("Superset: lost track of edited exercise after reorder.")
            return
        }
        guard let finalPartnerIdx = exercises.firstIndex(where: { $0.id.uuidString == partnerID }) else {
            print("Superset: lost track of partner after reorder.")
            return
        }
        
        exercises[finalMyIdx]      = me
        exercises[finalPartnerIdx] = partner
        
        // Commit back to template & caller
        template.exercises = exercises
        exercise = me
    }
    
    func addNewSet(_ exercise: Exercise, from template: inout WorkoutTemplate, user: UserData) {
        if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }) {
            let newSetNumber = template.exercises[index].workingSets + 1
            let newSet = SetDetail(
                setNumber: newSetNumber,
                load: exercise.loadMetric,
                planned: exercise.plannedMetric
            )
            template.exercises[index].setDetails.append(newSet)
            user.updateTemplate(template: template)
        }
    }
    
    func deleteSet(_ exercise: Exercise, from template: inout WorkoutTemplate, user: UserData) {
        if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }) {
            guard !template.exercises[index].setDetails.isEmpty else { return }
            template.exercises[index].setDetails.removeLast()
            user.updateTemplate(template: template)
        }
    }
}


