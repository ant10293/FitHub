//
//  WorkoutVM.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation
import SwiftUI


final class WorkoutVM: ObservableObject {
    @Published var template: WorkoutTemplate
    let activeWorkout: WorkoutInProgress?
    let startDate: Date
    @Published var currentExerciseState: CurrentExerciseState?
    @Published var updates: PerformanceUpdates
    @Published var workoutCompleted: Bool = false
    @Published var isOverlayVisible: Bool = true
    @Published var showWorkoutSummary: Bool = false
    @Published private var completionDuration: Int?

    init(
        template: WorkoutTemplate,
        activeWorkout: WorkoutInProgress? = nil
    ) {
        self.template = template
        self.activeWorkout = activeWorkout
        self.updates = PerformanceUpdates()

        if let aw = activeWorkout {
            // ---- resume a paused session ----
            self.startDate            = aw.dateStarted
            self.currentExerciseState = aw.currentExerciseState
            self.updates.updatedMax   = aw.updatedMax
        } else {
            // ---- brand-new session ----
            self.startDate            = Date()
            self.currentExerciseState = nil
            self.updates.updatedMax   = []
        }
    }
    
    // TODO: we only need the setID and exerciseBinding, no need for detailBinding
    // TODO: this shouldnt be called after moving to next set. should be called for entire template once at the end
    func saveTemplate(userData: UserData, detailBinding: Binding<SetDetail>, exerciseBinding: Binding<Exercise>) {
        // MARK: the template in UserData should only be updated with set load and metric
        // only pass ID for template and exercise because we ONLY want to update changes to set load and metric
        userData.updateTmplExSet(templateID: template.id, exerciseID: exerciseBinding.wrappedValue.id, setDetail: detailBinding.wrappedValue)
    }
    
    func goToNextSetOrExercise(for exerciseIndex: Int, selectedExerciseIndex: inout Int?) {
        let currentExercise = template.exercises[exerciseIndex]
        
        // Helper to allocate time when truly leaving an exercise
        func allocateTimeToCurrentExercise(index: Int, exercise: Exercise) {
            let timeSpent = secondsElapsed - (currentExerciseState?.startTime ?? 0)
            template.exercises[index].timeSpent += timeSpent
            currentExerciseState = CurrentExerciseState(id: exercise.id, name: exercise.name, index: index, startTime: secondsElapsed)
            //print("⏱  Allocated \(timeSpent)s to “\(exercise.name)”, new exerciseState=\(currentExerciseState!)")
        }

        // 1) If we're still in warm‑up sets, just advance the set number here
        if currentExercise.isWarmUp {
            //print("➡️ Still in warm‑ups (set \(currentExercise.currentSet)), just incrementing")
            template.exercises[exerciseIndex].currentSet += 1
            return
        }

        // 2) Now all warm‑ups are done—we can consider supersets
        if let supersetIdString = currentExercise.isSupersettedWith, let supersetIdx = template.exercises.firstIndex(where: { $0.id.uuidString == supersetIdString }) {
            // If main sets remain on this exercise
            if currentExercise.currentSet < currentExercise.totalSets {
                //print("➡️ Main sets remain (\(currentExercise.currentSet)/\(currentExercise.totalSets)), advancing current exercise")
                allocateTimeToCurrentExercise(index: exerciseIndex, exercise: currentExercise)
                template.exercises[exerciseIndex].currentSet += 1
                moveToNextIncompleteExercise(after: supersetIdx - 1, selectedExerciseIndex: &selectedExerciseIndex)
                //print("🔄 switched to superset exercise \(supersetExercise.name)")
            // Otherwise both done, mark complete and move on
            } else {
                //print("\(currentExercise.name) Set: \(currentExercise.currentSet)/\(currentExercise.totalSets)")
                //print("✅ Superset exercise “\(currentExercise.name)” complete")
                allocateTimeToCurrentExercise(index: exerciseIndex, exercise: currentExercise)
                template.exercises[exerciseIndex].isCompleted = true
                moveToNextIncompleteExercise(after: supersetIdx - 1, selectedExerciseIndex: &selectedExerciseIndex)
                if showWorkoutSummary { return }
            }
        } else {
            // 3) No superset configured—just finish this exercise
            if currentExercise.currentSet < currentExercise.totalSets {
                //print("➡️ Finishing remaining sets on “\(currentExercise.name)” (\(currentExercise.currentSet)/\(currentExercise.totalSets))")
                template.exercises[exerciseIndex].currentSet += 1
            } else {
                //print("\(currentExercise.name) Set: \(currentExercise.currentSet)/\(currentExercise.totalSets)")
                //print("✅ “\(currentExercise.name)” fully completed, moving to next incomplete")
                allocateTimeToCurrentExercise(index: exerciseIndex, exercise: currentExercise)
                template.exercises[exerciseIndex].isCompleted = true
                moveToNextIncompleteExercise(after: exerciseIndex, selectedExerciseIndex: &selectedExerciseIndex)
                if showWorkoutSummary { return }
            }
        }
    }

    private func moveToNextIncompleteExercise(after index: Int, selectedExerciseIndex: inout Int?) {
        // Find the next incomplete exercise starting after the given index
        if let nextExerciseIndex = template.exercises.indices.first(where: { $0 > index && !template.exercises[$0].isCompleted }) {
            selectedExerciseIndex = nextExerciseIndex
        } else if let anyExerciseIndex = template.exercises.firstIndex(where: { !$0.isCompleted } ) {
            selectedExerciseIndex = anyExerciseIndex
        } else {
            // No more incomplete exercises, finish the workout
            showCompletionAlert()
            return
        }
    }

    private func showCompletionAlert() {
        completionDuration = secondsElapsed
        isOverlayVisible = false
        showWorkoutSummary = true
        workoutCompleted = true
    }

    func isLastExerciseForIndex(_ exerciseIndex: Int) -> Bool {
        // Check if all other exercises except the current one are completed
        let allOtherExercisesCompleted = template.exercises.indices
            .filter { $0 != exerciseIndex }
            .allSatisfy { template.exercises[$0].isCompleted }
        return allOtherExercisesCompleted
    }

    func calculateWorkoutSummary() -> WorkoutSummaryData {
        template.calculateWorkoutSummary(completionDuration: completionDuration ?? 0, updates: updates)
    }
    
    private var secondsElapsed: Int { CalendarUtility.secondsSince(startDate) }
    
    func performSetup(userData: UserData) -> Int {
        if !userData.isWorkingOut { userData.isWorkingOut = true }
        return getExerciseIndex()
    }
    
    private func getExerciseIndex() -> Int {
        if let state = currentExerciseState, template.exercises.indices.contains(state.index) {
            let resumeIdx = state.index
            // only resume if still valid and not completed
            if !template.exercises[resumeIdx].isCompleted { return resumeIdx }
        }
        // 2) Otherwise Find the first unfinished exercise (or 0 if none)
        if let idx = template.exercises.firstIndex(where: { !$0.isCompleted }) {
            return idx
        } else {
            showCompletionAlert()
            return 0
        }
    }
    
    func updatePerformance(_ update: PerformanceUpdate) { updates.updatePerformance(update) }
    
    @MainActor
    func saveWorkoutInProgress(userData: UserData) {
        // Create a WorkoutInProgress object to store the current state
        let workoutInProgress = WorkoutInProgress(
            template: template,
            currentExerciseState: currentExerciseState,
            dateStarted: startDate,
            updatedMax: updates.updatedMax
        )
        
        // Save this to userData
        userData.sessionTracking.activeWorkout = workoutInProgress
        userData.saveToFile()
    }

    @MainActor
    func finishWorkoutAndDismiss(ctx: AppContext, completion: () -> Void) {
        let now = Date()
        let roundedDate = CalendarUtility.shared.startOfDay(for: now)
        
        // Calculate duration if not already set (e.g., when user exits via back button)
        let finalDuration = completionDuration ?? secondsElapsed
                
        // Check if there was a workout completed today
        let completedToday = ctx.userData.workoutPlans.completedWorkouts.contains { workout in
            CalendarUtility.shared.isDate(workout.date, inSameDayAs: roundedDate)
        }
        
        if !completedToday { ctx.userData.incrementWorkoutStreak() }
        
        ctx.userData.removePlannedWorkoutDate(templateID: template.id, date: roundedDate)
                        
        let completedWorkout = CompletedWorkout(template: template, updatedMax: updates.updatedMax, duration: finalDuration, date: now)
        ctx.userData.workoutPlans.completedWorkouts.append(completedWorkout)
        
        endWorkoutAndDismiss(ctx: ctx, completion: completion)
    }
        
    @MainActor
    func endWorkoutAndDismiss(ctx: AppContext, completion: () -> Void) {
        // update exercise performance
        ctx.exercises.applyPerformanceUpdates(updates: updates.updatedMax, csvEstimate: false)
        
        // CRITICAL: Reset all workout state atomically
        ctx.userData.resetWorkoutSession()
        
        ctx.userData.saveToFile()
        
        completion()
    }
}
