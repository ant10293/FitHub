//
//  ChangeLog.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/9/25.
//

import Foundation

extension WorkoutGenerator {
    func generateChangelog(
        input: Input,
        params: GenerationParameters,
        templates: [WorkoutTemplate],
        generationStartTime: Date
    ) -> WorkoutChangelog? {
        
        // Only generate changelog for next week workouts
        guard input.nextWeek else { return nil }
        
        let generationTime = Date().timeIntervalSince(generationStartTime)
        
        let templateChangelogs = templates.enumerated().map { index, newTemplate in
            createTemplateChangelog(
                dayIndex: index,
                newTemplate: newTemplate,
                previousTemplate: getPreviousTemplate(for: index, from: input.saved),
                input: input
            )
        }
        
        let stats = GenerationStats(
            totalGenerationTime: generationTime,
            exercisesSelected: templates.flatMap { $0.exercises }.count,
            exercisesKept: countExercises(for: .kept, templates: templates, saved: input.saved),
            exercisesChanged: countExercises(for: .changed, templates: templates, saved: input.saved),
            performanceUpdates: maxUpdates.count, // Use tracked state instead of countActualMaxUpdates
            progressiveOverloadApplied: overloadingExercises.count, // Use tracked state
            deloadsApplied: deloadingExercises.count // Use tracked state
        )
        
        return WorkoutChangelog(
            generationDate: Date(),
            weekStartDate: params.startDate,
            isNextWeek: input.nextWeek,
            templates: templateChangelogs,
            generationStats: stats
        )
    }
    
    private func createTemplateChangelog(
        dayIndex: Int,
        newTemplate: WorkoutTemplate,
        previousTemplate: WorkoutTemplate?,
        input: Input
    ) -> TemplateChangelog {
        
        let changes = newTemplate.exercises.map { newExercise in
            createExerciseChange(
                newExercise: newExercise,
                previousExercise: findPreviousExercise(newExercise, in: previousTemplate),
                input: input
            )
        }
        
        let metadata = TemplateMetadata(
            estimatedDuration: newTemplate.estimatedCompletionTime,
            totalSets: newTemplate.exercises.flatMap { $0.setDetails }.count,
            totalVolume: calculateTotalVolume(newTemplate),
            categories: newTemplate.categories
        )
        
        return TemplateChangelog(
            dayName: newTemplate.name,
            dayIndex: dayIndex,
            previousTemplate: previousTemplate,
            newTemplate: newTemplate,
            changes: changes,
            metadata: metadata
        )
    }
    
    // Update your existing createExerciseChange method:
    private func createExerciseChange(
        newExercise: Exercise,
        previousExercise: Exercise?,
        input: Input
    ) -> ExerciseChange {
        
        let changeType = determineChangeType(new: newExercise, previous: previousExercise)
        let progressionDetails = createProgressionDetails(new: newExercise, input: input)
        
        // NEW: Add max record information
        let maxRecordInfo = createMaxRecordInfo(exercise: newExercise, input: input)
        
        return ExerciseChange(
            exerciseName: newExercise.name,
            changeType: changeType,
            previousExercise: previousExercise,
            newExercise: newExercise,
            progressionDetails: progressionDetails,
            maxRecordInfo: maxRecordInfo // NEW: Add this
        )
    }

    private func createMaxRecordInfo(exercise: Exercise, input: Input) -> MaxRecordInfo {
        let currentMax   = input.exerciseData.getMax(for: exercise.id)
        let csvEstimate  = input.exerciseData.estimatedPeakMetric(for: exercise.id)

        let lastUpdated = currentMax?.date
        let daysSinceLastUpdate: Int?

        if let lastUpdate = lastUpdated {
            let startOfLastUpdate = CalendarUtility.shared.startOfDay(for: lastUpdate)
            let startOfToday      = CalendarUtility.shared.startOfDay(for: Date())
            let comps = CalendarUtility.shared.dateComponents([.day], from: startOfLastUpdate, to: startOfToday)
            daysSinceLastUpdate = max(0, comps.day ?? 0)   // clamp if somehow in the future
        } else {
            daysSinceLastUpdate = nil
        }

        return MaxRecordInfo(
            currentMax: currentMax,
            csvEstimate: csvEstimate,
            lastUpdated: lastUpdated,
            daysSinceLastUpdate: daysSinceLastUpdate
        )
    }
    
    private func determineChangeType(new: Exercise, previous: Exercise?) -> ExerciseChange.ChangeType {
        guard let previous = previous else { return .new }
        
        if new.name == previous.name {
            // Same exercise, check if modified
            return hasSignificantChanges(new: new, previous: previous) ? .modified : .kept
        } else {
            return .replaced
        }
    }
}

// Add these methods to the WorkoutGenerator extension
extension WorkoutGenerator {
    // Helper to get previous template for comparison
    private func getPreviousTemplate(for dayIndex: Int, from saved: [OldTemplate]) -> WorkoutTemplate? {
        guard dayIndex < saved.count else { return nil }
        
        let exercises = saved[dayIndex].exercises
        guard !exercises.isEmpty else { return nil }
        
        // Create a minimal template for comparison
        return WorkoutTemplate(
            name: "Previous \(dayIndex + 1)",
            exercises: exercises,
            categories: [], // We don't need categories for comparison
            dayIndex: dayIndex
        )
    }
    
    // Count exercises that were changed/replaced
    private enum CountVariants { case kept, changed }
    
    private func countExercises(for type: CountVariants, templates: [WorkoutTemplate], saved: [OldTemplate]) -> Int {
        var count = 0
        for (index, template) in templates.enumerated() {
            if index < saved.count {
                let savedNames = Set(saved[index].exercises.map(\.name))
                let exercises: [Exercise]
                switch type {
                case .kept: exercises = template.exercises.filter { savedNames.contains($0.name) }
                case .changed: exercises = template.exercises.filter { !savedNames.contains($0.name) }
                }
                count += exercises.count
            }
        }
        return count
    }
    
    // Find previous exercise for comparison
    private func findPreviousExercise(_ newExercise: Exercise, in previousTemplate: WorkoutTemplate?) -> Exercise? {
        guard let previous = previousTemplate else { return nil }
        return previous.exercises.first { $0.id == newExercise.id }
    }
    
    // Check if exercise has significant changes
    private func hasSignificantChanges(new: Exercise, previous: Exercise) -> Bool {
        // Compare set details
        if new.setDetails.count != previous.setDetails.count { return true }
        
        for (newSet, prevSet) in zip(new.setDetails, previous.setDetails) {
            if newSet.load != prevSet.load { return true }
            if newSet.planned.actualValue != prevSet.planned.actualValue { return true }
        }
        
        return false
    }

    // Calculate total volume for template
    private func calculateTotalVolume(_ template: WorkoutTemplate) -> Mass {
        let summary = template.calculateWorkoutSummary()
        return summary.totalVolume
    }
    
    // Create progression details
    private func createProgressionDetails(new: Exercise, input: Input) -> ProgressionDetails? {
        let s = input.user.settings
        let stagnationLimit = s.periodUntilDeload
        let olPeriod       = s.progressiveOverloadPeriod   // full overload cycle length

        let progressionType: ProgressionDetails.ProgressionType
        let appliedChange: String

        if maxUpdates.contains(new.id) {
            progressionType = .prUpdate
            appliedChange = "New PR since last generation. Set Details recalculated using new PR."
        }
        else if overloadingExercises.contains(new.id) {
            // Overload happened this tick
            let step = new.overloadProgress
            progressionType = .progressiveOverload
            appliedChange = "Progressive overload applied (Week \(step)/\(olPeriod))"
        }
        else if deloadingExercises.contains(new.id) {
            // Deload happened due to stagnation threshold
            progressionType = .deload
            appliedChange = "Deload applied after reaching stagnation threshold (\(stagnationLimit) weeks)"
        }
        else if endedDeloadExercises.contains(new.id) {
            progressionType = .endedDeload
            appliedChange = "Deload complete. Restoring previous working weights."
        }
        else if resetExercises.contains(new.id) {
            // Typically new PR → reset
            progressionType = .reset
            appliedChange = "Progression reset"
        }
        else if new.weeksStagnated >= stagnationLimit, s.allowDeloading == false {
            // Edge case: deloads disabled → we can sit at/above limit
            progressionType = .stagnation
            appliedChange = "Weeks stagnated: \(new.weeksStagnated)/\(stagnationLimit) (at limit; deloads disabled)"
        }
        else if new.weeksStagnated > 0 {
            // Normal stagnation increment
            progressionType = .stagnation
            appliedChange = "Weeks stagnated: \(new.weeksStagnated)/\(stagnationLimit)"
        }
        else {
            progressionType = .none
            appliedChange = "No progression changes"
        }

        return ProgressionDetails(
            progressionType: progressionType,
            // If overload applied, new.overloadProgress already includes the new step; otherwise it’s unchanged.
            previousWeek: max(0, new.overloadProgress - 1),
            newWeek: new.overloadProgress,
            stagnationWeeks: new.weeksStagnated,
            appliedChange: appliedChange
        )
    }
}
