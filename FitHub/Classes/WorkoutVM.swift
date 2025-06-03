//
//  WorkoutViewModel.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation
import SwiftUI

class WorkoutViewModel: ObservableObject {
     var template: WorkoutTemplate
     var currentSet: Int = 1
     var currentExerciseState: CurrentExerciseState?
     var updatedMax: [PerformanceUpdate]
     var isWorkoutingOut: Bool = false
     var workoutCompleted: Bool = false
     var isOverlayVisible: Bool = true
     var showWorkoutSummary: Bool = false

    init(template: WorkoutTemplate, currentExerciseState: CurrentExerciseState? = nil, updatedMax: [PerformanceUpdate]? = nil) {
        self.template = template
        self.currentExerciseState = currentExerciseState
        self.updatedMax = updatedMax ?? []
    }
    
    func saveTemplate(userData: UserData, detailBinding: Binding<SetDetail>, exerciseBinding: Binding<Exercise>) {
        // 1) update the SetDetail binding directly
        detailBinding.wrappedValue = detailBinding.wrappedValue

        // 2) mirror back into the master template
        if let exIdx = template.exercises.firstIndex(where: { $0.id == exerciseBinding.wrappedValue.id }) {
            template.exercises[exIdx].setDetails = exerciseBinding.wrappedValue.setDetails
        }

        // 3) persist in UserData
        userData.saveTemplate(template: template)
    }
    
    func goToNextSetOrExercise(for exerciseIndex: Int, selectedExerciseIndex: inout Int?, timerManager: TimerManager) {
        let currentExercise = template.exercises[exerciseIndex]
        let warmCount = currentExercise.warmUpSets
        //print("🔄 goToNextSetOrExercise for index \(exerciseIndex) (“\(currentExercise.name)”), currentSet=\(currentExercise.currentSet), warmUpSets=\(warmCount)")

        // resume timer if inactive
        if !timerManager.timerIsActive { timerManager.startTimer() }
        
        // Helper to allocate time when truly leaving an exercise
        func allocateTimeToCurrentExercise(index: Int, exercise: Exercise) {
            let timeSpent = timerManager.secondsElapsed - (currentExerciseState?.startTime ?? 0)
            template.exercises[index].timeSpent += timeSpent
            currentExerciseState = CurrentExerciseState(id: exercise.id, name: exercise.name, index: index, startTime: timerManager.secondsElapsed)
            //print("⏱  Allocated \(timeSpent)s to “\(exercise.name)”, new exerciseState=\(currentExerciseState!)")
        }

        // 1) If we're still in warm‑up sets, just advance the set number here
        if currentExercise.currentSet <= warmCount {
            //print("➡️ Still in warm‑ups (set \(currentExercise.currentSet)), just incrementing")
            template.exercises[exerciseIndex].currentSet += 1
            return
        }

        // 2) Now all warm‑ups are done—we can consider supersets
        if let supersetName = currentExercise.isSupersettedWith,
           let supersetIdx = template.exercises.firstIndex(where: { $0.name == supersetName }) {
            let supersetExercise = template.exercises[supersetIdx]
            //print("🤝 Superset partner found: “\(supersetExercise.name)” at index \(supersetIdx), its currentSet=\(supersetExercise.currentSet)")

            // If main sets remain on this exercise
            if currentExercise.currentSet < currentExercise.totalSets {
                //print("➡️ Main sets remain (\(currentExercise.currentSet)/\(currentExercise.totalSets)), advancing current exercise")
                template.exercises[exerciseIndex].currentSet += 1
                allocateTimeToCurrentExercise(index: exerciseIndex, exercise: currentExercise)
                selectedExerciseIndex = supersetIdx // the exercise switches after this line
                //print("🔄 switched to superset exercise \(supersetExercise.name)")
                
                allocateTimeToCurrentExercise(index: supersetIdx, exercise: supersetExercise)

            // Otherwise both done, mark complete and move on
            } else {
                /*print("Set: \(currentExercise.currentSet)/\(currentExercise.totalSets)")
                print("✅ Superset done, marking “\(currentExercise.name)” complete")*/
                allocateTimeToCurrentExercise(index: exerciseIndex, exercise: currentExercise)
                template.exercises[exerciseIndex].isCompleted = true
                moveToNextIncompleteExercise(after: exerciseIndex, selectedExerciseIndex: &selectedExerciseIndex, timerManager: timerManager)
            }
        } else {
            // 3) No superset configured—just finish this exercise
            if currentExercise.currentSet < currentExercise.totalSets {
                //print("➡️ Finishing remaining sets on “\(currentExercise.name)” (\(currentExercise.currentSet)/\(currentExercise.totalSets))")
                template.exercises[exerciseIndex].currentSet += 1
            } else {
                /*print("Set: \(currentExercise.currentSet)/\(currentExercise.totalSets)")
                print("✅ “\(currentExercise.name)” fully completed, moving to next incomplete")*/
                allocateTimeToCurrentExercise(index: exerciseIndex, exercise: currentExercise)
                template.exercises[exerciseIndex].isCompleted = true
                moveToNextIncompleteExercise(after: exerciseIndex, selectedExerciseIndex: &selectedExerciseIndex, timerManager: timerManager)
            }
        }
    }
    
    private func moveToNextIncompleteExercise(after index: Int, selectedExerciseIndex: inout Int?, timerManager: TimerManager) {
        // Find the next incomplete exercise starting after the given index
        if let nextExerciseIndex = template.exercises.indices.first(where: { $0 > index && !template.exercises[$0].isCompleted }) {
            selectedExerciseIndex = nextExerciseIndex
        } else {
            // No more incomplete exercises, finish the workout
            timerManager.stopTimer()
            showCompletionAlert()
        }
    }
    
    private func showCompletionAlert() {
        isOverlayVisible = false
        showWorkoutSummary = true
        workoutCompleted = true
    }
    
    func canCompleteSet() -> Bool {
        template.exercises.allSatisfy { $0.sets >= currentSet }
    }
    
    func maximumSets() -> Int {
        template.exercises.map { $0.sets }.max() ?? 1
    }
    
    func isLastExerciseForIndex(_ exerciseIndex: Int) -> Bool {
        // Check if all other exercises except the current one are completed
        let allOtherExercisesCompleted = template.exercises.indices
            .filter { $0 != exerciseIndex }
            .allSatisfy { template.exercises[$0].isCompleted }
        
        return allOtherExercisesCompleted
    }
    
    func getPRExercises() -> [String] {
        var exercisePRs: [String] = []
        
        for update in updatedMax {
            exercisePRs.append(update.exerciseName)
        }
        
        return exercisePRs
    }
    
    func calculateWorkoutSummary(timerManager: TimerManager) -> (totalVolume: Double, totalWeight: Double, totalReps: Int, totalTime: String, exercisePRs: [String]) {
        let totalVolume = template.exercises.reduce(0) { total, exercise in
            total + exercise.setDetails.reduce(0) { $0 + $1.weight * Double($1.reps) }
        }
        
        let totalWeight = template.exercises.reduce(0) { total, exercise in
            total + exercise.setDetails.reduce(0) { $0 + $1.weight }
        }
        
        let totalReps = template.exercises.reduce(0) { total, exercise in
            total + exercise.setDetails.reduce(0) { $0 + $1.reps }
        }
        
        let totalTime = timeString(from: timerManager.secondsElapsed)
        
        let exercisePRs = getPRExercises()
        
        return (totalVolume, totalWeight, totalReps, totalTime, exercisePRs)
    }
    
    func getExerciseIndex(timerManager: TimerManager) -> Int {
        //print("Timer Active: \(timerManager.timerIsActive)")

        // 1) If we’re just starting (timer not running), attempt to resume
        if !timerManager.timerIsActive {
            timerManager.startTimer()
            // unwrap the saved state
            if let state = currentExerciseState {
                let resumeIdx = state.index
                // only resume if still valid and not completed
                if template.exercises.indices.contains(resumeIdx),
                   !template.exercises[resumeIdx].isCompleted {
                    return resumeIdx
                }
            }
            // otherwise fall through to pick first unfinished
        }
        // 2) Find the first unfinished exercise (or 0 if none)
        return template.exercises.firstIndex(where: { !$0.isCompleted }) ?? 0
    }
    
    func getIndex(exercise: Exercise) -> Int {
        return template.exercises.firstIndex(where: { $0.name == exercise.name }) ?? 0
    }
    
    func getExerciseCount() -> Int {
        return template.exercises.count
    }
    
    func updatePerformance(_ exerciseName: String, _ newValue: Double, _ repsXWeight: RepsXWeight, _ setNumber: Int) {
        if let index = updatedMax.firstIndex(where: { $0.exerciseName == exerciseName }) {
            // Overwrite existing record if necessary
            if updatedMax[index].value < newValue {
                updatedMax[index].value = newValue
                updatedMax[index].repsXweight = repsXWeight
                updatedMax[index].setNumber = setNumber
            }
        } else {
            // Add new record
            let newUpdate = PerformanceUpdate(exerciseName: exerciseName, value: newValue, repsXweight: repsXWeight, setNumber: setNumber)
            updatedMax.append(newUpdate)
        }
    }
    
    func saveWorkoutInProgress(userData: UserData, timerManager: TimerManager) {
        let now = Date()
        
        // Create a WorkoutInProgress object to store the current state
        let workoutInProgress = WorkoutInProgress(
            template: template,
            elapsedTime: timerManager.secondsElapsed,
            currentExerciseState: currentExerciseState,
            dateStarted: now,
            exercises: template.exercises,
            updatedMax: updatedMax
        )
        
        // Save this to userData
        userData.activeWorkout = workoutInProgress
        //userData.saveSingleVariableToFile(\.activeWorkout, for: .activeWorkout)
        userData.saveToFileImmediate()
    }
    
    func finishWorkoutAndDismiss(userData: UserData, exerciseData: ExerciseData, timerManager: TimerManager) -> Bool {
        var isDone: Bool = false
        var shouldRemoveNotifications = false
        let now = Date()
        let calendar = Calendar.current
        let roundedDate = calendar.startOfDay(for: now)
                
        let shouldIncrement = userData.removePlannedWorkoutDate(template: template, date: roundedDate)
        let completedToday = userData.completedWorkouts.contains { workout in         // Check if there's a workout completed today
            calendar.isDate(workout.date, inSameDayAs: roundedDate)
        }
        
        if !completedToday {
            if shouldIncrement {
                print("Date Found. Incrementing Workout Streak...")
                shouldRemoveNotifications = true
            } else {
                print("Date not found...")
                print("No workouts completed yet today. Incrementing Workout Streak...")
            }
            userData.incrementWorkoutStreak(shouldSave: false)
        }
        // save precise date for determing freshness of muscle groups
        let completedWorkout = CompletedWorkout(name: template.name, template: template, updatedMax: updatedMax, duration: timerManager.secondsElapsed, date: Date())
        userData.completedWorkouts.append(completedWorkout)         // Append to completedWorkouts and save
        userData.saveToFile()
        
        if endWorkoutAndDismiss(userData: userData, exerciseData: exerciseData, shouldRemoveNotifications: shouldRemoveNotifications, timerManager: timerManager) {
            isDone = true
        }
        return isDone
    }
    
    func endWorkoutAndDismiss(userData: UserData, exerciseData: ExerciseData, shouldRemoveNotifications: Bool, timerManager: TimerManager) -> Bool {
        // update exercise performance
        if !updatedMax.isEmpty {
            for performanceUpdate in updatedMax {
                if let repsWeight = performanceUpdate.repsXweight {
                    let reps = repsWeight.reps
                    let weight = repsWeight.weight
                    exerciseData.updateExercisePerformance(for: performanceUpdate.exerciseName, newValue: performanceUpdate.value, reps: reps, weight: weight, csvEstimate: false)
                } else {
                    exerciseData.updateExercisePerformance(for: performanceUpdate.exerciseName, newValue: performanceUpdate.value, reps: nil, weight: nil, csvEstimate: false)
                }
            }
            exerciseData.savePerformanceData()
        }
        
        timerManager.resetTimer()
        timerManager.stopRest()
        userData.resetExercisesInTemplate(for: template, shouldRemoveNotifications: shouldRemoveNotifications)
        
        return true
    }
}
