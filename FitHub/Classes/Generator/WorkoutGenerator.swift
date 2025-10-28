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
    var changes: WorkoutChanges = .init()
    
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
        var updatedMax: [PerformanceUpdate]?
        var changelog: WorkoutChangelog? // NEW
        var changes: WorkoutChanges?
    }
    
    struct GenerationParameters {
        var duration: TimeSpan
       // var exercisesPerWorkout: Int
        var repsAndSets: RepsAndSets
        var days: [DaysOfWeek]
        var dates: [Date]
        var workoutWeek: WorkoutWeek
        var startDate: Date
        var categoriesPerDay: [[SplitCategory]]
        var overloadFactor: Double
        var overloadStyle: ProgressiveOverloadStyle
        var nonDefaultParameters: Set<PoolChanges.RelaxedFilter>
    }

    // MARK: – Public façade
    func generate(from input: Input) -> Output {
        let creationDate: Date = Date()
  
        //  Derive all knobs the old method used
        let params = deriveParameters(input: input)
        
        let selector = ExerciseSelector(
            exerciseData: input.exerciseData,
            equipmentData: input.equipmentData,
            userData: input.user,
            days: params.days,
            nonDefaultParams: params.nonDefaultParameters,
            policy: .init(minCount: 1, maxCount: 20),
            seed: UInt64(max(1, Int(creationDate.timeIntervalSince1970))) // deterministic per run
        )
        
        // Early-exit guard
        guard !params.days.isEmpty else {
            return Output(trainerTemplates: [],
                          workoutsStartDate: params.startDate,
                          workoutsCreationDate: creationDate)
        }

        // 3️⃣  Build templates day-by-day (selection via selector)
        var csvUpdates = PerformanceUpdates() // these are estimates only

        var templates: [WorkoutTemplate] = []
        for (idx, day) in params.days.enumerated() {
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
        }
        
        // �� GENERATE CHANGELOG HERE
        let changelog = generateChangelog(
            input: input,
            params: params,
            templates: templates,
            generationStartTime: creationDate
        )
        
        resetSets() // Clear tracking sets AFTER changelog generation

        return Output(
            trainerTemplates: templates,
            workoutsStartDate: params.startDate,
            workoutsCreationDate: creationDate,
            updatedMax: csvUpdates.updatedMax,
            changelog: changelog,
            changes: changes
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
        let customSplit = input.user.workoutPrefs.customWorkoutSplit
        let customDist = input.user.workoutPrefs.customDistribution
        let resistance = input.user.workoutPrefs.resistance

        let workoutWeek = WorkoutWeek.determineSplit(
            customSplit: customSplit,
            daysPerWeek: daysPerWeek
        )
        let repsAndSets = RepsAndSets.determineRepsAndSets(
            for: goal,
            customRestPeriod: input.user.workoutPrefs.customRestPeriods,
            customRepsRange: input.user.workoutPrefs.customRepsRange,
            customSets: input.user.workoutPrefs.customSets,
            customDistribution: customDist,
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
        /*
        let exPerWorkout = estimateExercises(
            duration: duration,
            repsAndSets: repsAndSets
        )
        */
        let dayIndices = DaysOfWeek.calculateWorkoutDayIndexes(
            customWorkoutDays: input.user.workoutPrefs.customWorkoutDays,
            workoutDaysPerWeek: daysPerWeek
        )
        
        var customParms: Set<PoolChanges.RelaxedFilter> = []
        if let customDist, customDist != repsAndSets.distribution { customParms.insert(.effort) }
        if let customSplit, customSplit != workoutWeek { customParms.insert(.split) }
        if resistance != .any { customParms.insert(.resistance) }
  
        let categoriesPerDay = (0..<dayIndices.count).map { workoutWeek.categoryForDay(index: $0) }
        
        // ---------------- Week roll-over logic ----------------
        let today = Date()
        var start = CalendarUtility.shared.startOfWeek(for: today) ?? today
        var weekDays = CalendarUtility.shared.datesInWeek(startingFrom: start)

        // FIXME: if on a saturday, the start date will be saved as the next week's start date
        if let lastDate = dayIndices.compactMap({ weekDays[$0] }).last {
            if CalendarUtility.shared.isDateInToday(lastDate) {
                // Last relevant workout day is today → stay in current week.
            } else if lastDate < today {
                // Last relevant workout day is past → bump to next week.
                start = CalendarUtility.shared.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
                weekDays = CalendarUtility.shared.datesInWeek(startingFrom: start)
            }
        }
        
        let days = dayIndices.map { DaysOfWeek.orderedDays[$0] }
        let dates = dayIndices.map { weekDays[$0] }

        return GenerationParameters(
            duration: duration,
         //   exercisesPerWorkout: exPerWorkout,
            repsAndSets: repsAndSets,
            days: days,
            dates: dates,
            workoutWeek: workoutWeek,
            startDate: start,
            categoriesPerDay: categoriesPerDay,
            overloadFactor: overloadFactor,
            overloadStyle: overloadStyle,
            nonDefaultParameters: customParms
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
        let savedDay: OldTemplate = input.saved[safe: dayIndex] ?? OldTemplate()
        let dayHasExercises: Bool = dayIndex < input.saved.count && !savedDay.exercises.isEmpty
        let initialExercises: [Exercise] = (input.keepCurrentExercises && dayHasExercises) ? savedDay.exercises : []
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
        
        var tpl = WorkoutTemplate(
            name: "\(dayName) Workout",
            //exercises: [],
            exercises: initialExercises,
            categories: categoriesForDay,
            dayIndex: dayIndex,
            date: workoutDate,
            restPeriods: params.repsAndSets.rest
        )
        /*
        func getExercisesForTemplate(exerciseCount: Int, existingPicked: [Exercise]? = nil) -> ([Exercise], [PoolChanges.RelaxedFilter]?) {
            let (exercises, dayChanges): ([Exercise], PoolChanges?) = {
                // Reuse existing?
                let existing: [Exercise]? = {
                    if let existingPicked {
                        return existingPicked
                    } else {
                        return (input.keepCurrentExercises && dayHasExercises) ? savedDay.exercises : nil
                    }
                }()
                
                // already have enough, trim and skip selection
                if let existing, existing.count >= exerciseCount {
                    let trimmed = intelligentlyTrim(existing, to: exerciseCount, mustHit: categoriesForDay)
                    return (trimmed, nil)
                }
                
                // Selector enforces exact `exercisesPerWorkout` when the pool allows.
                let (picked, dayChanges) = selector.select(
                    dayIndex: dayIndex,
                    dayLabel: day.rawValue,
                    categories: categoriesForDay,
                    total: exerciseCount,
                    rAndS: params.repsAndSets,
                    existing: existing
                )
                return (picked, dayChanges)
            }()
          
            if let dayChanges { changes.record(templateID: tpl.id, newPool: dayChanges) }
            if exercises.isEmpty { return ([], dayChanges?.relaxedFilters) }
            
            // [2] Detail each exercise (aggregate timing, plus per-ex timing with threshold)
            let detailedExercises: [Exercise] = exercises.map { ex in
                let newEx = calculateDetailedExercise(
                    input: input,
                    exercise: ex,
                    repsAndSets: params.repsAndSets,
                    maxUpdated: { update in
                        maxUpdated(update)
                    }
                )
                // —— Overload/deload progression ——————————————
                return handleExerciseProgression(
                    input: input,
                    exercise: newEx,
                    completedExercise: completed.byID[ex.id],
                    overloadFactor: params.overloadFactor,
                    overloadStyle: params.overloadStyle,
                    templateCompleted: wasCompleted
                )
            }
            
            return (detailedExercises, dayChanges?.relaxedFilters)
        }
        
        let (exercises, _) = getExercisesForTemplate(exerciseCount: params.exercisesPerWorkout)
        tpl.exercises = exercises
        
        let (est, perExercise) = tpl.estimateCompletionTime(rest: params.repsAndSets.rest)
        let newCount = targetExerciseCount(perExercise: perExercise, target: params.duration)
            
        if !est.isWithin(params.duration) {
            let (exercises, relaxed) = getExercisesForTemplate(exerciseCount: newCount, existingPicked: tpl.exercises)
            tpl.exercises = exercises
            tpl.setEstimatedCompletionTime(rest: params.repsAndSets.rest)
            if let relaxed, relaxed.contains(.split) { tpl.setCategories() }
        } else {
            tpl.estimatedCompletionTime = est
        }
        */
        
        func getExercisesForTemplate(status: TimeSpan.Fit? = nil, existingPicked: [Exercise]? = nil) -> ([Exercise], [PoolChanges.RelaxedFilter]?) {
            let (exercises, dayChanges): ([Exercise], PoolChanges?) = {
                let existing = (existingPicked?.count ?? 0)
                let newCount: Int = {
                    if let status {
                        switch status {
                        case .over: return existing - 1
                        case .under: return existing + 1
                        case .within: return existing
                        }
                    } else {
                        return existing
                    }
                }()
                
                if let existingPicked, newCount < existing {
                    let trimmed = intelligentlyTrim(existingPicked, to: newCount, mustHit: categoriesForDay)
                    return (trimmed, nil)
                }
                
                // Selector enforces exact `exercisesPerWorkout` when the pool allows.
                let (picked, dayChanges) = selector.select(
                    dayIndex: dayIndex,
                    dayLabel: day.rawValue,
                    categories: categoriesForDay,
                    total: newCount,
                    rAndS: params.repsAndSets,
                    existing: existingPicked
                )
                return (picked, dayChanges)
            }()
          
            if let dayChanges { changes.record(templateID: tpl.id, newPool: dayChanges) }
            if exercises.isEmpty { return ([], dayChanges?.relaxedFilters) }
            
            // [2] Detail each exercise (aggregate timing, plus per-ex timing with threshold)
            let detailedExercises: [Exercise] = exercises.map { ex in
                let newEx = calculateDetailedExercise(
                    input: input,
                    exercise: ex,
                    repsAndSets: params.repsAndSets,
                    maxUpdated: { update in
                        maxUpdated(update)
                    }
                )
                // —— Overload/deload progression ——————————————
                return handleExerciseProgression(
                    input: input,
                    exercise: newEx,
                    completedExercise: completed.byID[ex.id],
                    overloadFactor: params.overloadFactor,
                    overloadStyle: params.overloadStyle,
                    templateCompleted: wasCompleted
                )
            }
            
            return (detailedExercises, dayChanges?.relaxedFilters)
        }
        
        let initialEst = tpl.estimatedCompletionTime ?? TimeSpan(seconds: 0)
        var est: TimeSpan = initialEst
        var attempt: Int = 1
        while !est.isWithin(params.duration) {
            let fit = est.fit(against: params.duration)
            
            let existing = tpl.exercises
            print("\(dayName) selection attempt \(attempt)")
            let (exercises, relaxed) = getExercisesForTemplate(status: fit, existingPicked: existing)
            tpl.exercises = exercises
            
            print("\(exercises.count - existing.count) exercises picked - before: \(existing.count), after: \(exercises.count)")
            if let relaxed, relaxed.contains(.split) { tpl.setCategories() }
            
            let (newEst, _) = tpl.estimateCompletionTime(rest: params.repsAndSets.rest)
            tpl.estimatedCompletionTime = newEst
            est = newEst
            
            attempt += 1
        }
        
        return tpl
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
        ex.createSetDetails(repsAndSets: repsAndSets, userData: input.user, equipmentData: input.equipmentData)
        
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
                overloadingExercises.insert(ex.id)
                return true
            } else {
                ex.overloadProgress = oldProgress // rollback only the visual bump
                return false
            }
        }

        /// If no PR/OL change happened, advance stagnation and maybe deload.
        func stagnateOrDeload() {
            ex.weeksStagnated += 1

            if s.allowDeloading && ex.weeksStagnated >= s.periodUntilDeload {
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
            resetProgression()
            maxUpdates.insert(ex.id)
            return ex
        }

        // 1️⃣ Skip if last week’s template wasn’t completed.
        guard templateCompleted else { return ex }
        
        // 2️⃣ Prevent overload immediately after deload.
        if completedExercise?.isDeloading == true {
            ex.isDeloading = false
            endedDeloadExercises.insert(ex.id)
            return ex
        }

        // 3️⃣ Try overload → else stagnate/deload.
        let appliedOL = tryOverload()
        if !appliedOL { stagnateOrDeload() }

        // 4️⃣ Reset after completing a full overload cycle.
        if s.progressiveOverload && ex.overloadProgress >= s.progressiveOverloadPeriod {
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

extension WorkoutGenerator {
    /*
    private func targetExerciseCount(
        perExercise: [(id: Exercise.ID, seconds: Int)],
        target: TimeSpan,
        // minimal asymmetry knobs
        underTolerancePct: Double = 0.05,  // tighter under
        overTolerancePct:  Double = 0.12,  // looser over
        underMinSlackSec:  Int    = 45,
        overMinSlackSec:   Int    = 120
    ) -> Int {
        let targetSec = max(0, target.inSeconds)
        let count     = max(1, perExercise.count)
        let totalSec  = perExercise.reduce(0) { $0 + max(0, $1.seconds) }
        let avgSec    = max(1, totalSec / count)

        // Asymmetric tolerance
        let allowedUnder = max(Int(Double(targetSec) * underTolerancePct), underMinSlackSec)
        let allowedOver  = max(Int(Double(targetSec) * overTolerancePct),  overMinSlackSec)

        // Already “close enough”?
        if totalSec <= targetSec {
            if (targetSec - totalSec) <= allowedUnder { return count }
        } else {
            if (totalSec - targetSec) <= allowedOver { return count }
        }

        // Ideal by average; clamp to [1, count]
        let ideal = max(1, min(count, Int(round(Double(targetSec) / Double(avgSec)))))

        // Evaluate close-by options to avoid big swings
        let candidates = Set([ideal - 1, ideal, ideal + 1].filter { (1...count).contains($0) })
        let pick = candidates.min { a, b in
            let errA = abs(a * avgSec - targetSec)
            let errB = abs(b * avgSec - targetSec)
            if errA != errB { return errA < errB }
            // tie-breaker: prefer slightly *more* work if both are equally close
            return a > b
        } ?? ideal

        return pick
    }
    
    private func estimateExercises(duration: TimeSpan, repsAndSets: RepsAndSets) -> Int {
        // Weighted by distribution **and** per-type set counts
        let setsAvg = max(1.0, repsAndSets.averageSetsPerExercise)
        let repsAvg = max(1.0, repsAndSets.averageRepsPerSetWeighted)
        let restPer = max(0, repsAndSets.getRest(for: .working))
        
        let secondsPerRep = SetDetail.secPerRep(for: Int(repsAvg), isWarm: false)
        let avgSetup      = SetDetail.secPerSetup

        let workSeconds = setsAvg * repsAvg * Double(secondsPerRep)
        let restSeconds = Double(restPer) * max(0.0, setsAvg - 1.0)
        let perExercise = max(1, Int(workSeconds) + Int(restSeconds) + avgSetup)

        let totalSeconds = max(60, duration.inMinutes * 60)
        let numExercises = max(1, Int((Double(totalSeconds) / Double(perExercise)).rounded()))
        return numExercises
    }
    */
    /// Trim `existing` to `target` while trying to keep coverage of `mustHit` categories.
    /// - Keeps original order.
    /// - Guarantees at most one seed per category (if available), then fills with preferred matches, then anything.
    private func intelligentlyTrim(
        _ existing: [Exercise],
        to target: Int,
        mustHit: [SplitCategory]
    ) -> [Exercise] {
        guard existing.count > target, target > 0 else {
            return Array(existing.prefix(max(0, target)))
        }

        @inline(__always)
        func matches(_ ex: Exercise, _ cat: SplitCategory) -> Bool {
            ex.splitCategory == cat || ex.groupCategory == cat
        }

        var pickedIdx: [Int] = []
        pickedIdx.reserveCapacity(target)
        var used = Set<Int>()

        // 1) Seed: first occurrence for each must-hit category (in order)
        for cat in mustHit where pickedIdx.count < target {
            if let idx = existing.firstIndex(where: { matches($0, cat) }) {
                if used.insert(idx).inserted { pickedIdx.append(idx) }
            }
        }

        // 2) Prefer remaining items that match ANY must-hit category
        let mustHitSet = Set(mustHit)
        for (i, ex) in existing.enumerated() where pickedIdx.count < target {
            if used.contains(i) { continue }
            let preferred = (ex.splitCategory.map { mustHitSet.contains($0) } ?? false)
                         || (ex.groupCategory.map { mustHitSet.contains($0) } ?? false)
            if preferred, used.insert(i).inserted { pickedIdx.append(i) }
        }

        // 3) Fill with whatever’s left in order
        for i in 0..<existing.count where pickedIdx.count < target {
            if used.insert(i).inserted { pickedIdx.append(i) }
        }

        // Return in original order
        pickedIdx.sort()
        return pickedIdx.map { existing[$0] }
    }
}
