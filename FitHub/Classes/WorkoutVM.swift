//
//  WorkoutVM.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation
import SwiftUI


final class WorkoutVM: ObservableObject {
    var template: WorkoutTemplate
    let activeWorkout: WorkoutInProgress?
    let initialElapsedTime: Int?
    var currentExerciseState: CurrentExerciseState?
    var updates: PerformanceUpdates
    var workoutCompleted: Bool = false
    var isOverlayVisible: Bool = true
    var showWorkoutSummary: Bool = false
    var templateCompletedBefore: Bool = false

    init(
        template: WorkoutTemplate,
        activeWorkout: WorkoutInProgress? = nil,
        initialElapsedTime: Int? = nil,
        currentExerciseState: CurrentExerciseState? = nil,
        updatedMax: [PerformanceUpdate]? = nil
    ) {
       self.template = template
       self.activeWorkout = activeWorkout
       self.updates = PerformanceUpdates()
        
        
       if let aw = activeWorkout {
           // ---- resume a paused session ----
           self.initialElapsedTime   = aw.elapsedTime
           self.currentExerciseState = aw.currentExerciseState
           self.updates.updatedMax = aw.updatedMax
       } else {
           // ---- brand-new session ----
           self.initialElapsedTime   = initialElapsedTime
           self.currentExerciseState = currentExerciseState
           self.updates.updatedMax = updatedMax ?? []
       }
   }

    func saveTemplate(userData: UserData, detailBinding: Binding<SetDetail>, exerciseBinding: Binding<Exercise>) {
        // 1) update the SetDetail binding directly
        detailBinding.wrappedValue = detailBinding.wrappedValue

        // 2) mirror back into the master template
        if let exIdx = template.exercises.firstIndex(where: { $0.id == exerciseBinding.wrappedValue.id }) {
            template.exercises[exIdx].setDetails = exerciseBinding.wrappedValue.setDetails
        }

        // 3) persist in UserData
        _ = userData.updateTemplate(template: template)
    }
    
    func setTemplateCompletionStatus(completedWorkouts: [CompletedWorkout]) {
        templateCompletedBefore = completedWorkouts.contains(where: { $0.template.id == template.id })
        print("Template Completed Before: \(templateCompletedBefore)")
    }

    func goToNextSetOrExercise(for exerciseIndex: Int, selectedExerciseIndex: inout Int?, timer: TimerManager) {
        let currentExercise = template.exercises[exerciseIndex]

        // resume timer if inactive
        if !timer.isActive { timer.startTimer() }
        
        // Helper to allocate time when truly leaving an exercise
        func allocateTimeToCurrentExercise(index: Int, exercise: Exercise) {
            let timeSpent = timer.secondsElapsed - (currentExerciseState?.startTime ?? 0)
            template.exercises[index].timeSpent += timeSpent
            currentExerciseState = CurrentExerciseState(id: exercise.id, name: exercise.name, index: index, startTime: timer.secondsElapsed)
            //print("⏱  Allocated \(timeSpent)s to “\(exercise.name)”, new exerciseState=\(currentExerciseState!)")
        }

        // 1) If we're still in warm‑up sets, just advance the set number here
        if currentExercise.currentSet <= currentExercise.warmUpSets {
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
                moveToNextIncompleteExercise(after: supersetIdx - 1, selectedExerciseIndex: &selectedExerciseIndex, timer: timer)
                //print("🔄 switched to superset exercise \(supersetExercise.name)")
            // Otherwise both done, mark complete and move on
            } else {
                //print("\(currentExercise.name) Set: \(currentExercise.currentSet)/\(currentExercise.totalSets)")
                //print("✅ Superset exercise “\(currentExercise.name)” complete")
                allocateTimeToCurrentExercise(index: exerciseIndex, exercise: currentExercise)
                template.exercises[exerciseIndex].isCompleted = true
                moveToNextIncompleteExercise(after: supersetIdx - 1, selectedExerciseIndex: &selectedExerciseIndex, timer: timer)
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
                moveToNextIncompleteExercise(after: exerciseIndex, selectedExerciseIndex: &selectedExerciseIndex, timer: timer)
                if showWorkoutSummary { return }
            }
        }
    }

    private func moveToNextIncompleteExercise(after index: Int, selectedExerciseIndex: inout Int?, timer: TimerManager) {
        // Find the next incomplete exercise starting after the given index
        if let nextExerciseIndex = template.exercises.indices.first(where: { $0 > index && !template.exercises[$0].isCompleted }) {
            setAvgRPE(selectedIndex: selectedExerciseIndex)
            selectedExerciseIndex = nextExerciseIndex
        } else if let anyExerciseIndex = template.exercises.firstIndex(where: { !$0.isCompleted } ) {
            setAvgRPE(selectedIndex: selectedExerciseIndex)
            selectedExerciseIndex = anyExerciseIndex
        } else {
            // No more incomplete exercises, finish the workout
            timer.stopTimer()
            showCompletionAlert()
            return
        }
    }

    private func setAvgRPE(selectedIndex: Int?) {
        guard let selectedIndex = selectedIndex, !templateCompletedBefore else { return }
        
        var exercise = template.exercises[selectedIndex]
        if exercise.isCompleted {
            print("Last set completed of \(exercise.name)")
            
            let hadNewPR = updates.prExerciseIDs.contains(exercise.id)
            exercise.setRPE(hadNewPR: hadNewPR)
            template.exercises[selectedIndex] = exercise
        }
    }

    private func showCompletionAlert() {
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

    func calculateWorkoutSummary(secondsElapsed: Int) -> WorkoutSummaryData {
        // Sum volume (weight × reps), total weight, and total reps.
        // Isometric holds contribute to neither reps nor volume here.
        var totalVolume: Double = 0
        var totalReps:   Int    = 0
        var weightByExercise: [UUID: Double] = [:]

        for exercise in template.exercises {
            for set in exercise.setDetails {
                let w = set.weight.inKg

                // Prefer completed; fall back to planned.
                let metric = set.completed ?? set.planned
                switch metric {
                case .reps(let r):
                    let setVolume: Double = w * Double(r)
                    totalReps   += r
                    totalVolume += setVolume
                    weightByExercise[exercise.id, default: 0] += setVolume
                case .hold:
                    // no-op for reps/volume; holds are time-based
                    break
                }
            }
        }
        let totalTime = TimeSpan.init(seconds: secondsElapsed)
        let exercisePRs = updates.prExerciseIDs

        return WorkoutSummaryData(
            totalVolume: Mass(kg: totalVolume),
            totalReps:   totalReps,
            totalTime:   totalTime,
            exercisePRs: exercisePRs,
            weightByExercise: weightByExercise
        )
    }

    func getExerciseIndex(timer: TimerManager) -> Int {
        // 1) If we’re just starting (timer not running), attempt to resume
        if !timer.isActive {
            // resume from saved time if present
            if let elapsedTime = initialElapsedTime {
                timer.secondsElapsed = elapsedTime
            } 
            timer.startTimer()
            // unwrap the saved state
            if let state = currentExerciseState {
                let resumeIdx = state.index
                // only resume if still valid and not completed
                if template.exercises.indices.contains(resumeIdx),
                   !template.exercises[resumeIdx].isCompleted {
                    return resumeIdx
                }
            }
        }
        // 2) Otherwise Find the first unfinished exercise (or 0 if none)
        return template.exercises.firstIndex(where: { !$0.isCompleted }) ?? 0
    }
    
    func updatePerformance(_ update: PerformanceUpdate) { updates.updatePerformance(update) }
    
    @MainActor
    func saveWorkoutInProgress(userData: UserData, timer: TimerManager) {
        // Create a WorkoutInProgress object to store the current state
        let workoutInProgress = WorkoutInProgress(
            template: template,
            elapsedTime: timer.secondsElapsed,
            currentExerciseState: currentExerciseState,
            dateStarted: Date(),
            updatedMax: updates.updatedMax
        )
        
        // Save this to userData
        userData.sessionTracking.activeWorkout = workoutInProgress
        userData.saveToFileImmediate()
    }

    @MainActor
    func finishWorkoutAndDismiss(ctx: AppContext, timer: TimerManager, completion: () -> Void) {
        var shouldRemoveDate: Bool = false
        let now = Date()
        let roundedDate = CalendarUtility.shared.startOfDay(for: now)
                
        let (shouldIncrement, updatedTemplate) = ctx.userData.removePlannedWorkoutDate(template: template, removeNotifications: true, removeDate: false, date: roundedDate)
        if let updatedTemplate { template = updatedTemplate }
        let completedToday = ctx.userData.workoutPlans.completedWorkouts.contains { workout in         // Check if there's a workout completed today
            CalendarUtility.shared.isDate(workout.date, inSameDayAs: roundedDate)
        }
        
        if !completedToday {
            if shouldIncrement {
                print("Date Found. Incrementing Workout Streak...")
                shouldRemoveDate = true
            } else {
                print("Date not found...")
                print("No workouts completed yet today. Incrementing Workout Streak...")
            }
            ctx.userData.incrementWorkoutStreak(shouldSave: false)
        }
        // save precise date for determing freshness of muscle groups
        let completedWorkout = CompletedWorkout(name: template.name, template: template, updatedMax: updates.updatedMax, duration: timer.secondsElapsed, date: now)
        ctx.userData.workoutPlans.completedWorkouts.append(completedWorkout)         // Append to completedWorkouts and save
        
        endWorkoutAndDismiss(ctx: ctx, timer: timer, shouldRemoveDate: shouldRemoveDate, completion: completion)
    }
        
    @MainActor
    func endWorkoutAndDismiss(ctx: AppContext, timer: TimerManager, shouldRemoveDate: Bool, completion: () -> Void) {
        // update exercise performance
        ctx.exercises.applyPerformanceUpdates(updates: updates.updatedMax, csvEstimate: false)
        
        // Reset timer
        timer.resetTimer()
        timer.stopRest()
        
        // CRITICAL: Reset all workout state atomically
        ctx.userData.resetExercisesInTemplate(for: template, shouldRemoveDate: shouldRemoveDate)
        
        // Force save to ensure state is persisted
        ctx.userData.saveToFile()
        completion()
    }
}
