//
//  WorkoutGenerator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/16/25.
//

import Foundation


// ──────────────────────────────────────────────────────────────
//  WorkoutGenerator.swift  (new file)
// ──────────────────────────────────────────────────────────────

struct WorkoutGenerator {
    // •–––––––––  Inputs  –––––––––•
    struct Input {
        let user: UserData                       // read-only snapshot
        let exerciseData: ExerciseData
        let equipmentData: EquipmentData
        let keepCurrentExercises: Bool
        let nextWeek: Bool
    }
    // •–––––––––  Outputs  ––––––––•
    struct Output {
        var trainerTemplates: [WorkoutTemplate]
        var workoutsStartDate: Date
        var workoutsCreationDate: Date
        var updatedMax: Bool
        var logFileName: String?
    }
    
    struct GenerationParameters {
        var exercisesPerWorkout: Int
        var repsAndSets: RepsAndSets
        var dayNames: [String]
        var dates: [Date]
        var workoutWeek: WorkoutWeek
        var startDate: Date
        var categoriesPerDay: [[SplitCategory]]
    }

    // MARK: – Public façade
    func generate(from input: Input) -> Output {
        let creationDate: Date = Date()
        var updatedMax: Bool = false
        
        Logger.shared.add("Current Date: \(Format.fullDate(from: creationDate))", timestamp: false, lineBreak: .before)
        Logger.shared.add("Starting workout generation...", timestamp: true, lineBreak: .both)

        // 1️⃣  Pre-flight housekeeping
        let savedExercises = manageOldTemplates(
            input: input,
            removeNotis: { ids in
                NotificationManager.remove(ids: ids)
            }
        )

        // 2️⃣  Derive all the knobs the old method used
        let params = deriveParameters(input: input)
        
        // Early-exit guard
        guard !params.dayNames.isEmpty else {
            //print("Issue: No workout days were determined.")
            Logger.shared.add("ERROR: No workout days were determined.", lineBreak: .before)
            return Output(trainerTemplates: [], workoutsStartDate: params.startDate, workoutsCreationDate: creationDate, updatedMax: false)
        }

        // 3️⃣  Build templates day-by-day
        var templates: [WorkoutTemplate] = []
        for (idx, name) in params.dayNames.enumerated() {
            if let tpl = makeWorkoutTemplate(dayName: name, dayIndex: idx, params: params, savedExercises: savedExercises, input: input, maxUpdated: { updatedMax = true }) {
                templates.append(tpl)
            }
        }
        
        Logger.shared.add("Workout Generation Complete!", timestamp: true, lineBreak: .both, numLines: 2)
        
        let fileName = try? Logger.shared.flush()

        return Output(trainerTemplates: templates, workoutsStartDate: params.startDate, workoutsCreationDate: creationDate, updatedMax: updatedMax, logFileName: fileName)
    }
}

// MARK: – Step-specific helpers
extension WorkoutGenerator {
    // House-keep old trainerTemplates – returns exercises we might want to keep
    private func manageOldTemplates(input: Input, removeNotis: ([String]) -> Void) -> [[Exercise]] {
        let saved = input.user.workoutPlans.trainerTemplates.map(\.exercises)
        for tpl in input.user.workoutPlans.trainerTemplates { removeNotis(tpl.notificationIDs) }
        input.user.workoutPlans.trainerTemplates.removeAll()
        return saved
    }

    // Non-mutating derivations collected in one place
    func deriveParameters(input: Input) -> GenerationParameters {
        var daysPerWeek = input.user.workoutPrefs.workoutDaysPerWeek
        if daysPerWeek < 2 { daysPerWeek = 2 } // set min days per week
        let exPerWorkout = WorkoutTemplate.determineExercisesPerWorkout(basedOn: input.user.profile.age, frequency: input.user.workoutPrefs.workoutDaysPerWeek, strengthLevel: input.user.evaluation.strengthLevel)
        let repsAndSets = RepsAndSets.determineRepsAndSets(customRestPeriod: input.user.workoutPrefs.customRestPeriod, goal: input.user.physical.goal, customRepsRange: input.user.workoutPrefs.customRepsRange, customSets: input.user.workoutPrefs.customSets)
        let dayIndices = daysOfWeek.calculateWorkoutDayIndexes(customWorkoutDays: input.user.workoutPrefs.customWorkoutDays, workoutDaysPerWeek: daysPerWeek)
        let dayNames = dayIndices.map { daysOfWeek.orderedDays[$0].rawValue }
        let workoutWeek = input.user.workoutPrefs.customWorkoutSplit ?? WorkoutWeek.createSplit(forDays: daysPerWeek)
        let categoriesPerDay = (0..<dayIndices.count).map { workoutWeek.categoryForDay(index: $0) }
        
        // ---------------- Week roll‑over logic ----------------
        var cal      = Calendar.current; cal.firstWeekday = 2
        var start    = Date()
        var weekDays = start.datesOfWeek(using: cal)

        if let lastDate = dayIndices.compactMap({ weekDays[$0] }).last {
            if cal.isDateInToday(lastDate) {
                // staying on the current week – explicit branch kept for clarity / logging parity
                //print("Last relevant workout day is today → stay in current week.")
                Logger.shared.add("Last relevant workout day is today → stay in current week.")
            } else if lastDate < Date() {
                //print("Last relevant workout day is past → bump to next week.")
                Logger.shared.add("Last relevant workout day is past → bump to next week.")
                start = cal.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
                weekDays = start.datesOfWeek(using: cal)
            }
        }
        
        let dates = dayIndices.map { weekDays[$0] }
        let schedule = zip(dayNames, dates).map { name, date in
            "\t\(name): \(Format.shortDate(from: date))"
        }.joined(separator: "\n")
        
        Logger.shared.add("Next week(for progression): \(input.nextWeek ? "yes" : "no")", lineBreak: .before)
        Logger.shared.add("Exercises: \(input.keepCurrentExercises ? "keep current" : "select new") exercises")
        Logger.shared.add("Days per week: \(daysPerWeek)")
        Logger.shared.add("Workout week:\n \(workoutWeek)")
       // Logger.shared.add("Day indices: \(dayIndices)")
        Logger.shared.add("Workout schedule:\n\(schedule)")

        //print("Days per week: \(daysPerWeek)")
        //print("Workout week: \(workoutWeek)")
        //print("Day indices: \(dayIndices)")
        //print("Day names: \(dayNames)")

        return GenerationParameters(exercisesPerWorkout: exPerWorkout, repsAndSets: repsAndSets, dayNames: dayNames, dates: dates, workoutWeek: workoutWeek, startDate: start, categoriesPerDay: categoriesPerDay)
    }
    
    func makeWorkoutTemplate(dayName: String, dayIndex: Int, params: GenerationParameters, savedExercises: [[Exercise]], input: Input, maxUpdated: @escaping () -> Void) -> WorkoutTemplate? {
        let categoriesForDay = params.categoriesPerDay[dayIndex]   // ← just read
        var workoutDate: Date = params.dates[dayIndex]
        if !input.user.settings.useDateOnly {
            if let custom = input.user.settings.defaultWorkoutTime {
                workoutDate = custom
            } else {
                workoutDate = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: workoutDate) ?? workoutDate
            }
        }

        let exercises: [Exercise] = {
            if input.keepCurrentExercises, dayIndex < savedExercises.count {
                Logger.shared.add("\(params.dayNames[dayIndex]) Workout: Reusing saved exercises.", lineBreak: .before, numLines: 3)
                // use saved Exercises
                return savedExercises[dayIndex]
            }
            // 2. Otherwise build a fresh list, but guard the index access
              let usedNames: Set<String> =
                  dayIndex < savedExercises.count
                  ? Set(savedExercises[dayIndex].map(\.name))
                  : []
            Logger.shared.add("\(params.dayNames[dayIndex]) Workout: Selecting new exercises.", lineBreak: .before, numLines: 3)
            // otherwise pick fresh ones
            return selectExercisesForDay(dayIndex: dayIndex, usedNames: usedNames, params: params, input: input)
        }()
        
        if exercises.isEmpty {
            //print("No exercises were selected for \(dayName). Check the selection criteria and available exercises.")
            Logger.shared.add("No exercises selected. Check the selection criteria and available exercises.")
            return nil
        }
        
        // [1] Turn every *raw* exercise into a fully-detailed one (incl. overload)
        let detailedExercises: [Exercise] = exercises.map { ex in
            calculateDetailedExercise(
                input: input, 
                exercise: ex,
                repsAndSets: params.repsAndSets,
                maxUpdated: { maxUpdated() }
            )
        }

        // [2]  Similarity debug (only when *not* keeping current)
        if !input.keepCurrentExercises, dayIndex < savedExercises.count {
            let savedNames    = Set(savedExercises[dayIndex].map(\.name))
            let selectedNames = Set(exercises.map(\.name))
            let overlap       = Double(savedNames.intersection(selectedNames).count)
            let maxCount      = Double(max(savedNames.count, selectedNames.count))
            if maxCount > 0 {
                let sim = overlap / maxCount * 100
                //print("Day \(dayName) template similarity: \(String(format: "%.0f%%", sim))")
                Logger.shared.add("Similarity with previous week: \(String(format: "%.0f%%", sim))")
            }
        }
        
        // [3] Build the template
        var tpl = WorkoutTemplate(name: "\(dayName) Workout", exercises: detailedExercises, categories: categoriesForDay, dayIndex: dayIndex, date: workoutDate)

        // [4] Notifications
        let ids = input.user.scheduleNotification(for: tpl)
        tpl.notificationIDs.append(contentsOf: ids)

        // [5] Completion-time estimate
        tpl.estimatedCompletionTime = WorkoutTemplate.estimateCompletionTime(for: tpl, completedWorkouts: input.user.workoutPlans.completedWorkouts)
        
        return tpl
    }
    
    func calculateDetailedExercise(input: Input, exercise: Exercise, repsAndSets: RepsAndSets, maxUpdated: @escaping () -> Void) -> Exercise {
        var ex  = exercise

        // —— 1RM / max-rep look-ups ———————————————
        if !ex.type.usesWeight {
            if let max = input.exerciseData.getMax(for: ex.id), max > 0 {
                ex.draftMaxReps = Int(max)
                //print("Exercise: \(ex.name), Existing Max Reps: \(max), No Recalculation Needed")
                Logger.shared.add("• Exercise: \(ex.name), Existing Max Reps: \(Int(max)), No Recalculation Needed", lineBreak: .before)
            } else {
                if let estMax = input.exerciseData.getEstimatedMax(for: ex.id), estMax > 0 {
                    ex.draftMaxReps = Int(estMax)
                    //print("Exercise: \(ex.name), Estimated Max Reps: \(estMax), No Recalculation Needed")
                    Logger.shared.add("• Exercise: \(ex.name), Estimated Max Reps: \(Int(estMax)), No Recalculation Needed", lineBreak: .before)

                } else {
                    let max = CSVLoader.calculateFinalReps(userData: input.user, exercise: ex.url)
                    ex.draftMaxReps = max
                    input.exerciseData.updateExercisePerformance(for: ex, newValue: Double(max), reps: nil, weight: nil, csvEstimate: true)
                    maxUpdated()
                    //print("Exercise: \(ex.name), Estimated Max Reps Calculated: \(max)")
                    Logger.shared.add("• Exercise: \(ex.name), Estimated Max Reps Calculated: \(Int(max))", lineBreak: .before)
                }
            }
        } else {
            if let oneRM = input.exerciseData.getMax(for: ex.id), oneRM > 0 {
                ex.draft1rm = oneRM
                //print("Exercise: \(ex.name), Existing 1RM: \(oneRM), No Recalculation Needed")
                Logger.shared.add("• Exercise: \(ex.id), Existing 1RM: \(Format.smartFormat(oneRM)), No Recalculation Needed", lineBreak: .before)
            } else {
                if let estOneRM = input.exerciseData.getEstimatedMax(for: ex.id), estOneRM > 0 {
                    //print("Exercise: \(ex.name), Estimated 1RM: \(estOneRM), No Recalculation Needed")
                    Logger.shared.add("• Exercise: \(ex.name), Estimated 1RM: \(Format.smartFormat(estOneRM)), No Recalculation Needed", lineBreak: .before)
                    ex.draft1rm = estOneRM
                } else {
                    let oneRM = CSVLoader.calculateFinal1RM(userData: input.user, exercise: ex.url)
                    ex.draft1rm = oneRM
                    input.exerciseData.updateExercisePerformance(for: ex, newValue: oneRM, reps: nil, weight: nil, csvEstimate: true)
                    maxUpdated()
                    //print("Exercise: \(ex.name), Estimated 1RM Calculated: \(oneRM)")
                    Logger.shared.add("• Exercise: \(ex.name), Estimated 1RM Calculated: \(Format.smartFormat(oneRM))", lineBreak: .before)
                }
            }
        }

        // —— Set details ————————————————————————————
        ex.setDetails = createSetDetails(exercise: ex, repsAndSets: repsAndSets, input: input)

        return handleExerciseProgression(input: input, exercise: ex)
    }
    
    func handleExerciseProgression(input: Input, exercise: Exercise) -> Exercise {
        var ex = exercise
        var prog = ex.overloadProgress

        func resetProgression() {
            ex.currentWeekAvgRPE  = nil
            ex.previousWeeksAvgRPE = nil
            ex.weeksStagnated = 0
            ex.overloadProgress = 0
            prog = 0      // keep `prog` in sync
        }
        
        // —— Progressive overload ————————————————
        // Only run this whole section if we're rolling the same template into next week
        if input.nextWeek && input.keepCurrentExercises {

            // ────────────────────────────────────────────────────────────────
            // 0️⃣  NEW PR CHECK  →  reset stagnation if a new max exists
            // ────────────────────────────────────────────────────────────────
            let newPRLogged: Bool = {
                guard
                    let maxDate   = input.exerciseData.getDateForMax(for: ex.id),
                    let creation  = input.user.workoutPlans.workoutsCreationDate
                else { return false }          // no prior creation date? treat as “no”
                
                // If the max is on or after the plan-creation date,
                // a new PR was saved during the last cycle.
                return maxDate >= creation
            }()
            
            if newPRLogged {
                Logger.shared.add("◦ New 1 RM recorded on or after last plan creation → reset stagnation.", indentTabs: 1)
                resetProgression()
            }
            
            // ────────────────────────────────────────────────────────────────
            // 1️⃣  PROGRESSIVE OVERLOAD
            // ────────────────────────────────────────────────────────────────
            if !newPRLogged,                                   // skip if we just reset
               ex.weeksStagnated >= input.user.settings.stagnationPeriod,
               input.user.settings.progressiveOverload
            {
                prog += 1
                
                Logger.shared.add(
                    "◦ Weeks stagnated (\(ex.weeksStagnated)) ≥ limit " +
                    "(\(input.user.settings.stagnationPeriod)) — applying overload.",
                    indentTabs: 1
                )
                ex.overloadProgress = prog
                ex.setDetails = applyProgressiveOverload(
                    equipmentData: input.equipmentData,
                    exercise: ex,
                    period:   input.user.settings.progressiveOverloadPeriod,
                    style:    input.user.settings.progressiveOverloadStyle,
                    roundingPreference: input.user.settings.roundingPreference
                )
            }
            
            // ────────────────────────────────────────────────────────────────
            // 2️⃣  DELOAD or +1 week stagnant
            //     (only if no new PR and no overload just applied)
            // ────────────────────────────────────────────────────────────────
            else if !newPRLogged,
                    let maxDate  = input.exerciseData.getDateForMax(for: ex.id),
                    let creation = input.user.workoutPlans.workoutsCreationDate,
                    maxDate < creation
            {
                if let currentRPE   = ex.currentWeekAvgRPE,
                   let prevRPEs     = ex.previousWeeksAvgRPE,
                   currentRPE > (prevRPEs.average ?? 0),
                   prevRPEs.count >= input.user.settings.periodUntilDeload, // count + 1 simulates inclusion of current rpe
                   input.user.settings.allowDeloading
                {
                    
                    Logger.shared.add(
                        "◦ RPE (\(currentRPE)) ≥ previous \(input.user.settings.periodUntilDeload) " +
                        "wk avg: \(prevRPEs.average ?? 0) — applying deload.",
                        indentTabs: 1
                    )
                    
                    ex.setDetails = applyDeload(
                        equipmentData: input.equipmentData,
                        exercise: ex,
                        deloadPct: input.user.settings.deloadIntensity,
                        roundingPreference: input.user.settings.roundingPreference
                    )
                    resetProgression()
                } else {
                    Logger.shared.add("◦ Weeks stagnated: \(ex.weeksStagnated) → \(ex.weeksStagnated+1)", indentTabs: 1)
                    ex.weeksStagnated += 1
                }
            }
        }

        // ────────────────────────────────────────────────────────────────────
        // 3️⃣  Reset after completing a full overload cycle
        // ────────────────────────────────────────────────────────────────────
        if prog == input.user.settings.progressiveOverloadPeriod {
            Logger.shared.add("◦ Resetting progressive-overload cycle.", indentTabs: 1)
            resetProgression()
        }
        
        return ex
    }
    
    func applyProgressiveOverload(equipmentData: EquipmentData, exercise: Exercise, period: Int, style: ProgressiveOverloadStyle, roundingPreference: RoundingPreference) -> [SetDetail] {
        let usesWeight = exercise.type.usesWeight
        let equipment = exercise.equipmentRequired
        let setDetails = exercise.setDetails
        let progress = exercise.overloadProgress
        var updatedSetDetails = setDetails
        
        for (index, setDetail) in setDetails.enumerated() {
            var updatedSetDetail = setDetail
            
            if !usesWeight {
                // increase reps
                updatedSetDetail.reps += progress // Increment reps based on progress
                
            } else {
                switch style {
                case .increaseWeight:
                    // Increase weight while keeping reps constant
                    updatedSetDetail.weight += Double(progress) * 2.5 // Add 2.5 units per week of progress
                    updatedSetDetail.weight = equipmentData.roundWeight(updatedSetDetail.weight, for: equipment, roundingPreference: roundingPreference) // Round weight
                    
                case .increaseReps:
                    // Increase reps while keeping weight constant
                    updatedSetDetail.reps += progress // Increment reps based on progress
                    
                case .decreaseReps:
                    // Decrease reps and increase weight
                    updatedSetDetail.reps = max(1, updatedSetDetail.reps - progress) // Decrease reps (minimum of 1)
                    updatedSetDetail.weight += Double(progress) * 2.5 // Add 2.5 units per week of progress
                    updatedSetDetail.weight = equipmentData.roundWeight(updatedSetDetail.weight, for: equipment, roundingPreference: roundingPreference) // Round weight
                    
                case .dynamic:
                    let halfwayPoint = period / 2
                    if progress <= halfwayPoint {
                        // First half: Increase reps
                        updatedSetDetail.reps += progress
                    } else {
                        // Second half: Reset reps, increase weight
                        let adjustedProgress = progress - halfwayPoint
                        updatedSetDetail.reps = setDetail.reps // Reset reps to original value
                        updatedSetDetail.weight += Double(adjustedProgress) * 2.5 // Increase weight
                        updatedSetDetail.weight = equipmentData.roundWeight(updatedSetDetail.weight, for: equipment, roundingPreference: roundingPreference) // Round weight
                    }
                }
            }
            updatedSetDetails[index] = updatedSetDetail
        }
        
        return updatedSetDetails
    }

    func applyDeload(equipmentData: EquipmentData, exercise: Exercise, deloadPct: Int, roundingPreference: RoundingPreference) -> [SetDetail] {
        let usesWeight = exercise.type.usesWeight
        let setDetails = exercise.setDetails
        let deloadFactor = min(Double(deloadPct) / 100.0, 1.0)
        var updatedSetDetails = setDetails
        
        for (index, setDetail) in setDetails.enumerated() {
            var updatedSetDetail = setDetail
            
            if !usesWeight {
                //print("old reps: \(updatedSetDetail.reps)")
                let newReps = Double(updatedSetDetail.reps) * deloadFactor
                updatedSetDetail.reps = Int(newReps.rounded(.down))
                //print("new reps: \(updatedSetDetail.reps)")
                
            } else {
                //print("old weight: \(updatedSetDetail.weight)")
                let weight = updatedSetDetail.weight * deloadFactor
                let roundedWeight = equipmentData.roundWeight(weight, for: exercise.equipmentRequired, roundingPreference: roundingPreference)
                updatedSetDetail.weight = roundedWeight
                //print("new weight: \(roundedWeight)")
            }
            updatedSetDetails[index] = updatedSetDetail
        }
        
        return updatedSetDetails
    }

    func createSetDetails(exercise: Exercise, repsAndSets: RepsAndSets, input: Input) -> [SetDetail] {
        var details: [SetDetail] = []
        let numSets    = repsAndSets.sets
        let range    = repsAndSets.repsRange
        let rest     = repsAndSets.restPeriod
        let setStructure = input.user.workoutPrefs.setStructure
        let roundingPref = input.user.settings.roundingPreference

        for n in 1...numSets {
            let reps: Int
            var weight: Double = 0

            if !exercise.type.usesWeight {
                let maxReps = exercise.draftMaxReps ?? 0
                switch setStructure {
                case .pyramid:
                    let minReps = Int(Double(maxReps) * 0.8)
                    let incrementPerSet = (maxReps - minReps) / max(1, numSets - 1)
                    let calculatedReps = (minReps + incrementPerSet * (n - 1)) + 1
                    reps = min(maxReps, calculatedReps) // Ensure it doesn't exceed maxReps
                    
                case .reversePyramid:
                    let decreasePerSet = max(1, Int(0.1 * Double(maxReps)))
                    reps = max(1, maxReps - decreasePerSet * (n - 1))
                    
                case .fixed:
                    reps = Int(Double(maxReps) * 0.95)
                }
            } else {
                let oneRM = exercise.draft1rm ?? 0
                switch setStructure {
                case .pyramid:
                    reps = range.upperBound - (n - 1) * (range.upperBound - range.lowerBound) / (numSets - 1)
                    
                case .reversePyramid:
                    reps = range.lowerBound + (n - 1) * (range.upperBound - range.lowerBound) / (numSets - 1)
                    
                case .fixed:
                    reps = (range.lowerBound + range.upperBound) / 2
                }
                weight = SetDetail.calculateSetWeight(oneRepMax: oneRM, reps: reps)
                weight = input.equipmentData.roundWeight(weight, for: exercise.equipmentRequired, roundingPreference: roundingPref)
            }
            details.append(SetDetail(setNumber: n, weight: exercise.type.usesWeight ? weight : 0, reps: reps, restPeriod: rest))
        }
        return details
    }
    
    func selectExercisesForDay(dayIndex: Int, usedNames: Set<String>, params: GenerationParameters, input: Input) -> [Exercise] {
        let totalExercises = params.exercisesPerWorkout
        let favorites = Set(input.user.evaluation.favoriteExercises)
        let disliked = Set(input.user.evaluation.dislikedExercises)
        
        // Expand split categories (main cat + subs)
        var targeted = params.workoutWeek.categoryForDay(index: dayIndex)
        let expanded = targeted.flatMap { parent in
            SplitCategory.muscles[parent]?
                .compactMap { SplitCategory(rawValue: $0.rawValue) } ?? []
        }
        targeted.append(contentsOf: expanded)
        
        // Body-weight filter closure
        func bodyWeightOK(_ ex: Exercise) -> Bool {
            switch input.user.workoutPrefs.ResistanceType {
            case .any: return true
            case .bodyweight:    return !ex.type.usesWeight
            case .weighted: return  ex.type.usesWeight
            default: return true
            }
        }
        
        // Main filtering pass
        let pool = input.exerciseData.allExercises.filter { ex in
            let matchesSplit = targeted.contains(.all)
            || (ex.groupCategory != nil && targeted.contains { $0 == ex.groupCategory })
            || targeted.contains(ex.splitCategory)
            
            let equipmentOK = input.user.canPerformExercise(ex, equipmentData: input.equipmentData)
            let difficultyOK = ex.difficulty.strengthValue <= input.user.evaluation.strengthLevel.strengthValue
            
            return matchesSplit
            && equipmentOK
            && difficultyOK
            && bodyWeightOK(ex)
            && !disliked.contains(ex.id)
            && !usedNames.contains(ex.name)
        }
        
        // Priority buckets – favourites first
        let compoundsFav = pool.filter { favorites.contains($0.id) && $0.effort == .compound }.shuffled()
        let isolatesFav  = pool.filter { favorites.contains($0.id) && $0.effort == .isolation }.shuffled()
        let compounds    = pool.filter { !favorites.contains($0.id) && $0.effort == .compound }.shuffled()
        let isolates     = pool.filter { !favorites.contains($0.id) && $0.effort == .isolation }.shuffled()
        
        // Build the ordered list (compound before isolation)
        var ordered = compoundsFav + compounds + isolatesFav + isolates
        ordered = input.exerciseData.distributeExercisesEvenly(ordered)
        
        var chosen = Array(ordered.prefix(totalExercises))
        
        // If we still need more, dip back into the pool without the earlier filters
        if chosen.count < totalExercises {
            let needed = totalExercises - chosen.count
            let fallback = pool.filter { !chosen.contains($0) }.prefix(needed)
            chosen.append(contentsOf: fallback)
        }
        
        return chosen
    }
    
    /// Generates warm-up sets based on the chosen set structure.
    func createWarmUpDetails(equipmentData: EquipmentData, for exercise: Exercise, baselineSet: SetDetail, setStructure: SetStructures, roundingPref: RoundingPreference) -> [SetDetail] {
        var warmUpDetails: [SetDetail] = []
        var totalWarmUpSets: Int = 0
        var weightReductionSteps: [Double] = []
        var repsIncreaseSteps: [Int] = []
        
        switch setStructure {
        case .pyramid:
            totalWarmUpSets = 2
            weightReductionSteps = [0.5, 0.65]
            repsIncreaseSteps = [12, 10]
        case .reversePyramid:
            totalWarmUpSets = 3
            weightReductionSteps = [0.5, 0.65, 0.8]
            repsIncreaseSteps = [10, 8, 6]
        default:
            totalWarmUpSets = 0
            weightReductionSteps = []
            repsIncreaseSteps = []
        }
        
        for i in 0..<totalWarmUpSets {
            let weight = baselineSet.weight * weightReductionSteps[i]
            let roundedWeight = equipmentData.roundWeight(weight, for: exercise.equipmentRequired, roundingPreference: roundingPref)
            let reps = repsIncreaseSteps[i]
            warmUpDetails.append(SetDetail(setNumber: i + 1, weight: roundedWeight, reps: reps))
        }
        
        return warmUpDetails
    }
    
    func autofillWarmUpSets(equipmentData: EquipmentData, for exercise: inout Exercise, setStructure: SetStructures, roundingPref: RoundingPreference) {
        guard let baseline = exercise.setDetails.first else { return }
        let details = createWarmUpDetails(equipmentData: equipmentData, for: exercise, baselineSet: baseline, setStructure: setStructure, roundingPref: roundingPref)
        exercise.warmUpDetails = details // add the warmup details to the exercise
    }
}
