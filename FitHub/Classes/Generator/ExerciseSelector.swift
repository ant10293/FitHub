//
//  ExerciseSelector.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/30/25.
//

import Foundation

// TODO: strengthCeiling should be applied unless we dont have enough exercises
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

    // MARK: Init
    init(
        data: ExerciseData,
        equipment: EquipmentData,
        selectedEquipment: [GymEquipment.ID],
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
    }

    // MARK: Policy
    struct Policy {
        var minCount: Int = 1
        var maxCount: Int = 20
    }

    // MARK: Immutable catalog snapshot
    private struct ExerciseIndex {
        let exercises: [Exercise]
        let bySplit: [SplitCategory: [Int]]
        let byGroup: [SplitCategory: [Int]]
        let canPerform: [Bool]

        init(data: ExerciseData, equipment: EquipmentData, selection: [GymEquipment.ID]) {
            self.exercises = data.exercisesWithData

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
    }

    // MARK: Public API - Simplified & Reliable
    func select(
        dayIndex: Int,
        categories: [SplitCategory],
        total: Int,
        rAndS: RepsAndSets,
        dayLabel: String
    ) -> [Exercise] {
        let clampedTotal = max(policy.minCount, min(policy.maxCount, total))
        guard clampedTotal > 0 else { return [] }

        var rng = seededRNG(for: dayIndex)
        let unionIdxs = idx.union(for: categories)

        logger?.add("[\(dayLabel)] Pool size: \(unionIdxs.count) exercises")

        // 1. Filter exercises based on basic criteria
        let eligibleExercises = filterEligibleExercises(
            from: unionIdxs,
            rAndS: rAndS,
            dayLabel: dayLabel
        )

        logger?.add("[\(dayLabel)] Eligible after filtering: \(eligibleExercises.count) exercises")

        if eligibleExercises.isEmpty {
            logger?.add("[\(dayLabel)] No eligible exercises found")
            return []
        }
        
        // filter by difficulty, still allowing favorites
        let eligibleFiltered = eligibleExercises.filter {
            if favorites.contains($0.id) {
                return true
            } else {
                return $0.difficultyOK(strengthCeiling)
            }
        }
        
        // TODO: add logic to derive muscles and submuscles from [SplitCategory]
        /*
        let muscles = deriveTargetMuscles(from: categories)
        print("Muscles: \(muscles)")
        let submuscles = deriveTargetSubmuscles(from: muscles)
        print("Submuscles: \(submuscles)")
        */
        
        /*
        let (targetted, grouped) = deriveTargetMuscles(from: categories)
        let targetSub = deriveTargetSubmuscles(from: targetted)
        let groupSub = deriveTargetSubmuscles(from: grouped)
        
        var coverage: CoverageState = .init(target: targetted, group: grouped, targetSub: targetSub, groupSub: groupSub)
        */
        
        // 2. Apply distribution logic - removes exercises with effortType of 0% or setCount of 0
        let countByEffort = rAndS.distribution.allocateCountsPerEffort(targetCount: clampedTotal)
        let selectedExercises = applyDistributionLogic(
            pool: eligibleFiltered,
            targetCount: clampedTotal,
            countByEffort: countByEffort,
            rng: &rng
        )

        logger?.add("[\(dayLabel)] Selected: \(selectedExercises.count) exercises")
        print("[\(dayLabel)] Selected: \(selectedExercises.map(\.name).joined(separator: ", "))")
        
        // 3. Apply balancing and return
        // TODO: if still not enough exercises after relaxing the muscle requirements, use the unfiltered eligibleExercises
        var finalSelection = selectedExercises
        if finalSelection.count < clampedTotal {
            let missingCount = clampedTotal - finalSelection.count
            let remainingCountByEffort = neededCounts(initialCounts: countByEffort, subtractingSelected: selectedExercises)
            let extraExercises = applyDistributionLogic(
                pool: eligibleExercises,
                existing: selectedExercises,
                targetCount: missingCount,
                countByEffort: remainingCountByEffort,
                rng: &rng
            )
            finalSelection.append(contentsOf: extraExercises)
        }

        // Ensure we don't exceed the target
        /*
        if finalSelection.count > clampedTotal {
            finalSelection = Array(finalSelection.prefix(clampedTotal))
        }
        */
        
        // TODO: free weight compound should go before machine
        let sortedSelection = finalSelection.sorted { $0.effort.order < $1.effort.order }

        return sortedSelection
    }
    
    private func effortExerciseCount(_ exercises: [Exercise]) -> [EffortType: Int] {
        Dictionary(grouping: exercises, by: { $0.effort }).mapValues { $0.count }
    }
    
    func neededCounts(initialCounts: [EffortType: Int], subtractingSelected selected: [Exercise]) -> [EffortType: Int] {
        let selectedCounts = effortExerciseCount(selected)
        var out: [EffortType: Int] = [:]
        out.reserveCapacity(initialCounts.count)
        for (type, target) in initialCounts {
            let left = target - (selectedCounts[type] ?? 0)
            if left > 0 { out[type] = left }
        }
        return out
    }
    
    /*
    private func deriveTargetMuscles(from categories: [SplitCategory]) -> [Muscle] {
        var targetMuscles: Set<Muscle> = []
        
        for category in categories {
            if let muscles = SplitCategory.muscles[category] { targetMuscles.formUnion(muscles) }
            if let groupMuscles = SplitCategory.groups[category] { targetMuscles.formUnion(groupMuscles) }
        }
        
        return Array(targetMuscles)
    }
    */
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
    
    // MARK: - Simplified Filtering
    private func filterEligibleExercises(
        from indices: [Int],
        rAndS: RepsAndSets,
        dayLabel: String
    ) -> [Exercise] {
        var result: [Exercise] = []

        for idx in indices {
            guard idx < self.idx.exercises.count else { continue }
            let ex = self.idx.exercises[idx]

            if disliked.contains(ex.id) { continue }
            if !self.idx.canPerform[idx] { continue }
            if !ex.resistanceOK(resistance) { continue }
            // DO NOT check difficulty here
            if !ex.effortOK(rAndS) { continue }
            if rAndS.sets.sets(for: ex.effort) < 1 { continue }

            result.append(ex)
        }
        return result
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
            let neededCount = min(needed, targetCount)
            
            // TODO: this should take parameters for the SplitCategory/Muscle
            let selected = selectRandomExercises(from: matchingExercises, count: neededCount, rng: &rng)
            
            selectedExercises.append(contentsOf: selected)
            
            // Remove selected exercises from remaining pool to avoid duplicates
            let selectedIds = Set(selected.map(\.id))
            remainingExercises = remainingExercises.filter { !selectedIds.contains($0.id) }
        }
        
        // If we still need more exercises, fill from remaining pool
        if selectedExercises.count < targetCount && !remainingExercises.isEmpty {
            let needed = targetCount - selectedExercises.count
            let additional = selectRandomExercises(from: remainingExercises, count: needed, rng: &rng)
            selectedExercises.append(contentsOf: additional)
        }
        
        return selectedExercises
    }
    
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
        let actualCount = min(count, array.count)
        guard actualCount > 0 else { return [] }
        
        if actualCount == array.count { return array.shuffled(using: &rng) }
        
        // Prioritize favorite exercises first
        let sortedExercises = array.sorted { ex1, ex2 in
            let ex1IsFavorite = favorites.contains(ex1.id)
            let ex2IsFavorite = favorites.contains(ex2.id)
            
            if ex1IsFavorite != ex2IsFavorite { return ex1IsFavorite } // Favorites first
            // If both are favorites or both are not, maintain random order
            return false
        }
        
        // Log favorite prioritization
        let favoriteCount = sortedExercises.prefix(actualCount).filter { favorites.contains($0.id) }.count
        if favoriteCount > 0 {
            logger?.add("Prioritized \(favoriteCount) favorite exercises")
        }
        
        let shuffled = sortedExercises.shuffled(using: &rng)
        return Array(shuffled.prefix(actualCount))
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


