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
    private let strengthCeiling: StrengthLevel
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
        strengthCeiling: StrengthLevel,
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
        usedNames: Set<String>,
        total: Int,
        rAndS: RepsAndSets,
        dayLabel: String
    ) -> [Exercise] {
        let clampedTotal = max(policy.minCount, min(policy.maxCount, total))
        guard clampedTotal > 0 else { return [] }

        var rng = seededRNG(for: dayIndex)
        let expanded = expand(categories)

        let unionIdxs = idx.union(for: expanded)

        logger?.add("[\(dayLabel)] Pool size: \(unionIdxs.count) exercises")

        // 1. Filter exercises based on basic criteria
        let eligibleExercises = filterEligibleExercises(
            from: unionIdxs,
            usedNames: usedNames,
            rAndS: rAndS,
            dayLabel: dayLabel
        )

        logger?.add("[\(dayLabel)] Eligible after filtering: \(eligibleExercises.count) exercises")

        if eligibleExercises.isEmpty {
            logger?.add("[\(dayLabel)] No eligible exercises found")
            return []
        }

        // 2. Apply distribution logic - removes exercises with effortType of 0% or setCount of 0
        let selectedExercises = applyDistributionLogic(
            exercises: eligibleExercises,
            targetCount: clampedTotal,
            rAndS: rAndS,
            rng: &rng
        )

        logger?.add("[\(dayLabel)] Selected: \(selectedExercises.count) exercises")
        print("[\(dayLabel)] Selected: \(selectedExercises.map(\.name).joined(separator: ", "))")

        // 3. Apply balancing and return
        var finalSelection = selectedExercises
        if !finalSelection.isEmpty {
            // Try with muscle filtering first
            var balanced = distributeExercisesEvenly(finalSelection)
            
            // If we don't have enough exercises after muscle filtering, try without it
            if balanced.count < clampedTotal && finalSelection.count >= clampedTotal {
                // Return original selection without muscle filtering
                balanced = finalSelection
            }
            
            finalSelection = balanced
        }

        // Ensure we don't exceed the target
        if finalSelection.count > clampedTotal {
            finalSelection = Array(finalSelection.prefix(clampedTotal))
        }

        return finalSelection
    }

    // MARK: - Simplified Filtering
    private func filterEligibleExercises(
        from indices: [Int],
        usedNames: Set<String>,
        rAndS: RepsAndSets,
        dayLabel: String
    ) -> [Exercise] {
        
        var filteredCount = 0
        var dislikedCount = 0
      //  var usedNamesCount = 0
        var cantPerformCount = 0
        var resistanceCount = 0
        var effortOKCount = 0
        
        var result: [Exercise] = []
        
        for idx in indices {
            let ex = self.idx.exercises[idx]
            
            // Basic filters - skip this exercise if any condition fails
            if disliked.contains(ex.id) { 
                dislikedCount += 1
                continue
            }
            
            // SMART usedNames filter: Only filter if we have plenty of alternatives
            // This prevents the "all exercises are used" problem while still avoiding duplicates
           /*
            if usedNames.contains(ex.name) && usedNames.count >= 3 {
                usedNamesCount += 1
                continue
            }
            */
            
            if !self.idx.canPerform[idx] {
                cantPerformCount += 1
                continue
            }
            if !ex.resistanceOK(resistance) { 
                resistanceCount += 1
                continue
            }
            
            // CRITICAL: Only include exercises that have sets configured AND positive distribution
            if !ex.effortOK(rAndS) { 
                effortOKCount += 1
                continue
            }
            
            filteredCount += 1
            result.append(ex)
        }
        
        return result
    }

    // MARK: - Simplified Distribution Logic
    private func applyDistributionLogic(
        exercises: [Exercise],
        targetCount: Int,
        rAndS: RepsAndSets,
        rng: inout SeededRNG
    ) -> [Exercise] {
        // Get the normalized distribution (this filters out effort types with 0 sets)
        let distribution = rAndS.normalizedDistribution
        
        var selectedExercises: [Exercise] = []
        var remainingExercises = exercises
        
        // For each effort type, select exercises according to distribution
        for (effort, percentage) in distribution {
            let targetForType = Int(round(Double(targetCount) * percentage))
            guard targetForType > 0 else { continue }
            
            let exercisesOfType = remainingExercises.filter { $0.effort == effort }
            let availableCount = exercisesOfType.count
            
            if availableCount == 0 { continue }
            
            let actualCount = min(targetForType, availableCount)
            print("ExercisesOfType: \(exercisesOfType.map(\.name).joined(separator: ", "))")
            let selected = selectRandomExercises(from: exercisesOfType, count: actualCount, rng: &rng)
            
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
    
    // FIXME: needs to work with muscleEngagement changes
    private func distributeExercisesEvenly(_ exercises: [Exercise]) -> [Exercise] {
        var distributedExercises: [Exercise] = []
        // Tracks unique combinations of primary and secondary muscle groups.
        var muscleCombinationsUsed: [(primary: Set<SubMuscles>, secondary: Set<SubMuscles>)] = []
        
        // Check if the combination of primary and secondary muscles is unique
        func isUniqueCombination(_ exercise: Exercise) -> Bool {
            let primarySet = Set(exercise.primarySubMuscles ?? [])
            let secondarySet = Set(exercise.secondarySubMuscles ?? [])
            
            for combo in muscleCombinationsUsed {
                if combo.primary == primarySet && combo.secondary == secondarySet {
                    //print("Combination already used: Primary: \(combo.primary), Secondary: \(combo.secondary)")
                    return false
                }
            }
            //print("Combination is unique")
            return true
        }
        
        // Add the combination to the tracking set
        func addCombination(_ exercise: Exercise) {
            let primarySet = Set(exercise.primarySubMuscles ?? [])
            let secondarySet = Set(exercise.secondarySubMuscles ?? [])
            
            muscleCombinationsUsed.append((primary: primarySet, secondary: secondarySet))
            //print("Added combination: Primary: \(primarySet), Secondary: \(secondarySet)")
        }
        
        func filter(for type: EffortType) {
            exercises.filter({ $0.effort == type }).forEach { exercise in
                //print("Processing compound exercise: \(exercise.name)")
                if isUniqueCombination(exercise) {
                    distributedExercises.append(exercise)
                    addCombination(exercise)
                }
            }
        }
        
        for type in EffortType.allCases {
            filter(for: type)
        }
        
        //print("Distributed exercises: \(distributedExercises.map { $0.name })")
        return distributedExercises
    }
    
    // MARK: - Exercise Selection with Favorite Prioritization
    private func selectRandomExercises(from array: [Exercise], count: Int, rng: inout SeededRNG) -> [Exercise] {
        let actualCount = min(count, array.count)
        guard actualCount > 0 else { return [] }
        
        if actualCount == array.count {
            return array.shuffled(using: &rng)
        }
        
        // Prioritize favorite exercises first
        let sortedExercises = array.sorted { ex1, ex2 in
            let ex1IsFavorite = favorites.contains(ex1.id)
            let ex2IsFavorite = favorites.contains(ex2.id)
            
            if ex1IsFavorite != ex2IsFavorite {
                return ex1IsFavorite // Favorites first
            }
            
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

    // MARK: Helpers
    private func expand(_ categories: [SplitCategory]) -> [SplitCategory] {
        var out: Set<SplitCategory> = Set(categories)
        for parent in categories {
            if let subs = SplitCategory.muscles[parent] {
                for s in subs {
                    if let sc = SplitCategory(rawValue: s.rawValue) { out.insert(sc) }
                }
            }
        }
        return Array(out)
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

