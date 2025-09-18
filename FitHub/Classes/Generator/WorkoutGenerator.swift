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
    var overloadingExercises: Set<Exercise.ID> = []
    var resetExercises: Set<Exercise.ID> = []
    var maxUpdates: Set<Exercise.ID> = []
    
    // •–––––––––  Inputs  –––––––––•
    struct Input {
        let user: UserData                       // read-only snapshot
        let exerciseData: ExerciseData
        let equipmentData: EquipmentData
        //let savedExercises: [[Exercise]]
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
                selector: selector,                
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

        return Output(
            trainerTemplates: templates,
            workoutsStartDate: params.startDate,
            workoutsCreationDate: creationDate,
            logFileName: fileName,
            updatedMax: updates.updatedMax,
            changelog: changelog
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
            overloadFactor: overloadFactor
        )
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
        
        //let savedExercises = input.savedExercises
        let savedExercises = input.saved
        
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
        var wasCompleted: Bool = false
        let selectTok = Logger.shared.start("[\(dayName)] select exercises", indentTabs: 2)
        let exercises: [Exercise] = {
            // TODO: this must also add exercises if desired duration changed
            if input.keepCurrentExercises, dayIndex < savedExercises.count {
                Logger.shared.add("\(dayName) Workout: Reusing saved exercises.", lineBreak: .before, numLines: 3)
                let daySaved = savedExercises[dayIndex]
                wasCompleted = input.user.workoutPlans.completedWorkouts.contains(where: { $0.template.id == daySaved.id })
                
                return daySaved.exercises
            }

            Logger.shared.add("\(dayName) Workout: Selecting new exercises.", lineBreak: .before, numLines: 3)
            print("[\(dayName)] \(categoriesForDay)")
            
            // Selector enforces exact `exercisesPerWorkout` when the pool allows.
            let result = selector.select(
                dayIndex: dayIndex,
                categories: categoriesForDay,
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
        
        // [1] Similarity debug (only when *not* keeping current)
        if !input.keepCurrentExercises, dayIndex < savedExercises.count {
            let simTok = Logger.shared.start("[\(dayName)] similarity", indentTabs: 2)
            compareSimilarity(savedExercises: savedExercises[dayIndex].exercises, chosenExercises: exercises, dayIndex: dayIndex)
            Logger.shared.end(simTok)
        }
                
        // [2] Detail each exercise (aggregate timing, plus per-ex timing with threshold)
        let detailTok = Logger.shared.start("[\(dayName)] detail exercises", indentTabs: 2)
        let detailedExercises: [Exercise] = exercises.map { ex in
            Logger.shared.time("[\(dayName)] \(ex.name) details", indentTabs: 3, minMs: 1.0) {
                calculateDetailedExercise(
                    input: input,
                    exercise: ex,
                    repsAndSets: params.repsAndSets,
                    overloadFactor: params.overloadFactor,
                    templateCompleted: wasCompleted,
                    maxUpdated: { update in
                        maxUpdated(update)
                    }
                )
            }
        }
        Logger.shared.end(detailTok, suffix: "x\(exercises.count)")
        
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
        overloadFactor: Double,
        templateCompleted: Bool = false,
        maxUpdated: @escaping (PerformanceUpdate) -> Void
    ) -> Exercise {
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
            handleExerciseProgression(input: input, exercise: ex, overloadFactor: overloadFactor, templateCompleted: templateCompleted)
        }
    }
    
    func handleExerciseProgression(input: Input, exercise: Exercise, overloadFactor: Double, templateCompleted: Bool) -> Exercise {
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
            
            if !templateCompleted {
                Logger.shared.add("Template was not completed last week. Skipping exercise progression.", indentTabs: 1)
                return ex
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
                if let current  = ex.currentWeekAvgRPE,
                   let previous = ex.previousWeeksAvgRPE,
                   let avgPrevRPEs = previous.avgRPE,
                   let prevPeaks = previous.avgPeakValue,
                   current.rpe > avgPrevRPEs, // rpe trend increasing (difficulty increasing)
                   current.completion.actualValue <= prevPeaks, // weight completed same or lower
                   previous.entries.count + 1 >= input.user.settings.periodUntilDeload, // using +1 also accounts for the current week
                   input.user.settings.allowDeloading
                {
                    Logger.shared.add(
                        "◦ RPE \(current.rpe) > \(avgPrevRPEs), Weight \(current.completion.actualValue) <= \(prevPeaks) — over \(previous.entries.count)w — deload.",
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
