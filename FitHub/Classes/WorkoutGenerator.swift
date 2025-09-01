//
//  WorkoutGenerator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/16/25.
//

import Foundation

// ──────────────────────────────────────────────────────────────
//  WorkoutGenerator.swift  (instrumented + selection engine)
// ──────────────────────────────────────────────────────────────
final class WorkoutGenerator {
    // Track progression states during generation
    private var deloadingExercises: Set<Exercise.ID> = []
    private var overloadingExercises: Set<Exercise.ID> = []
    private var resetExercises: Set<Exercise.ID> = []
    private var maxUpdates: Set<Exercise.ID> = []
    
    // •–––––––––  Inputs  –––––––––•
    struct Input {
        let user: UserData                       // read-only snapshot
        let exerciseData: ExerciseData
        let equipmentData: EquipmentData
        let savedExercises: [[Exercise]] 
        let keepCurrentExercises: Bool
        let nextWeek: Bool
    }

    // •–––––––––  Outputs  ––––––––•
    struct Output {
        var trainerTemplates: [WorkoutTemplate]
        var workoutsStartDate: Date
        var workoutsCreationDate: Date
        var logFileName: String?
        var updatedMax: [PerformanceUpdate]?
        var changelog: WorkoutChangelog? // NEW
    }
    
    struct GenerationParameters {
        var exercisesPerWorkout: Int
        var repsAndSets: RepsAndSets
        var days: [DaysOfWeek]
        var dates: [Date]
        var workoutWeek: WorkoutWeek
        var startDate: Date
        var categoriesPerDay: [[SplitCategory]]
        var overloadFactor: Double
    }

    // MARK: – Public façade
    func generate(from input: Input) -> Output {
        let creationDate: Date = Date()
        
        Logger.shared.add("Current Date: \(Format.fullDate(from: creationDate))", timestamp: false, lineBreak: .before)
        Logger.shared.add("Starting workout generation...", timestamp: true, lineBreak: .both)

        // TOTAL (compute only; we time flush separately)
        let totalTok = Logger.shared.start("TOTAL generation time", lineBreak: .before)

        // 0) Build selector (index + policy + deterministic seed)
        let selTok = Logger.shared.start("0) build selector (index + policy)", indentTabs: 1)
        let selector = ExerciseSelector(
            data: input.exerciseData,
            equipment: input.equipmentData,
            selectedEquipment: input.user.evaluation.equipmentSelected,
            favorites: Set(input.user.evaluation.favoriteExercises),
            disliked: Set(input.user.evaluation.dislikedExercises),
            resistance: input.user.workoutPrefs.ResistanceType,
            strengthCeiling: input.user.evaluation.strengthLevel.strengthValue,
            policy: .init(minCount: 1, maxCount: 20),
            logger: Logger.shared,
            seed: UInt64(max(1, Int(creationDate.timeIntervalSince1970))) // deterministic per run
        )
        Logger.shared.end(selTok)

        //  Derive all knobs the old method used
        let params = Logger.shared.time("2) deriveParameters", indentTabs: 1) {
            deriveParameters(input: input)
        }
        
        // Early-exit guard
        guard !params.days.isEmpty else {
            Logger.shared.add("ERROR: No workout days were determined.", lineBreak: .before)
            Logger.shared.end(totalTok, suffix: "early exit")
            return Output(trainerTemplates: [],
                          workoutsStartDate: params.startDate,
                          workoutsCreationDate: creationDate,
                          logFileName: nil)
        }

        // 3️⃣  Build templates day-by-day (selection via selector)
        var updates = PerformanceUpdates()

        var templates: [WorkoutTemplate] = []
        for (idx, day) in params.days.enumerated() {
            let dayTok = Logger.shared.start("3) build \(day.rawValue) template", indentTabs: 1)
            if let tpl = makeWorkoutTemplate(
                day: day,
                dayIndex: idx,
                params: params,
                input: input,
                selector: selector,                // ⬅️ NEW
                maxUpdated: { update in
                    updates.updatePerformance(update)
                }
            ) {
                templates.append(tpl)
            }
            Logger.shared.end(dayTok)
        }
        
        Logger.shared.add("Workout Generation Complete!", timestamp: true, lineBreak: .both, numLines: 2)
        Logger.shared.end(totalTok)  // end TOTAL

        // Flush separately so TOTAL reflects compute only
        let flushTok = Logger.shared.start("flush logs to disk")
        let fileName = try? Logger.shared.flush()
        Logger.shared.end(flushTok)
        
        // �� GENERATE CHANGELOG HERE
           let changelog = generateChangelog(
               input: input,
               params: params,
               templates: templates,
               generationStartTime: creationDate,
               performanceUpdates: updates
           )

        return Output(trainerTemplates: templates,
                      workoutsStartDate: params.startDate,
                      workoutsCreationDate: creationDate,
                      logFileName: fileName,
                      updatedMax: updates.updatedMax,
                      changelog: changelog  // 🆕 ADD THIS
        )
    }
}

// MARK: – Step-specific helpers
extension WorkoutGenerator {
    // Non-mutating derivations collected in one place
    func deriveParameters(input: Input) -> GenerationParameters {
        let goal = input.user.physical.goal
        let age = input.user.profile.age
        let freq = input.user.workoutPrefs.workoutDaysPerWeek
        let lvl = input.user.evaluation.strengthLevel
        let daysPerWeek = max(2, input.user.workoutPrefs.workoutDaysPerWeek) // clamp min days per week

        let workoutWeek = WorkoutWeek.determineSplit(
            customSplit: input.user.workoutPrefs.customWorkoutSplit,
            daysPerWeek: daysPerWeek
        )
        let repsAndSets = RepsAndSets.determineRepsAndSets(
            for: goal,
            customRestPeriod: input.user.workoutPrefs.customRestPeriods,
            customRepsRange: input.user.workoutPrefs.customRepsRange,
            customSets: input.user.workoutPrefs.customSets,
            customDistribution: input.user.workoutPrefs.customDistribution,
        )
        let duration = WorkoutParams.determineWorkoutDuration(
            age: age,
            frequency: freq,
            strengthLevel: lvl,
            goal: goal,
            customDuration: input.user.workoutPrefs.customDuration
        )
        let overloadFactor = WorkoutParams.determineOverloadFactor(
            age: age,
            frequency: freq,
            strengthLevel: lvl,
            goal: goal,
            customFactor: input.user.settings.customOverloadFactor
        )
        let exPerWorkout = estimateExercises(
            durationMinutes: duration,
            repsAndSets: repsAndSets
        )
        let dayIndices = DaysOfWeek.calculateWorkoutDayIndexes(
            customWorkoutDays: input.user.workoutPrefs.customWorkoutDays,
            workoutDaysPerWeek: daysPerWeek
        )
  
        let categoriesPerDay = (0..<dayIndices.count).map { workoutWeek.categoryForDay(index: $0) }
        
        // ---------------- Week roll-over logic ----------------
        var start    = Date()
        var weekDays = start.datesOfWeek(using: Calendar.current)

        if let lastDate = dayIndices.compactMap({ weekDays[$0] }).last {
            if CalendarUtility.shared.isDateInToday(lastDate) {
                Logger.shared.add("Last relevant workout day is today → stay in current week.")
            } else if lastDate < Date() {
                Logger.shared.add("Last relevant workout day is past → bump to next week.")
                start = CalendarUtility.shared.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
                weekDays = start.datesOfWeek(using: Calendar.current)
            }
        }
        
        let days = dayIndices.map { DaysOfWeek.orderedDays[$0] }
        let dates = dayIndices.map { weekDays[$0] }
        let schedule = zip(days, dates).map { name, date in
            "\t\(name.rawValue): \(Format.shortDate(from: date))"
        }.joined(separator: "\n")
        
        Logger.shared.add("New Week: \(input.nextWeek ? "yes" : "no")", lineBreak: .before)
        Logger.shared.add("Exercises: \(input.keepCurrentExercises ? "keep current" : "select new") exercises")
        Logger.shared.add("Days per week: \(daysPerWeek)")
        Logger.shared.add("Workout week:\n \(workoutWeek)")
        Logger.shared.add("Workout schedule:\n\(schedule)")

        return GenerationParameters(
            exercisesPerWorkout: exPerWorkout,
            repsAndSets: repsAndSets,
            days: days,
            dates: dates,
            workoutWeek: workoutWeek,
            startDate: start,
            categoriesPerDay: categoriesPerDay,
            overloadFactor: overloadFactor
        )
    }
    
    private func estimateExercises(durationMinutes: Int, repsAndSets: RepsAndSets) -> Int {
        let secondsPerRep = SetDetail.secPerRep
        let avgSetup      = SetDetail.secPerSetup

        // Weighted by distribution **and** per-type set counts
        let setsAvg   = max(1.0, repsAndSets.averageSetsPerExercise)
        let repsAvg   = max(1.0, repsAndSets.averageRepsPerSetWeighted)
        let restPer   = max(0, repsAndSets.getRest(for: .working))

        let workSeconds = setsAvg * repsAvg * Double(secondsPerRep)
        let restSeconds = Double(restPer) * max(0.0, setsAvg - 1.0)
        let perExercise = max(1, Int(workSeconds) + Int(restSeconds) + avgSetup)

        let totalSeconds = max(60, durationMinutes * 60)
        let numExercises = max(1, Int((Double(totalSeconds) / Double(perExercise)).rounded()))
        return numExercises
    }
    
    // Selection via engine
    func makeWorkoutTemplate(
        day: DaysOfWeek,
        dayIndex: Int,
        params: GenerationParameters,
        input: Input,
        selector: ExerciseSelector,
        maxUpdated: @escaping (PerformanceUpdate) -> Void
    ) -> WorkoutTemplate? {
        
        let dayName = day.rawValue
        let categoriesForDay = params.categoriesPerDay[dayIndex]
        var workoutDate: Date = params.dates[dayIndex]
        let savedExercises = input.savedExercises 
        
        if !input.user.settings.useDateOnly {
            // Prefer per-day custom time → then user default → then 11:00
            let comps: DateComponents =
            (input.user.workoutPrefs.customWorkoutTimes?.time(for: day))
                ?? input.user.settings.defaultWorkoutTime
                ?? DateComponents(hour: 11, minute: 0)

            if let h = comps.hour, let m = comps.minute {
                workoutDate = CalendarUtility.shared.date(bySettingHour: h, minute: m, second: 0, of: workoutDate) ?? workoutDate
            }
        }

        // Selection
        let selectTok = Logger.shared.start("[\(dayName)] select exercises", indentTabs: 2)
        let exercises: [Exercise] = {
            if input.keepCurrentExercises, dayIndex < savedExercises.count {
                Logger.shared.add("\(dayName) Workout: Reusing saved exercises.", lineBreak: .before, numLines: 3)
                let result = savedExercises[dayIndex]
                return result
            }

            let usedNames: Set<String> = dayIndex < savedExercises.count ? Set(savedExercises[dayIndex].map(\.name)) : []

            Logger.shared.add("\(dayName) Workout: Selecting new exercises.", lineBreak: .before, numLines: 3)

            // Selector enforces exact `exercisesPerWorkout` when the pool allows.
            let result = selector.select(
                dayIndex: dayIndex,
                categories: categoriesForDay,
                usedNames: usedNames,
                total: params.exercisesPerWorkout,
                rAndS: params.repsAndSets,
                dayLabel: dayName
            )
            return result
        }()
        
        Logger.shared.end(selectTok, suffix: "\(exercises.count) selected")

        if exercises.isEmpty {
            Logger.shared.add("No exercises selected. Check the selection criteria and available exercises.")
            return nil
        }
        
        // [1] Detail each exercise (aggregate timing, plus per-ex timing with threshold)
        let detailTok = Logger.shared.start("[\(dayName)] detail exercises", indentTabs: 2)
        let detailedExercises: [Exercise] = exercises.map { ex in
            Logger.shared.time("[\(dayName)] \(ex.name) details", indentTabs: 3, minMs: 1.0) {
                calculateDetailedExercise(
                    input: input,
                    exercise: ex,
                    repsAndSets: params.repsAndSets,
                    overloadFactor: params.overloadFactor,
                    maxUpdated: { update in
                        maxUpdated(update)
                    }
                )
            }
        }
        Logger.shared.end(detailTok, suffix: "x\(exercises.count)")

        // [2] Similarity debug (only when *not* keeping current)
        if !input.keepCurrentExercises, dayIndex < savedExercises.count {
            let simTok = Logger.shared.start("[\(dayName)] similarity", indentTabs: 2)
            let savedNames    = Set(savedExercises[dayIndex].map(\.name))
            let selectedNames = Set(exercises.map(\.name))
            let overlap       = Double(savedNames.intersection(selectedNames).count)
            let maxCount      = Double(max(savedNames.count, selectedNames.count))
            if maxCount > 0 {
                let sim = overlap / maxCount * 100
                Logger.shared.add("Similarity with previous week: \(String(format: "%.0f%%", sim))")
            }
            Logger.shared.end(simTok)
        }
        
        // [3] Build the template
        var tpl = WorkoutTemplate(
            name: "\(dayName) Workout",
            exercises: detailedExercises,
            categories: categoriesForDay,
            dayIndex: dayIndex,
            date: workoutDate
        )

        // [5] Completion-time estimate
        let etaTok = Logger.shared.start("[\(dayName)] estimate completion time", indentTabs: 2)
        tpl.setEstimatedCompletionTime(rest: params.repsAndSets.rest)
        Logger.shared.end(etaTok)
        
        return tpl
    }
    
    func calculateDetailedExercise(input: Input, exercise: Exercise, repsAndSets: RepsAndSets, overloadFactor: Double, maxUpdated: @escaping (PerformanceUpdate) -> Void) -> Exercise {
        var ex  = exercise
        
        if let max = input.exerciseData.peakMetric(for: ex.id), max.actualValue > 0 {
            ex.draftMax = max
            Logger.shared.add("• Exercise: \(ex.name), \(max.loggingEntry), No Recalculation Needed", lineBreak: .before)
        } else if let estMax = input.exerciseData.estimatedPeakMetric(for: ex.id), estMax.actualValue > 0 {
            ex.draftMax = estMax
            Logger.shared.add("• Exercise: \(ex.name), Estimated \(estMax.loggingEntry), No Recalculation Needed", lineBreak: .before)
        } else if let calcMax = ex.calculateCSVMax(userData: input.user) {
            ex.draftMax = calcMax
            maxUpdated(PerformanceUpdate(exerciseId: ex.id, value: calcMax))
            Logger.shared.add("• Exercise: \(ex.name), Estimated \(calcMax.loggingEntry), Calculation Completed", lineBreak: .before)
        }

        // —— Set details ————————————————————————————
        Logger.shared.time("createSetDetails \(ex.name)", indentTabs: 4, minMs: 0.5) {
            ex.createSetDetails(repsAndSets: repsAndSets, userData: input.user, equipmentData: input.equipmentData)
        }

        // —— Overload/deload progression ——————————————
        return Logger.shared.time("handleExerciseProgression \(ex.name)", indentTabs: 4, minMs: 0.5) {
            handleExerciseProgression(input: input, exercise: ex, overloadFactor: overloadFactor)
        }
    }
    
    func handleExerciseProgression(input: Input, exercise: Exercise, overloadFactor: Double) -> Exercise {
        var ex = exercise
        var prog = ex.overloadProgress

        func resetProgression() {
            ex.currentWeekAvgRPE   = nil
            ex.previousWeeksAvgRPE = nil
            ex.weeksStagnated      = 0
            ex.overloadProgress    = 0
            resetExercises.insert(ex.id)
        }

        if input.nextWeek && input.keepCurrentExercises {
            // 0️⃣ NEW PR check (day-normalized)
            let newPRLogged = newPRSincePlanCreation(input: input, exerciseID: ex.id)

            if newPRLogged {
                Logger.shared.add("◦ New 1RM since plan creation → reset stagnation.", indentTabs: 1)
                maxUpdates.insert(ex.id)
                resetProgression()
            }
            // 1️⃣ PROGRESSIVE OVERLOAD
            else if ex.weeksStagnated >= input.user.settings.stagnationPeriod,
                    input.user.settings.progressiveOverload {
                prog += 1
                ex.overloadProgress = prog
                Logger.shared.add(
                    "◦ Weeks stagnated \(ex.weeksStagnated) ≥ \(input.user.settings.stagnationPeriod) — applying overload.",
                    indentTabs: 1
                )
                ex.applyProgressiveOverload(
                    equipmentData: input.equipmentData,
                    period:   input.user.settings.progressiveOverloadPeriod,
                    style:    input.user.settings.progressiveOverloadStyle,
                    rounding: input.user.settings.roundingPreference,
                    overloadFactor: overloadFactor
                )
                overloadingExercises.insert(ex.id)
            }
            // 2️⃣ DELOAD or +1 week stagnant (no new PR in window)
            else {
                if let currentRPE = ex.currentWeekAvgRPE,
                   let prevRPEs   = ex.previousWeeksAvgRPE,
                   let avgPrevRPEs = prevRPEs.average,
                   currentRPE > avgPrevRPEs,
                   prevRPEs.count + 1 >= input.user.settings.periodUntilDeload, // using +1 also accounts for the current week
                   input.user.settings.allowDeloading {
                    
                    Logger.shared.add(
                        "◦ RPE \(currentRPE) > \(prevRPEs.average ?? currentRPE) over \(prevRPEs.count)w — deload.",
                        indentTabs: 1
                    )
                    ex.applyDeload(
                        equipmentData: input.equipmentData,
                        deloadPct: input.user.settings.deloadIntensity,
                        rounding: input.user.settings.roundingPreference
                    )
                    resetProgression()
                    deloadingExercises.insert(ex.id)
                    
                } else {
                    Logger.shared.add("◦ Weeks stagnated: \(ex.weeksStagnated) → \(ex.weeksStagnated + 1)", indentTabs: 1)
                    ex.weeksStagnated += 1
                }
            }
        }

        // 3️⃣ Reset after completing a full overload cycle
        if prog == input.user.settings.progressiveOverloadPeriod {
            Logger.shared.add("◦ Resetting progressive-overload cycle.", indentTabs: 1)
            resetProgression()
        }

        return ex
    }
    
    // MARK: - PR window helper (use same logic everywhere)
    private func newPRSincePlanCreation(input: Input, exerciseID: UUID) -> Bool {
        guard let creation = input.user.workoutPlans.workoutsCreationDate else { return false }

        let cal = CalendarUtility.shared
        let windowStart = cal.startOfDay(for: creation)

        guard let max = input.exerciseData.getMax(for: exerciseID), max.value.actualValue > 0
        else { return false }

        let maxDay = cal.startOfDay(for: max.date)
        return maxDay >= windowStart       // match your counter's logic
        // If you want "strictly after", use `>` instead.
    }
}
 
extension WorkoutGenerator {
    private func generateChangelog(
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
            // Use Calendar directly
            let calendar = Calendar.current
            let startOfLastUpdate = calendar.startOfDay(for: lastUpdate)
            let startOfToday = calendar.startOfDay(for: Date())
            
            let components = calendar.dateComponents([.weekOfYear], from: startOfLastUpdate, to: startOfToday)
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
                appliedChange = "Deload applied after \(prevRPEs.count + 1) weeks of increasing RPE"
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
