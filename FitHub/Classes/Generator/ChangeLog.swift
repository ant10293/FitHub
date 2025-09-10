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
        generationStartTime: Date,
        performanceUpdates: PerformanceUpdates
    ) -> WorkoutChangelog? {
        
        // Only generate changelog for next week workouts
        guard input.nextWeek else { return nil }
        
        let generationTime = Date().timeIntervalSince(generationStartTime)
        
        let templateChangelogs = templates.enumerated().map { index, newTemplate in
            createTemplateChangelog(
                dayIndex: index,
                newTemplate: newTemplate,
                previousTemplate: getPreviousTemplate(for: index, from: input.savedExercises),
                input: input
            )
        }
        
        let stats = GenerationStats(
            totalGenerationTime: generationTime,
            exercisesSelected: templates.flatMap { $0.exercises }.count,
            exercisesKept: countKeptExercises(templates: templates, saved: input.savedExercises),
            exercisesChanged: countChangedExercises(templates: templates, saved: input.savedExercises),
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
        let setChanges = createSetChanges(new: newExercise, previous: previousExercise)
        let progressionDetails = createProgressionDetails(new: newExercise, input: input)
        
        // NEW: Add max record information
        let maxRecordInfo = createMaxRecordInfo(exercise: newExercise, input: input)
        
        return ExerciseChange(
            exerciseName: newExercise.name,
            changeType: changeType,
            previousExercise: previousExercise,
            newExercise: newExercise,
            setChanges: setChanges,
            progressionDetails: progressionDetails,
            maxRecordInfo: maxRecordInfo // NEW: Add this
        )
    }

    private func createMaxRecordInfo(exercise: Exercise, input: Input) -> MaxRecordInfo {
        let currentMax = input.exerciseData.getMax(for: exercise.id)
        let csvEstimate = input.exerciseData.estimatedPeakMetric(for: exercise.id)
        
        let lastUpdated = currentMax?.date
        let weeksSinceLastUpdate: Int?
        
        if let lastUpdate = lastUpdated {
            let startOfLastUpdate = CalendarUtility.shared.startOfDay(for: lastUpdate)
            let startOfToday = CalendarUtility.shared.startOfDay(for: Date())
            let components = CalendarUtility.shared.dateComponents([.weekOfYear], from: startOfLastUpdate, to: startOfToday)
            weeksSinceLastUpdate = max(0, components.weekOfYear ?? 0)
        } else {
            weeksSinceLastUpdate = nil
        }
        
        return MaxRecordInfo(
            currentMax: currentMax,
            csvEstimate: csvEstimate,
            lastUpdated: lastUpdated,
            weeksSinceLastUpdate: weeksSinceLastUpdate
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
    
    private func createSetChanges(new: Exercise, previous: Exercise?) -> [SetChange] {
        guard let previous = previous else {
            // New exercise - all sets are new
            return new.setDetails.map { set in
                SetChange(
                    setNumber: set.setNumber,
                    previousSet: nil,
                    newSet: set,
                    weightChange: nil,
                    metricChange: nil
                )
            }
        }
        
        return new.setDetails.map { newSet in
            let previousSet = previous.setDetails.first { $0.setNumber == newSet.setNumber }
            
            let weightChange = createWeightChange(new: newSet, previous: previousSet)
            let metricChange = createMetricChange(new: newSet, previous: previousSet)
            
            return SetChange(
                setNumber: newSet.setNumber,
                previousSet: previousSet,
                newSet: newSet,
                weightChange: weightChange,
                metricChange: metricChange
            )
        }
    }

    // Better approach - make the method safer:
    // Fix the createWeightChange method:
    private func createWeightChange(new: SetDetail, previous: SetDetail?) -> SetChange.WeightChange? {
        guard let previous = previous else { return nil }
        
        // Since weight is not optional, we can access it directly
        let newWeight = new.weight.inKg
        let prevWeight = previous.weight.inKg
        
        // Check if weights are different
        guard newWeight != prevWeight else { return nil }
        
        let percentageChange = ((newWeight - prevWeight) / prevWeight) * 100
        
        return SetChange.WeightChange(
            previous: new.weight,      // Direct access, no unwrapping needed
            new: previous.weight,      // Direct access, no unwrapping needed
            percentageChange: abs(percentageChange),
            isIncrease: newWeight > prevWeight
        )
    }
    
    private func createMetricChange(new: SetDetail, previous: SetDetail?) -> SetChange.MetricChange? {
        guard let previous = previous else { return nil }
        
        let newValue = new.planned.actualValue
        let prevValue = previous.planned.actualValue
        
        guard newValue != prevValue else { return nil }
        
        let percentageChange = ((newValue - prevValue) / prevValue) * 100
        let isReps = new.planned.repsValue != nil
        
        return SetChange.MetricChange(
            previous: previous.planned,
            new: new.planned,
            isReps: isReps,
            previousValue: prevValue,
            newValue: newValue,
            percentageChange: abs(percentageChange)
        )
    }
}

// Add these methods to the WorkoutGenerator extension
extension WorkoutGenerator {
    // Helper to get previous template for comparison
    private func getPreviousTemplate(for dayIndex: Int, from savedExercises: [[Exercise]]) -> WorkoutTemplate? {
        guard dayIndex < savedExercises.count else { return nil }
        
        let exercises = savedExercises[dayIndex]
        guard !exercises.isEmpty else { return nil }
        
        // Create a minimal template for comparison
        return WorkoutTemplate(
            name: "Previous \(dayIndex + 1)",
            exercises: exercises,
            categories: [], // We don't need categories for comparison
            dayIndex: dayIndex,
            date: Date()
        )
    }
    
    // Count exercises that were kept from previous week
    private func countKeptExercises(templates: [WorkoutTemplate], saved: [[Exercise]]) -> Int {
        var count = 0
        for (index, template) in templates.enumerated() {
            if index < saved.count {
                let savedNames = Set(saved[index].map(\.name))
                let kept = template.exercises.filter { savedNames.contains($0.name) }
                count += kept.count
            }
        }
        return count
    }
    
    // Count exercises that were changed/replaced
    private func countChangedExercises(templates: [WorkoutTemplate], saved: [[Exercise]]) -> Int {
        var count = 0
        for (index, template) in templates.enumerated() {
            if index < saved.count {
                let savedNames = Set(saved[index].map(\.name))
                let changed = template.exercises.filter { !savedNames.contains($0.name) }
                count += changed.count
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
            if newSet.weight.inKg != prevSet.weight.inKg { return true }
            if newSet.planned.actualValue != prevSet.planned.actualValue { return true }
        }
        
        return false
    }
    
    // Calculate total volume for template
    private func calculateTotalVolume(_ template: WorkoutTemplate) -> Double {
        template.exercises.reduce(0.0) { total, exercise in
            total + exercise.setDetails.reduce(0.0) { setTotal, set in
                setTotal + (set.weight.inKg) * set.planned.actualValue
            }
        }
    }
    
    // Create progression details
    private func createProgressionDetails(new: Exercise, input: Input) -> ProgressionDetails? {
        let progressionType: ProgressionDetails.ProgressionType
        let appliedChange: String
        
        // must also show when weekStagnated is incremented, show weeks stagnated compared to stagnationPeriod
        if overloadingExercises.contains(new.id) {
            progressionType = .progressiveOverload
            appliedChange = "Progressive overload applied (Week \(new.overloadProgress))"
        } else if deloadingExercises.contains(new.id) {
            progressionType = .deload
            // Use prevRPEs.count to show how many weeks led to deload
            if let prevRPEs = new.previousWeeksAvgRPE {
                appliedChange = "Deload applied after \(prevRPEs.entries.count + 1) weeks of increasing RPE"
            } else {
                appliedChange = "Deload applied"
            }
        } else if resetExercises.contains(new.id) {
            progressionType = .reset
            appliedChange = "Progression reset"
        } else if new.weeksStagnated >= input.user.settings.stagnationPeriod {
            progressionType = .stagnation
            appliedChange = "Weeks stagnated: \(new.weeksStagnated) (at stagnation limit)"
        } else if new.weeksStagnated > 0 {
            progressionType = .stagnation
            appliedChange = "Weeks stagnated: \(new.weeksStagnated)"
        } else {
            progressionType = .none
            appliedChange = "No progression changes"
        }
        
        return ProgressionDetails(
            progressionType: progressionType,
            previousWeek: max(0, new.overloadProgress - 1),
            newWeek: new.overloadProgress,
            stagnationWeeks: new.weeksStagnated,
            appliedChange: appliedChange
        )
    }
}
