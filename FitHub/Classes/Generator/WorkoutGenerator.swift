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
    var deloadingExercises: Set<Exercise.ID> = []
    var endedDeloadExercises: Set<Exercise.ID> = []
    var overloadingExercises: Set<Exercise.ID> = []
    var resetExercises: Set<Exercise.ID> = []
    var maxUpdates: Set<Exercise.ID> = []
    var reductions: WorkoutReductions = .init()
    
    // •–––––––––  Inputs  –––––––––•
    struct Input {
        let user: UserData  // read-only snapshot
        let exerciseData: ExerciseData
        let equipmentData: EquipmentData
        let saved: [OldTemplate]
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
        var reductions: WorkoutReductions?
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
        var overloadStyle: ProgressiveOverloadStyle
    }

    // MARK: – Public façade
    func generate(from input: Input) -> Output {
        let creationDate: Date = Date()
        
        Logger.shared.add("Current Date: \(Format.fullDate(from: creationDate))", timestamp: false, lineBreak: .before)
        Logger.shared.add("Starting workout generation...", timestamp: true, lineBreak: .both)

        
        //  Derive all knobs the old method used
        let params = Logger.shared.time("2) deriveParameters", indentTabs: 1) {
            deriveParameters(input: input)
        }
        
        // TOTAL (compute only; we time flush separately)
        let totalTok = Logger.shared.start("TOTAL generation time", lineBreak: .before)

        // 0) Build selector (index + policy + deterministic seed)
        let selTok = Logger.shared.start("0) build selector (index + policy)", indentTabs: 1)
        let selector = ExerciseSelector(
            data: input.exerciseData,
            equipment: input.equipmentData,
            selectedEquipment: input.user.evaluation.equipmentSelected,
            days: params.days,
            favorites: Set(input.user.evaluation.favoriteExercises),
            disliked: Set(input.user.evaluation.dislikedExercises),
            resistance: input.user.workoutPrefs.resistance,
            strengthCeiling: input.user.evaluation.strengthLevel.strengthValue,
            policy: .init(minCount: 1, maxCount: 20),
            logger: Logger.shared,
            seed: UInt64(max(1, Int(creationDate.timeIntervalSince1970))) // deterministic per run
        )
        Logger.shared.end(selTok)
        
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
        var csvUpdates = PerformanceUpdates() // these are estimates only

        var templates: [WorkoutTemplate] = []
        for (idx, day) in params.days.enumerated() {
            let dayTok = Logger.shared.start("3) build \(day.rawValue) template", indentTabs: 1)
            if let tpl = makeWorkoutTemplate(
                day: day,
                dayIndex: idx,
                params: params,
                input: input,
                selector: selector,                
                maxUpdated: { update in
                    csvUpdates.updatePerformance(update)
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
            //performanceUpdates: updates
        )
        
        resetSets() // Clear tracking sets AFTER changelog generation

        return Output(
            trainerTemplates: templates,
            workoutsStartDate: params.startDate,
            workoutsCreationDate: creationDate,
            logFileName: fileName,
            updatedMax: csvUpdates.updatedMax,
            changelog: changelog,
            reductions: reductions
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
        let overloadStyle = ProgressiveOverloadStyle.determineStyle(
            overloadStyle: input.user.settings.progressiveOverloadStyle,
            overloadPeriod: input.user.settings.progressiveOverloadPeriod,
            rAndS: repsAndSets
        )
        let duration = WorkoutParams.determineWorkoutDuration(
            age: age,
            frequency: freq,
            strengthLevel: lvl,
            goal: goal,
            customDuration: input.user.workoutPrefs.customDuration
        )
        let overloadFactor = input.user.settings.customOverloadFactor ?? 1.0
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
        let today = Date()
        var start = CalendarUtility.shared.startOfWeek(for: today) ?? today
        var weekDays = CalendarUtility.shared.datesInWeek(startingFrom: start)

        // FIXME: if on a saturday, the start date will be saved as the next week's start date
        if let lastDate = dayIndices.compactMap({ weekDays[$0] }).last {
            if CalendarUtility.shared.isDateInToday(lastDate) {
                Logger.shared.add("Last relevant workout day is today → stay in current week.")
            } else if lastDate < today {
                Logger.shared.add("Last relevant workout day is past → bump to next week.")
                start = CalendarUtility.shared.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
                weekDays = CalendarUtility.shared.datesInWeek(startingFrom: start)
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
            overloadFactor: overloadFactor,
            overloadStyle: overloadStyle
        )
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
        
        guard let categoriesForDay = params.categoriesPerDay[safe: dayIndex],
              var workoutDate: Date = params.dates[safe: dayIndex]
        else { return nil }
        
        let dayName = day.rawValue
        let dayHasExercises: Bool = dayIndex < input.saved.count
        let savedDay: OldTemplate = input.saved[safe: dayIndex] ?? OldTemplate()
        let testCompleted: CompletedWorkout? = input.user.workoutPlans.completedWorkouts.first(where: { $0.template.id == savedDay.id })
        let wasCompleted: Bool = testCompleted != nil
        let completed: CompletedWorkout = testCompleted ?? CompletedWorkout()
     
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
        // returns both
        let (exercises, dayReductions): ([Exercise], PoolReduction?) = {
            // Reuse existing?
            let existing: [Exercise]? = (input.keepCurrentExercises && dayHasExercises) ? savedDay.exercises : nil
            if let existing, existing.count >= params.exercisesPerWorkout {
                Logger.shared.add("\(dayName) Workout: Reusing saved exercises.", lineBreak: .before, numLines: 3)
                // no new selection happened → reductions empty
                return (existing, nil)
            }

            Logger.shared.add("\(dayName) Workout: Selecting new exercises.", lineBreak: .before, numLines: 3)
            print("[\(dayName)] \(categoriesForDay)")

            // Selector enforces exact `exercisesPerWorkout` when the pool allows.
            let (picked, dayReductions) = selector.select(
                dayIndex: dayIndex,
                categories: categoriesForDay,
                total: params.exercisesPerWorkout,
                rAndS: params.repsAndSets,
                dayLabel: dayName,
                existing: existing
            )
            return (picked, dayReductions)
        }()

        Logger.shared.end(selectTok, suffix: "\(exercises.count) selected")

        let templateID: UUID = UUID()
        if let dayReductions {
            reductions.record(templateID: templateID, newPool: dayReductions)
        }
        
        if exercises.isEmpty {
            Logger.shared.add("No exercises selected. Check the selection criteria and available exercises.")
            return nil
        }
        
        // [1] Similarity debug (only when *not* keeping current)
        if !input.keepCurrentExercises, dayHasExercises {
            let simTok = Logger.shared.start("[\(dayName)] similarity", indentTabs: 2)
            compareSimilarity(savedExercises: savedDay.exercises, chosenExercises: exercises, dayIndex: dayIndex)
            Logger.shared.end(simTok)
        }
                
        // [2] Detail each exercise (aggregate timing, plus per-ex timing with threshold)
        let detailTok = Logger.shared.start("[\(dayName)] detail exercises", indentTabs: 2)
        let detailedExercises: [Exercise] = exercises.map { ex in
            Logger.shared.time("[\(dayName)] \(ex.name) details", indentTabs: 3, minMs: 1.0) {
                let newEx = calculateDetailedExercise(
                    input: input,
                    exercise: ex,
                    repsAndSets: params.repsAndSets,
                    maxUpdated: { update in
                        maxUpdated(update)
                    }
                )
                // —— Overload/deload progression ——————————————
                return Logger.shared.time("handleExerciseProgression \(ex.name)", indentTabs: 4, minMs: 0.5) {
                    handleExerciseProgression(
                        input: input,
                        exercise: newEx,
                        completedExercise: completed.byID[ex.id],
                        overloadFactor: params.overloadFactor,
                        overloadStyle: params.overloadStyle,
                        templateCompleted: wasCompleted
                    )
                }
            }
        }
        Logger.shared.end(detailTok, suffix: "x\(exercises.count)")
        
        // [3] Build the template
        let tpl = WorkoutTemplate(
            id: templateID,
            name: "\(dayName) Workout",
            exercises: detailedExercises,
            categories: categoriesForDay,
            dayIndex: dayIndex,
            date: workoutDate,
            restPeriods: params.repsAndSets.rest
        )

        // [5] Completion-time estimate
        let etaTok = Logger.shared.start("[\(dayName)] estimate completion time", indentTabs: 2)
        Logger.shared.end(etaTok)
        
        return tpl
    }
    
    private func estimateExercises(durationMinutes: Int, repsAndSets: RepsAndSets) -> Int {
        let secondsPerRep = SetDetail.secPerRep
        let avgSetup      = SetDetail.secPerSetup

        // Weighted by distribution **and** per-type set counts
        let setsAvg = max(1.0, repsAndSets.averageSetsPerExercise)
        let repsAvg = max(1.0, repsAndSets.averageRepsPerSetWeighted)
        let restPer = max(0, repsAndSets.getRest(for: .working))

        let workSeconds = setsAvg * repsAvg * Double(secondsPerRep)
        let restSeconds = Double(restPer) * max(0.0, setsAvg - 1.0)
        let perExercise = max(1, Int(workSeconds) + Int(restSeconds) + avgSetup)

        let totalSeconds = max(60, durationMinutes * 60)
        let numExercises = max(1, Int((Double(totalSeconds) / Double(perExercise)).rounded()))
        return numExercises
    }
    
    private func compareSimilarity(savedExercises: [Exercise], chosenExercises: [Exercise], dayIndex: Int) {
        let savedNames    = Set(savedExercises.map(\.name))
        let selectedNames = Set(chosenExercises.map(\.name))
        let overlap       = Double(savedNames.intersection(selectedNames).count)
        let maxCount      = Double(max(savedNames.count, selectedNames.count))
        if maxCount > 0 {
            let sim = overlap / maxCount * 100
            Logger.shared.add("Similarity with previous week: \(String(format: "%.0f%%", sim))")
        }
    }
    
    func calculateDetailedExercise(
        input: Input,
        exercise: Exercise,
        repsAndSets: RepsAndSets,
        maxUpdated: @escaping (PerformanceUpdate) -> Void
    ) -> Exercise {
        var ex  = exercise
        
        // Only try to fetch/compute if we don't already have a valid draftMax
        if ex.draftMax.valid == nil {
            if let max = input.exerciseData.peakMetric(for: ex.id), max.actualValue > 0 {
                ex.draftMax = max
            } else if let estMax = input.exerciseData.estimatedPeakMetric(for: ex.id), estMax.actualValue > 0 {
                ex.draftMax = estMax
            } else if let calcMax = ex.calculateCSVMax(userData: input.user) {
                ex.draftMax = calcMax
                maxUpdated(PerformanceUpdate(exerciseId: ex.id, value: calcMax))
            }
        }

        // —— Set details ————————————————————————————
        Logger.shared.time("createSetDetails \(ex.name)", indentTabs: 4, minMs: 0.5) {
            ex.createSetDetails(repsAndSets: repsAndSets, userData: input.user, equipmentData: input.equipmentData)
        }
        return ex
    }
    
    /*
    FIXME: should use exercise.isCompleted and ensure that planned metric is equal to completed metric
     will probably have to get exercises from completedWorkouts, not OldTemplate
    */
    func handleExerciseProgression(
        input: Input,
        exercise: Exercise,
        completedExercise: Exercise? = nil, // last week's
        overloadFactor: Double,
        overloadStyle: ProgressiveOverloadStyle,
        templateCompleted: Bool
    ) -> Exercise {
        var ex   = exercise
        let s    = input.user.settings

        func resetProgression() {
            ex.weeksStagnated      = 0
            ex.overloadProgress    = 0
            ex.isDeloading         = false
            resetExercises.insert(ex.id)
        }

        /// Try to apply OL if enabled. Returns true only if a real change was applied.
        @discardableResult
        func tryOverload() -> Bool {
            guard s.progressiveOverload else { return false }

            let oldProgress = ex.overloadProgress
            let next        = oldProgress + 1

            ex.overloadProgress = next // optimistic bump for apply()
            Logger.shared.add("◦ Attempting overload (step \(next)).", indentTabs: 1)

            let applied = ex.applyProgressiveOverload(
                equipmentData: input.equipmentData,
                period:   s.progressiveOverloadPeriod,
                style:    overloadStyle,
                rounding: s.roundingPreference,
                overloadFactor: overloadFactor,
                oldExercise: completedExercise
            )

            if applied {
                ex.weeksStagnated = 0
                Logger.shared.add("◦ Overload applied. Progress step = \(ex.overloadProgress).", indentTabs: 1)
                overloadingExercises.insert(ex.id)
                return true
            } else {
                ex.overloadProgress = oldProgress // rollback only the visual bump
                Logger.shared.add("◦ Overload not applied.", indentTabs: 1)
                return false
            }
        }

        /// If no PR/OL change happened, advance stagnation and maybe deload.
        func stagnateOrDeload() {
            ex.weeksStagnated += 1
            Logger.shared.add("◦ weeksStagnated = \(ex.weeksStagnated).", indentTabs: 1)

            if s.allowDeloading && ex.weeksStagnated >= s.periodUntilDeload {
                Logger.shared.add("◦ Stagnation threshold reached → Deload.", indentTabs: 1)
                ex.applyDeload(
                    equipmentData: input.equipmentData,
                    deloadPct: s.deloadIntensity,
                    rounding: s.roundingPreference
                )
                resetProgression()
                deloadingExercises.insert(ex.id)
                ex.isDeloading = true
            }
        }

        // ── Early exits ───────────────────────────────────────────────────────────────
        guard input.nextWeek && input.keepCurrentExercises else { return ex }

        // 0️⃣ New PR → reset.
        if newPRSincePlanCreation(input: input, exerciseID: ex.id) {
            Logger.shared.add("◦ New 1RM since plan creation → reset.", indentTabs: 1)
            resetProgression()
            maxUpdates.insert(ex.id)
            return ex
        }

        // 1️⃣ Skip if last week’s template wasn’t completed.
        guard templateCompleted else {
            Logger.shared.add("Template not completed last week → no progression changes.", indentTabs: 1)
            return ex
        }
        
        // 2️⃣ Prevent overload immediately after deload.
        if completedExercise?.isDeloading == true {
            Logger.shared.add("◦ Skipping overload — previous week was deload.", indentTabs: 1)
            ex.isDeloading = false
            endedDeloadExercises.insert(ex.id)
            return ex
        }

        // 3️⃣ Try overload → else stagnate/deload.
        let appliedOL = tryOverload()
        if !appliedOL { stagnateOrDeload() }

        // 4️⃣ Reset after completing a full overload cycle.
        if s.progressiveOverload && ex.overloadProgress >= s.progressiveOverloadPeriod {
            Logger.shared.add("◦ Completed overload cycle → reset progression.", indentTabs: 1)
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
        return maxDay >= windowStart
    }
    
    private func resetSets() {
        deloadingExercises.removeAll()
        endedDeloadExercises.removeAll()
        overloadingExercises.removeAll()
        resetExercises.removeAll()
        maxUpdates.removeAll()
    }
}
