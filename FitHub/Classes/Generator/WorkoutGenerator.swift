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
        let daysPerWeek = max(1, input.user.workoutPrefs.workoutDaysPerWeek) // clamp min days per week
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
        let restPeriods: RestPeriods = params.repsAndSets.rest
     
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
            exercises: initialExercises,
            categories: categoriesForDay,
            dayIndex: dayIndex,
            date: workoutDate,
            restPeriods: restPeriods
        )
        
        func getExercisesForTemplate(status: TimeSpan.Fit, existingPicked: [Exercise]) -> ([Exercise], [PoolChanges.RelaxedFilter]?) {
            let (exercises, dayChanges): ([Exercise], PoolChanges?) = {
                let existingCount = existingPicked.count
                let rawCount: Int = {
                    switch status {
                    case .over: return existingCount - 1
                    case .under: return existingCount + 1
                    case .within: return existingCount
                    }
                }()
                
                let targetCount = max(0, rawCount)
                if targetCount == existingCount { return (existingPicked, nil) }
                if targetCount < existingCount {
                    // TODO: add a warning if the effort distribution gets messed up
                    let trimmed = intelligentlyTrim(existingPicked, to: targetCount, mustHit: categoriesForDay)
                    return (trimmed, nil)
                }
                
                // Selector enforces exact `exercisesPerWorkout` when the pool allows.
                let (picked, dayChanges) = selector.select(
                    dayIndex: dayIndex,
                    dayLabel: dayName,
                    categories: categoriesForDay,
                    total: targetCount,
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
                
        let maxAttempts: Int = 20
        let step: () -> Bool = {
            let status = (tpl.estimatedCompletionTime ?? .init(seconds: 0)).fit(against: params.duration)

            let existing = tpl.exercises
            let (exercises, relaxed) = getExercisesForTemplate(status: status, existingPicked: existing)
            tpl.exercises = exercises

            if let relaxed, relaxed.contains(.split) { tpl.setCategories() }

            let (newEst, _) = tpl.estimateCompletionTime(rest: restPeriods)
            tpl.estimatedCompletionTime = newEst

            return newEst.fit(against: params.duration).isWithin
        }

        // Run at least once, up to maxAttempts
        for _ in 0..<maxAttempts {
            if step() { break }
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
        
        if let max = input.exerciseData.peakMetric(for: ex.id), max.actualValue > 0 {
            ex.draftMax = max
        } else if let estMax = input.exerciseData.estimatedPeakMetric(for: ex.id), estMax.actualValue > 0 {
            ex.draftMax = estMax
        } else if let calcMax = CSVLoader.calculateMaxValue(for: ex, userData: input.user) {
            ex.draftMax = calcMax
            maxUpdated(PerformanceUpdate(exerciseId: ex.id, value: calcMax))
        }

        // —— Set details ————————————————————————————
        ex.createSetDetails(repsAndSets: repsAndSets, userData: input.user, equipmentData: input.equipmentData)
        
        return ex
    }
    
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

