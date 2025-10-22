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
    private let policy: Policy
    private let logger: Logger?
    private let baseSeed: UInt64
    private var reductions: DayReductions
    
    // MARK: Init
    init(
        data: ExerciseData,
        equipment: EquipmentData,
        selectedEquipment: [GymEquipment.ID],
        days: [DaysOfWeek],
        favorites: Set<Exercise.ID>,
        disliked: Set<Exercise.ID>,
        resistance: ResistanceType,
        strengthCeiling: Int,
        policy: Policy = Policy(),
        logger: Logger? = nil,
        seed: UInt64 = 0
    ) {
        self.idx = ExerciseIndex(data: data, equipment: equipment, selection: selectedEquipment)
        self.favorites = favorites
        self.disliked = disliked
        self.strengthCeiling = strengthCeiling
        self.resistance = resistance
        self.policy = policy
        self.logger = logger
        self.baseSeed = seed
        self.reductions = .init(preseed: days)
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
                split[ex.splitCategory, default: []].append(i)
                if let g = ex.groupCategory { group[g, default: []].append(i) }
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
        categories: [SplitCategory],
        total: Int,
        rAndS: RepsAndSets,
        dayLabel: String,
        existing: [Exercise]? = nil
    ) -> ([Exercise], PoolReduction?) {
                
        let clampedTotal = max(policy.minCount, min(policy.maxCount, total))
        guard clampedTotal > 0 else { return ([], nil) }

        var rng = seededRNG(for: dayIndex)
        let unionIdxs = idx.union(for: categories)

        logger?.add("[\(dayLabel)] Pool size: \(unionIdxs.count) exercises")
        
        let ewd = idx.getExercisesWithDataCount()
        reductions.record(dayRaw: dayLabel, reason: .split, before: ewd, after: unionIdxs.count)
        
        // 1. Filter exercises based on basic criteria
        let eligibleExercises = filterEligibleExercises(
            from: unionIdxs,
            rAndS: rAndS,
            dayLabel: dayLabel
        )

        logger?.add("[\(dayLabel)] Eligible after filtering: \(eligibleExercises.count) exercises")
        
        // 2) Difficulty AND too-easy-reps, favorites bypass
        let eligibleFiltered = additionalFiltering(
            eligibleExercises: eligibleExercises,
            rAndS: rAndS,
            dayLabel: dayLabel
        )    
        
        // 2. Apply distribution logic - removes exercises with effortType of 0% or setCount of 0
        let baseExisting = existing ?? []
        let countByEffort = rAndS.distribution.allocateCountsPerEffort(targetCount: clampedTotal)
        let countByEffortWithExisting = neededCounts(initialCounts: countByEffort, subtractingSelected: baseExisting)
        
        let selectedExercises = applyDistributionLogic(
            pool: eligibleFiltered,
            existing: baseExisting,
            targetCount: clampedTotal,
            countByEffort: countByEffortWithExisting,
            rng: &rng
        )
        logger?.add("[\(dayLabel)] Selected: \(selectedExercises.count) exercises")
        print("[\(dayLabel)] Selected: \(selectedExercises.map(\.name).joined(separator: ", "))")
        
        let selectedWithExisting = selectedExercises + baseExisting
        
        // TODO: remove reduction reasons for difficulty and repCap if we use this
        // 3. Apply balancing and return
        // TODO: if still not enough exercises after relaxing the muscle requirements, use the unfiltered eligibleExercises
        var finalSelection = selectedWithExisting
        if finalSelection.count < clampedTotal {
            reductions.record(dayRaw: dayLabel, relaxed: true)
            reductions.clear(dayRaw: dayLabel, reasons: [.repCap, .tooDifficult])
            
            let missingCount = clampedTotal - finalSelection.count
            let remainingCountByEffort = neededCounts(
                initialCounts: countByEffortWithExisting,
                subtractingSelected: selectedExercises
            )
            let extraExercises = applyDistributionLogic(
                pool: eligibleExercises,
                existing: selectedWithExisting, // include both existing + already picked
                targetCount: missingCount,
                countByEffort: remainingCountByEffort,
                rng: &rng
            )
            finalSelection.append(contentsOf: extraExercises)
        }
        
        // TODO: free weight compound should go before machine
        let sortedSelection = finalSelection.sorted { $0.effort.order < $1.effort.order }

        let pool = reductions.pool(for: dayLabel)
        return (sortedSelection, pool)
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
    
    // MARK: - Simplified Filtering
    private func filterEligibleExercises(
        from indices: [Int],
        rAndS: RepsAndSets,
        dayLabel: String
    ) -> [Exercise] {
        var result: [Exercise] = []
        
        var isDisliked: Set<Exercise.ID> = []
        var cannotPerform: Set<Exercise.ID> = []
        var invalidResistance: Set<Exercise.ID> = []
        var invalidEffort: Set<Exercise.ID> = []
        var invalidSets: Set<Exercise.ID> = []
        
        for idx in indices {
            guard idx < self.idx.exercises.count else { continue }
            let ex = self.idx.exercises[idx]

            if disliked.contains(ex.id) {
                isDisliked.insert(ex.id)
                continue
            }
            if !self.idx.canPerform[idx] {
                cannotPerform.insert(ex.id)
                continue
            }
            if !ex.resistanceOK(resistance) {
                invalidResistance.insert(ex.id)
                continue
            }
            // DO NOT check difficulty here
            if !ex.effortOK(rAndS) {
                invalidEffort.insert(ex.id)
                continue
            }
            if rAndS.sets.sets(for: ex.effort) < 1 {
                invalidSets.insert(ex.id)
                continue
            }

            result.append(ex)
        }
        
        if !isDisliked.isEmpty { reductions.record(dayRaw: dayLabel, reason: .disliked, ids: isDisliked) }
        if !cannotPerform.isEmpty { reductions.record(dayRaw: dayLabel, reason: .cannotPerform, ids: cannotPerform) }
        if !invalidResistance.isEmpty { reductions.record(dayRaw: dayLabel, reason: .resistance, ids: invalidResistance) }
        if !invalidEffort.isEmpty { reductions.record(dayRaw: dayLabel, reason: .effort, ids: invalidEffort) }
        if !invalidSets.isEmpty { reductions.record(dayRaw: dayLabel, reason: .sets, ids: invalidSets) }
        
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
        var exceedsRepCap: Set<Exercise.ID> = []
        
        let eligibleFiltered = eligibleExercises.filter { ex in
            if favorites.contains(ex.id) { return true }
            // cheap early checks
            guard ex.difficultyOK(strengthCeiling) else {
                tooDifficult.insert(ex.id)
                return false
            }
            // reps-cap check only for repsOnly + when we actually have a max
            if ex.unitType == .repsOnly, let max = ex.draftMax?.actualValue,
               Double(rAndS.reps.reps(for: ex.effort).upperBound) * 2 < max
            {
                exceedsRepCap.insert(ex.id)
                return false
            }
            return true
        }
        
        if !tooDifficult.isEmpty { reductions.record(dayRaw: dayLabel, reason: .tooDifficult, ids: tooDifficult) }
        if !exceedsRepCap.isEmpty { reductions.record(dayRaw: dayLabel, reason: .repCap, ids: exceedsRepCap) }
        
        return eligibleFiltered
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
}

