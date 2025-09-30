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
    let startDate: Date
    let workoutsStartDate: Date? // for week of templates
    var currentExerciseState: CurrentExerciseState?
    var updates: PerformanceUpdates
    var workoutCompleted: Bool = false
    var isOverlayVisible: Bool = true
    var showWorkoutSummary: Bool = false
    @Published private var completionDuration: Int = 0

    init(
        template: WorkoutTemplate,
        activeWorkout: WorkoutInProgress? = nil,
        startDate: Date = Date(),
        workoutsStartDate: Date?,
        currentExerciseState: CurrentExerciseState? = nil,
        updatedMax: [PerformanceUpdate]? = nil
    ) {
        self.template = template
        self.activeWorkout = activeWorkout
        self.updates = PerformanceUpdates()
        self.workoutsStartDate = workoutsStartDate

        if let aw = activeWorkout {
            // ---- resume a paused session ----
            self.startDate            = aw.dateStarted
            self.currentExerciseState = aw.currentExerciseState
            self.updates.updatedMax   = aw.updatedMax
        } else {
            // ---- brand-new session ----
            self.startDate            = startDate
            self.currentExerciseState = currentExerciseState
            self.updates.updatedMax   = updatedMax ?? []
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

    func goToNextSetOrExercise(for exerciseIndex: Int, selectedExerciseIndex: inout Int?) {
        let currentExercise = template.exercises[exerciseIndex]

        // resume timer if inactive
        //if !timer.isActive { timer.startTimer(startDate: startDate) }
        
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
            setAvgRPE(selectedIndex: selectedExerciseIndex)
            selectedExerciseIndex = nextExerciseIndex
        } else if let anyExerciseIndex = template.exercises.firstIndex(where: { !$0.isCompleted } ) {
            setAvgRPE(selectedIndex: selectedExerciseIndex)
            selectedExerciseIndex = anyExerciseIndex
        } else {
            // No more incomplete exercises, finish the workout
            //timer.stopTimer()
            completionDuration = secondsElapsed
            showCompletionAlert()
            return
        }
    }

    private func setAvgRPE(selectedIndex: Int?) {
        guard let selectedIndex = selectedIndex else { return }
        
        if var exercise = template.exercises[safe: selectedIndex], let startDate = workoutsStartDate, exercise.isCompleted {
            print("Last set completed of \(exercise.name)")
            
            let hadNewPR = updates.prExerciseIDs.contains(exercise.id)
            
            exercise.setRPE(hadNewPR: hadNewPR, startDate: startDate)
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

    func calculateWorkoutSummary() -> WorkoutSummaryData {
        var totalVolume: Double = 0
        var totalReps:   Int    = 0
        var weightByExercise: [UUID: Double] = [:]

        for exercise in template.exercises {
            let mv = exercise.limbMovementType

            // unilateral → reps × 2; bilateralIndependent → weight × 2
            let repsMul: Int = {
                switch mv {
                case .unilateral: return 2
                default:          return 1
                }
            }()

            let wtMul: Double = {
                switch mv {
                case .bilateralIndependent: return 2
                default:                    return 1
                }
            }()

            for set in exercise.setDetails {
                let setWeight = set.load.weight?.inKg ?? 0
                let adjustedWeight = setWeight * wtMul
                let metric = set.completed ?? set.planned

                switch metric {
                case .reps(let r):
                    let adjustedReps = r * repsMul
                    let setVolume = adjustedWeight * Double(adjustedReps)

                    totalReps += adjustedReps
                    totalVolume += setVolume
                    weightByExercise[exercise.id, default: 0] += setVolume

                case .hold:
                    // holds are time-based → no reps/volume contribution
                    break
                case .cardio:
                    break
                }
            }
        }

        return WorkoutSummaryData(
            totalVolume: Mass(kg: totalVolume),
            totalReps: totalReps,
            totalTime: TimeSpan(seconds: completionDuration),
            exercisePRs: updates.prExerciseIDs,
            weightByExercise: weightByExercise
        )
    }
    
    private var secondsElapsed: Int { CalendarUtility.secondsSince(startDate) }
    
    func performSetup(userData: UserData) -> Int {
        if !userData.isWorkingOut { userData.isWorkingOut = true }
        //if !timer.isActive { timer.startTimer(startDate: startDate) }
        return getExerciseIndex()
    }
    
    private func getExerciseIndex() -> Int {
        if let state = currentExerciseState {
            let resumeIdx = state.index
            // only resume if still valid and not completed
            guard template.exercises.indices.contains(resumeIdx) else { return 0 }
            if !template.exercises[resumeIdx].isCompleted { return resumeIdx }
        }
        
        // 2) Otherwise Find the first unfinished exercise (or 0 if none)
        return template.exercises.firstIndex(where: { !$0.isCompleted }) ?? 0
    }
    
    func updatePerformance(_ update: PerformanceUpdate) { updates.updatePerformance(update) }
    
    @MainActor
    func saveWorkoutInProgress(userData: UserData) {
        // Create a WorkoutInProgress object to store the current state
        let workoutInProgress = WorkoutInProgress(
            template: template, // this doesnt save the updated template.still works because we only use it to find the actual template in trainer or user list
            currentExerciseState: currentExerciseState,
            dateStarted: startDate,
            updatedMax: updates.updatedMax
        )
        
        // Save this to userData
        userData.sessionTracking.activeWorkout = workoutInProgress
        userData.saveToFileImmediate()
    }

    @MainActor
    func finishWorkoutAndDismiss(ctx: AppContext, completion: () -> Void) {
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
        let completedWorkout: CompletedWorkout = .init(template: template, updatedMax: updates.updatedMax, duration: completionDuration, date: now)
        ctx.userData.workoutPlans.completedWorkouts.append(completedWorkout)         // Append to completedWorkouts and save
        
        endWorkoutAndDismiss(ctx: ctx, shouldRemoveDate: shouldRemoveDate, completion: completion)
    }
        
    @MainActor
    func endWorkoutAndDismiss(ctx: AppContext, shouldRemoveDate: Bool, completion: () -> Void) {
        // update exercise performance
        ctx.exercises.applyPerformanceUpdates(updates: updates.updatedMax, csvEstimate: false)
        
        // Reset timer
        //timer.stopAll()
        
        // CRITICAL: Reset all workout state atomically
        ctx.userData.resetExercisesInTemplate(for: template, shouldRemoveDate: shouldRemoveDate)
        
        // Force save to ensure state is persisted
        ctx.userData.saveToFile()
        completion()
    }
}
