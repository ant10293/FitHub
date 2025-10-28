//
//  ExerciseSelector.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/30/25.
//

import Foundation


// MARK: - ExerciseSelector (Simplified & Reliable)
final class ExerciseSelector {
    // MARK: Dependencies
    private let idx: ExerciseIndex
    private let favorites: Set<Exercise.ID>
    private let disliked: Set<Exercise.ID>
    private let strengthCeiling: Int
    private let resistance: ResistanceType
    private let allowDisliked: Bool
    private let allowDifficult: Bool
    private let nonDefaultParams: Set<PoolChanges.RelaxedFilter>
    private let policy: Policy
    private let baseSeed: UInt64
    private var changes: DayChanges
    
    // MARK: Init
    init(
        exerciseData: ExerciseData,
        equipmentData: EquipmentData,
        userData: UserData,
        days: [DaysOfWeek],
        nonDefaultParams: Set<PoolChanges.RelaxedFilter>,
        policy: Policy = Policy(),
        seed: UInt64 = 0
    ) {
        self.idx = ExerciseIndex(
            data: exerciseData,
            equipment: equipmentData,
            selection: userData.evaluation.equipmentSelected
        )
        self.favorites = userData.evaluation.favoriteExercises
        self.disliked = userData.evaluation.dislikedExercises
        self.strengthCeiling = userData.evaluation.strengthLevel.strengthValue
        self.resistance = userData.workoutPrefs.resistance
        self.allowDisliked = userData.allowDisliked
        self.allowDifficult = userData.allowDifficult
        self.nonDefaultParams = nonDefaultParams
        self.policy = policy
        self.baseSeed = seed
        self.changes = .init(preseed: days)
    }
    
    // MARK: Policy
    struct Policy {
        var minCount: Int = 1
        var maxCount: Int = 20
    }
    
    // MARK: Immutable catalog snapshot
    private struct ExerciseIndex {
        let allExercisesCount: Int
        let exercisesWithDataCount: Int
        let exercises: [Exercise]
        let bySplit: [SplitCategory: [Int]]
        let byGroup: [SplitCategory: [Int]]
        let canPerform: [Bool]
        
        init(data: ExerciseData, equipment: EquipmentData, selection: [GymEquipment.ID]) {
            self.allExercisesCount = data.allExercises.count
            
            // TODO: add option to use all exercises instead of just those with data
            self.exercises = data.exercisesWithData
            
            self.exercisesWithDataCount = exercises.count
            
            var split: [SplitCategory: [Int]] = [:]
            var group: [SplitCategory: [Int]] = [:]
            split.reserveCapacity(64)
            group.reserveCapacity(64)
            
            var perf: [Bool] = []
            perf.reserveCapacity(exercises.count)
            
            for (i, ex) in exercises.enumerated() {
                if let s = ex.splitCategory { split[s, default: []].append(i) }
                if let g = ex.groupCategory(forGeneration: true) { group[g, default: []].append(i) }
                perf.append(ex.canPerform(equipmentData: equipment, equipmentSelected: selection))
            }
            
            self.bySplit = split
            self.byGroup = group
            self.canPerform = perf
        }
        
        func union(for categories: [SplitCategory]) -> [Int] {
            guard !categories.isEmpty else { return [] }
            if categories.contains(.all) { return Array(exercises.indices) }
            
            var seen = Set<Int>()
            var out: [Int] = []
            
            for c in categories {
                if let s = bySplit[c] { for i in s where seen.insert(i).inserted { out.append(i) } }
                if let g = byGroup[c] { for i in g where seen.insert(i).inserted { out.append(i) } }
            }
            return out
        }
        
        func getAllExercisesCount() -> Int { return allExercisesCount }
        func getExercisesWithDataCount() -> Int { return exercisesWithDataCount }
    }
    
    // MARK: Public API - Simplified & Reliable
    func select(
        dayIndex: Int,
        dayLabel: String,
        categories: [SplitCategory],
        total: Int,
        rAndS: RepsAndSets,
        existing: [Exercise]? = nil
    ) -> ([Exercise], PoolChanges?) {
        let clampedTotal = max(policy.minCount, min(policy.maxCount, total))
        guard clampedTotal > 0 else { return ([], nil) }

        var rng = seededRNG(for: dayIndex)
        let baseExisting = existing ?? []

        let relaxed = changes.pool(for: dayLabel)?.relaxedFilters ?? []
        var currentRelaxed = Set(relaxed)
        // Attempt once with currentRelaxed
        var finalSelection = attemptSelection(
            dayLabel: dayLabel,
            categories: categories,
            clampedTotal: clampedTotal,
            rAndS: rAndS,
            baseExisting: baseExisting,
            rng: &rng,
            relaxed: currentRelaxed
        )
        
        // If short, progressively relax one filter at a time and retry
        for f in PoolChanges.RelaxedFilter.ordered(excluding: nonDefaultParams) where finalSelection.count < clampedTotal && !currentRelaxed.contains(f) {
            print("relaxing \(f), finalSelection count: \(finalSelection.count)")
            currentRelaxed.insert(f)
            changes.record(dayRaw: dayLabel, relaxed: f)
            //changes.clear(dayRaw: dayLabel, reasons: [f.correspondingReduction])
            finalSelection = attemptSelection(
                dayLabel: dayLabel,
                categories: categories,
                clampedTotal: clampedTotal,
                rAndS: rAndS,
                baseExisting: baseExisting,
                rng: &rng,
                relaxed: currentRelaxed
            )
        }

        return (finalSelection.sorted { $0.effort.order < $1.effort.order },
                changes.pool(for: dayLabel))
    }
    
    private func attemptSelection(
        dayLabel: String,
        categories: [SplitCategory],
        clampedTotal: Int,
        rAndS: RepsAndSets,
        baseExisting: [Exercise],
        rng: inout SeededRNG,
        relaxed: Set<PoolChanges.RelaxedFilter>
    ) -> [Exercise] {

        // Pool width (split vs .all)
        let unionIdxs: [Int] = {
            if relaxed.contains(.split) {
                return idx.union(for: [.all])
            } else {
                return idx.union(for: categories)
            }
        }()

        let ewd = idx.getExercisesWithDataCount()
        changes.record(dayRaw: dayLabel, reason: .init(reason: .split, beforeCount: ewd, afterCount: unionIdxs.count))

        // 1) Eligibility filtering (gates read `relaxed`)
        let eligible = filterEligibleExercises(
            from: unionIdxs,
            rAndS: rAndS,
            dayLabel: dayLabel,
            relaxed: relaxed
        )

        // 2) Difficulty filtering (skipped if .difficulty relaxed)
        let eligibleFiltered: [Exercise] = {
            if relaxed.contains(.difficulty) { return eligible }
            return additionalFiltering(
                eligibleExercises: eligible,
                rAndS: rAndS,
                dayLabel: dayLabel
            )
        }()
        
        // 3) Distribution selection
        let countByEffort = rAndS.distribution.allocateCountsPerEffort(targetCount: clampedTotal)
        let withExisting  = neededCounts(initialCounts: countByEffort, subtractingSelected: baseExisting)

        let newSelection = applyDistributionLogic(
            pool: eligibleFiltered,
            existing: baseExisting,
            targetCount: clampedTotal,
            countByEffort: withExisting,
            rng: &rng
        )
        
        var selection = newSelection + baseExisting
        if selection.count < clampedTotal {
            let missing = clampedTotal - selection.count
            let remaining = neededCounts(initialCounts: withExisting, subtractingSelected: newSelection)

            let extras = applyDistributionLogic(
                pool: eligible,
                existing: selection,
                targetCount: missing,
                countByEffort: remaining,
                rng: &rng
            )
            selection.append(contentsOf: extras)
        }
  
        return selection
    }

    private func filterEligibleExercises(
        from indices: [Int],
        rAndS: RepsAndSets,
        dayLabel: String,
        relaxed: Set<PoolChanges.RelaxedFilter>    // NEW PARAM
    ) -> [Exercise] {
        var result: [Exercise] = []

        var isDisliked: Set<Exercise.ID> = []
        var invalidResistance: Set<Exercise.ID> = []
        var cannotPerform: Set<Exercise.ID> = []
        var invalidEffort: Set<Exercise.ID> = []
        var invalidSets: Set<Exercise.ID> = []
        var exceedsRepCap: Set<Exercise.ID> = []
        var missesRepMin: Set<Exercise.ID> = []

        for i in indices {
            guard i < self.idx.exercises.count else { continue }
            let ex = self.idx.exercises[i]

            if !allowDisliked, disliked.contains(ex.id) {
                isDisliked.insert(ex.id); continue
            }
            if !relaxed.contains(.resistance), !ex.resistanceOK(resistance) {
                invalidResistance.insert(ex.id); continue
            }
            if !self.idx.canPerform[i] {
                cannotPerform.insert(ex.id); continue
            }
            if !relaxed.contains(.effort), !ex.effortOK(rAndS) {
                invalidEffort.insert(ex.id); continue
            }
            if rAndS.sets.sets(for: ex.effort) < 1 {
                invalidSets.insert(ex.id); continue
            }
            if ex.unitType == .repsOnly, let max = ex.draftMax?.actualValue {
                let repRange = rAndS.reps.reps(for: ex.effort)
                if Double(repRange.lowerBound) > max {
                    missesRepMin.insert(ex.id); continue
                }
                if !relaxed.contains(.repCap), Double(repRange.upperBound) * 2 < max {
                    exceedsRepCap.insert(ex.id); continue
                }
            }
            
            result.append(ex)
        }

        if !isDisliked.isEmpty        { changes.record(dayRaw: dayLabel, reason: .init(reason: .disliked,    exerciseIDs: isDisliked)) }
        if !invalidResistance.isEmpty { changes.record(dayRaw: dayLabel, reason: .init(reason: .resistance,  exerciseIDs: invalidResistance)) }
        if !cannotPerform.isEmpty     { changes.record(dayRaw: dayLabel, reason: .init(reason: .cannotPerform,exerciseIDs: cannotPerform)) }
        if !invalidEffort.isEmpty     { changes.record(dayRaw: dayLabel, reason: .init(reason: .effort,      exerciseIDs: invalidEffort)) }
        if !invalidSets.isEmpty       { changes.record(dayRaw: dayLabel, reason: .init(reason: .sets,        exerciseIDs: invalidSets)) }
        if !exceedsRepCap.isEmpty     { changes.record(dayRaw: dayLabel, reason: .init(reason: .repCap,      exerciseIDs: exceedsRepCap)) }
        if !missesRepMin.isEmpty      { changes.record(dayRaw: dayLabel, reason: .init(reason: .repMin,      exerciseIDs: missesRepMin)) }

        return result
    }
    
    // MARK: - Advanced Filtering (for difficulty & rep cap)
    // FIXME: should use indices like other filter func
    private func additionalFiltering(
        eligibleExercises: [Exercise],
        rAndS: RepsAndSets,
        dayLabel: String
    ) -> [Exercise] {
        var tooDifficult: Set<Exercise.ID> = []
        
        let eligibleFiltered = eligibleExercises.filter { ex in
            if favorites.contains(ex.id) { return true }
            // cheap early checks
            guard !allowDifficult, ex.difficultyOK(strengthCeiling) else {
                tooDifficult.insert(ex.id)
                return false
            }
 
            return true
        }
        
        if !tooDifficult.isEmpty { changes.record(dayRaw: dayLabel, reason: .init(reason: .tooDifficult, exerciseIDs: tooDifficult)) }
        
        return eligibleFiltered
    }
    
    // TODO: we need to select using SubMuscle, but if the Muscle has no submucles, we use Muscle
    // MARK: - Simplified Distribution Logic
    private func applyDistributionLogic(
        pool: [Exercise],
        existing: [Exercise]? = nil,
        targetCount: Int,
        countByEffort: [EffortType: Int],
        rng: inout SeededRNG
    ) -> [Exercise] {
        var selectedExercises: [Exercise] = []
        var remainingExercises = getExercisePool(pool: pool, existing: existing)
        
        // For each effort type, select exercises according to distribution
        for (effort, needed) in countByEffort {
            let matchingExercises = remainingExercises.filter { $0.effort == effort }
            let take = min(needed, matchingExercises.count) // cap by availability
            
            // TODO: this should take parameters for the SplitCategory/Muscle
            let selected = selectRandomExercises(from: matchingExercises, count: take, rng: &rng)
            
            selectedExercises.append(contentsOf: selected)
            
            // Remove selected exercises from remaining pool to avoid duplicates
            let selectedIds = Set(selected.map(\.id))
            remainingExercises = remainingExercises.filter { !selectedIds.contains($0.id) }
        }
        
        return selectedExercises
    }
}

extension ExerciseSelector {
    private func getExercisePool(pool: [Exercise], existing: [Exercise]? = nil) -> [Exercise] {
        guard let existing, !existing.isEmpty else { return pool }
        
        let exclude = Set((existing).map(\.id))
        // One pass: skip excluded, keep first occurrence per id
        let remaining: [Exercise] = pool.reduce(into: (seen: Set<Exercise.ID>(), out: [Exercise]())) { acc, ex in
            guard !exclude.contains(ex.id) else { return }
            if acc.seen.insert(ex.id).inserted { acc.out.append(ex) }
        }.out
        
        return remaining
    }
    
    // MARK: - Exercise Selection with Favorite Prioritization
    private func selectRandomExercises(from array: [Exercise], count: Int, rng: inout SeededRNG) -> [Exercise] {
        let actual = min(count, array.count)
        guard actual > 0 else { return [] }

        let favs = array.filter { favorites.contains($0.id) }
        let non  = array.filter { !favorites.contains($0.id) }

        let takeFav = min(favs.count, actual)
        var picked  = Array(favs.shuffled(using: &rng).prefix(takeFav))

        if picked.count < actual {
            let need = actual - picked.count
            picked.append(contentsOf: non.shuffled(using: &rng).prefix(need))
        }
        return picked
    }
    
    // MARK: Deterministic RNG
    private struct SeededRNG: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    private func seededRNG(for dayIndex: Int) -> SeededRNG {
        let mix: UInt64 = 0x9E3779B97F4A7C15 &* UInt64(1 + dayIndex)
        return SeededRNG(seed: baseSeed ^ mix)
    }
}

extension ExerciseSelector {
    private func effortExerciseCount(_ exercises: [Exercise]) -> [EffortType: Int] {
        Dictionary(grouping: exercises, by: { $0.effort }).mapValues { $0.count }
    }
    
    private func neededCounts(initialCounts: [EffortType: Int], subtractingSelected selected: [Exercise]) -> [EffortType: Int] {
        guard !selected.isEmpty else { return initialCounts }
        let selectedCounts = effortExerciseCount(selected)
        var out: [EffortType: Int] = [:]
        out.reserveCapacity(initialCounts.count)
        for (type, target) in initialCounts {
            let left = target - (selectedCounts[type] ?? 0)
            if left > 0 { out[type] = left }
        }
        return out
    }
}

extension ExerciseSelector {
    /*
    private func deriveTargetMuscles(from categories: [SplitCategory]) -> (target: [Muscle], group: [Muscle]) {
        var targetMuscles: Set<Muscle> = []
        var groupMuscles: Set<Muscle> = []
        
        for category in categories {
            if let muscles = SplitCategory.muscles[category] { targetMuscles.formUnion(muscles) }
            if let groups = SplitCategory.groups[category] { groupMuscles.formUnion(groups) }
        }
        
        return (Array(targetMuscles), Array(groupMuscles))
    }

    private func deriveTargetSubmuscles(from muscles: [Muscle]) -> [SubMuscles] {
        var targetSubmuscles: Set<SubMuscles> = []
        
        for muscle in muscles {
            if let submuscles = Muscle.SubMuscles[muscle] { targetSubmuscles.formUnion(submuscles) }
        }
        
        return Array(targetSubmuscles)
    }
    */
}

