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
    private let repCapMultiplier: Double
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
            selection: userData.evaluation.availableEquipment
        )
        self.favorites = userData.evaluation.favoriteExercises
        self.disliked = userData.evaluation.dislikedExercises
        self.strengthCeiling = userData.evaluation.strengthLevel.strengthValue
        self.resistance = userData.workoutPrefs.resistance
        self.allowDisliked = userData.allowDisliked
        self.repCapMultiplier = userData.workoutPrefs.maxBwRepCapMultiplier
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
        
        init(data: ExerciseData, equipment: EquipmentData, selection: Set<GymEquipment.ID>) {
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
                perf.append(ex.canPerform(equipmentData: equipment, available: selection))
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
        existing: [Exercise]
    ) -> ([Exercise], PoolChanges?) {
        let clampedTotal = max(policy.minCount, min(policy.maxCount, total))
        guard clampedTotal > 0 else { return (existing, nil) }
        
        var rng = seededRNG(for: dayIndex)
        let relaxed = changes.pool(for: dayLabel)?.relaxedFilters ?? []
        var currentRelaxed = Set(relaxed)
        // Attempt once with currentRelaxed
        var finalSelection = attemptSelection(
            dayLabel: dayLabel,
            categories: categories,
            clampedTotal: clampedTotal,
            rAndS: rAndS,
            baseExisting: existing,
            rng: &rng,
            relaxed: currentRelaxed
        )
        
        // If short, progressively relax one filter at a time and retry
        for f in PoolChanges.RelaxedFilter.ordered(excluding: nonDefaultParams)
        where finalSelection.count < clampedTotal && !currentRelaxed.contains(f) {
            currentRelaxed.insert(f)
            changes.record(dayRaw: dayLabel, relaxed: f)
            //changes.clear(dayRaw: dayLabel, reasons: [f.correspondingReduction])
            finalSelection = attemptSelection(
                dayLabel: dayLabel,
                categories: categories,
                clampedTotal: clampedTotal,
                rAndS: rAndS,
                baseExisting: existing,
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
    
        var coverage: CoverageState = {
            if let coverage = changes.pool(for: dayLabel)?.coverage {
                return coverage
            } else {
                var initCoverage: CoverageState = .init(categories: categories)
                for ex in baseExisting {
                    initCoverage.apply(exercise: ex)
                }
                //print("Coverage: \(initCoverage)")
                return initCoverage
            }
        }()
        
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

        let targets = coverage.orderedTargetSpecs()

        // 3) Distribution selection
        let countByEffort = rAndS.distribution.allocateCountsPerEffort(targetCount: clampedTotal)
        let withExisting  = neededCounts(initialCounts: countByEffort, subtractingSelected: baseExisting)
        let selection = applyDistributionLogic(
            pool: eligible,
            existing: baseExisting,
            targets: targets,
            countByEffort: withExisting,
            rng: &rng
        )
       // print("new selection: \(selection.map(\.name))")
        for ex in selection {
            coverage.apply(exercise: ex)
        }
        
        // place at the end of func
        changes.updateCoverage(dayRaw: dayLabel, coverage: coverage)
  
        return selection + baseExisting
    }
    
    // TODO: we need to select using SubMuscle, but if the Muscle has no submucles, we use Muscle
    // MARK: - Simplified Distribution Logic
    private func applyDistributionLogic(
        pool: [Exercise],
        existing: [Exercise]? = nil,
        targets: [TargetSpec],
        countByEffort: [EffortType: Int],
        rng: inout SeededRNG
    ) -> [Exercise] {
        var selectedExercises: [Exercise] = []
        var remainingExercises = getExercisePool(pool: pool, existing: existing)
        let baseExisting = existing ?? []
        
        // For each effort type, select exercises according to distribution
        for (effort, needed) in countByEffort where needed > 0 {
            let matchingExercises = remainingExercises.filter { $0.effort == effort }
            let take = min(needed, matchingExercises.count) // cap by availability
            
            // Combine base existing with already selected exercises for similarity comparison
            let currentExisting = baseExisting + selectedExercises
                        
            let selected: [Exercise]
            if let best = selectBestForTargets(from: matchingExercises, targets: targets, count: take, existing: currentExisting, rng: &rng) {
                selected = best
            } else {
                selected = selectRandomExercises(from: matchingExercises, count: take, existing: currentExisting, rng: &rng)
            }
            selectedExercises.append(contentsOf: selected)
            
            // Remove selected exercises from remaining pool to avoid duplicates
            let selectedIds = Set(selected.map(\.id))
            remainingExercises = remainingExercises.filter { !selectedIds.contains($0.id) }
        }
        
        return selectedExercises
    }
    
    private func filterEligibleExercises(
        from indices: [Int],
        rAndS: RepsAndSets,
        dayLabel: String,
        relaxed: Set<PoolChanges.RelaxedFilter>    
    ) -> [Exercise] {
        var result: [Exercise] = []

        var isDisliked: Set<Exercise.ID> = []
        var invalidResistance: Set<Exercise.ID> = []
        var cannotPerform: Set<Exercise.ID> = []
        var invalidEffort: Set<Exercise.ID> = []
        var invalidSets: Set<Exercise.ID> = []
        var exceedsRepCap: Set<Exercise.ID> = []
        var missesRepMin: Set<Exercise.ID> = []
        var tooDifficult: Set<Exercise.ID> = []

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
                if !relaxed.contains(.repCap), Double(repRange.upperBound) * repCapMultiplier < max {
                    exceedsRepCap.insert(ex.id); continue
                }
            }
            if !favorites.contains(ex.id) {
                if !relaxed.contains(.difficulty), !ex.difficultyOK(strengthCeiling) {
                    tooDifficult.insert(ex.id); continue
                }
            }
            
            result.append(ex)
        }

        if !isDisliked.isEmpty        { changes.record(dayRaw: dayLabel, reason: .init(reason: .disliked,    exerciseIDs: isDisliked)) }
        if !invalidResistance.isEmpty { changes.record(dayRaw: dayLabel, reason: .init(reason: .resistance,  exerciseIDs: invalidResistance)) }
        if !cannotPerform.isEmpty     { changes.record(dayRaw: dayLabel, reason: .init(reason: .cannotPerform, exerciseIDs: cannotPerform)) }
        if !invalidEffort.isEmpty     { changes.record(dayRaw: dayLabel, reason: .init(reason: .effort,      exerciseIDs: invalidEffort)) }
        if !invalidSets.isEmpty       { changes.record(dayRaw: dayLabel, reason: .init(reason: .sets,        exerciseIDs: invalidSets)) }
        if !exceedsRepCap.isEmpty     { changes.record(dayRaw: dayLabel, reason: .init(reason: .repCap,      exerciseIDs: exceedsRepCap)) }
        if !missesRepMin.isEmpty      { changes.record(dayRaw: dayLabel, reason: .init(reason: .repMin,      exerciseIDs: missesRepMin)) }
        if !tooDifficult.isEmpty      { changes.record(dayRaw: dayLabel, reason: .init(reason: .tooDifficult, exerciseIDs: tooDifficult)) }

        return result
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
    private func selectRandomExercises(from array: [Exercise], count: Int, existing: [Exercise], rng: inout SeededRNG) -> [Exercise] {
        let actual = min(count, array.count)
        guard actual > 0 else { return [] }

        let favs = array.filter { favorites.contains($0.id) }
        let non  = array.filter { !favorites.contains($0.id) }

        // Prioritize least similar exercises within each group
        var sortedFavs = favs
        var sortedNon = non
        if !existing.isEmpty {
            sortedFavs.sort { minSimilarityToExisting(exercise: $0, existing: existing) < minSimilarityToExisting(exercise: $1, existing: existing) }
            sortedNon.sort { minSimilarityToExisting(exercise: $0, existing: existing) < minSimilarityToExisting(exercise: $1, existing: existing) }
        }

        let takeFav = min(sortedFavs.count, actual)
        var picked = Array(sortedFavs.shuffled(using: &rng).prefix(takeFav))

        if picked.count < actual {
            let need = actual - picked.count
            picked.append(contentsOf: sortedNon.shuffled(using: &rng).prefix(need))
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
    
    // MARK: - Similarity Helper
    /// Returns the minimum similarity percentage to existing exercises (lower = more different = better)
    private func minSimilarityToExisting(exercise: Exercise, existing: [Exercise]) -> Double {
        guard !existing.isEmpty else { return 0.0 }
        return existing.map { exercise.similarityPct(to: $0) }.min() ?? 0.0
    }
}

extension ExerciseSelector {
    private func score(
        _ ex: Exercise,
        target: TargetSpec,
        primaryWeight: Double = 1.0,
        secondaryWeight: Double = 0.50,
        nonTargetPenaltyPerSub: Double = 0.25
    ) -> Double {
        // Sum engagement on the target muscle.
        // If a specific submuscle is provided, sum only that sub.
        // Otherwise (nil), sum ALL submuscles for that muscle (muscle-level scoring).
        func sumEngagement(_ entries: [MuscleEngagement]) -> Double {
            let onMuscle = entries.filter { $0.muscleWorked == target.muscle }
            let subs = onMuscle.flatMap { $0.submusclesWorked ?? [] }
            if let sub = target.submuscle {
                return subs.filter { $0.submuscleWorked == sub }
                           .reduce(0.0) { $0 + $1.engagementPercentage }
            } else {
                return subs.reduce(0.0) { $0 + $1.engagementPercentage }
            }
        }

        let pTarget = sumEngagement(ex.primaryMuscleEngagements)
        let sTarget = sumEngagement(ex.secondaryMuscleEngagements)

        // Only penalize “other subs” if we’re targeting a specific submuscle.
        let penalty: Double = {
            guard let sub = target.submuscle else { return 0.0 }
            let others = (ex.allSubMuscles ?? []).filter { $0 != sub }.count
            return Double(others) * nonTargetPenaltyPerSub
        }()

        let primeBonus = (ex.topPrimaryMuscle == target.muscle) ? 0.10 : 0.0

        return primaryWeight * pTarget + secondaryWeight * sTarget + primeBonus - penalty
    }

    private func selectBestForSubmuscles(
        from pool: [Exercise],
        target: TargetSpec,
        count: Int,
        existing: [Exercise],
        rng: inout SeededRNG
    ) -> [Exercise]? {
        guard count > 0 else { return nil }

        // must at least train the muscle
        let candidates = pool.filter { $0.allMuscles.contains(target.muscle) }
        guard !candidates.isEmpty else { return nil }

        // score & sort
        let scored = candidates
            .map { (ex: $0, s: score($0, target: target)) }
            .sorted { $0.s > $1.s }

        let bestScore = scored.first?.s ?? .leastNonzeroMagnitude
        let epsilon: Double = max(0.05, abs(bestScore) * 0.05)

        // relative band
        let relBand = scored.prefix { $0.s >= bestScore - epsilon }

        // fallback band size if relative band is tiny
        let topK = 4
        var band: [Exercise]
        if relBand.count >= 2 {
            band = relBand.map(\.ex)
        } else {
            band = Array(scored.prefix(topK)).map(\.ex)
        }
        let bandSize = band.count

        // Prioritize least similar exercises within the band
        if !existing.isEmpty {
            band.sort { minSimilarityToExisting(exercise: $0, existing: existing) < minSimilarityToExisting(exercise: $1, existing: existing) }
        }
        band.shuffle(using: &rng)

        var picks: [Exercise] = []
        var currentExisting = existing
        while picks.count < count, !band.isEmpty {
            let picked = band.removeFirst()
            picks.append(picked)
            currentExisting.append(picked)
        }

        // fill from the rest (prioritized by similarity) if needed
        if picks.count < count {
            var rest = Array(scored.dropFirst(bandSize)).map(\.ex)
            if !currentExisting.isEmpty {
                rest.sort { minSimilarityToExisting(exercise: $0, existing: currentExisting) < minSimilarityToExisting(exercise: $1, existing: currentExisting) }
            }
            rest.shuffle(using: &rng)
            while picks.count < count, !rest.isEmpty {
                picks.append(rest.removeFirst())
            }
        }

        return picks.isEmpty ? nil : picks
    }

    private func selectBestForTargets(
        from pool: [Exercise],
        targets: [TargetSpec],
        count: Int,
        existing: [Exercise],
        rng: inout SeededRNG
    ) -> [Exercise]? {
        for (idx, t) in targets.enumerated() {
            // lightly stir RNG per target so we don't always pick same item
            var localRng = rng
            for _ in 0..<idx { _ = localRng.next() }

            print("  🔍 trying target: \(t.muscle) sub: \(t.submuscle?.rawValue ?? "nil")")

            if let picked = selectBestForSubmuscles(from: pool, target: t, count: count, existing: existing, rng: &localRng),
               !picked.isEmpty {
                if let ex = picked.first {
                    print("  ✅ target matched: \(t.muscle) sub: \(t.submuscle?.rawValue ?? "nil") → \(ex.name)")
                }
                return picked
            } else {
                print("  ❌ no match for: \(t.muscle) sub: \(t.submuscle?.rawValue ?? "nil") in current pool")
            }
        }
        return nil
    }
}
