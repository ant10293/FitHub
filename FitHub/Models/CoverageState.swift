//
//  CoverageState.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/28/25.
//
import Foundation

struct TargetSpec {
    let muscle: Muscle
    let submuscle: SubMuscles?
}

struct CoverageState {
    var muscleCoverage: [MuscleCoverage] = []
    
    init(categories: [SplitCategory]) {
        let coverageWeights = buildCoverageWeights(categories: categories)
        for (muscle, weight) in coverageWeights {
            self.muscleCoverage.append(
                .init(
                    muscle: muscle,
                    weight: weight,
                    count: 0,
                    subNeeded: Set(Muscle.getSubMuscles(for: muscle)),
                    subCovered: []
                )
            )
        }
    }
        
    struct MuscleCoverage {
        var muscle: Muscle
        var weight: Double               // e.g., 2.0 for “primary/weighted”, 1.0 for “group/secondary”
        var count: Int                   // how many exercises currently targeting this muscle
        var subNeeded: Set<SubMuscles>   // required submuscles to hit (may be empty)
        var subCovered: Set<SubMuscles>  // submuscles we’ve already hit

        /// True when all required submuscles for this muscle are covered at least once.
        var areSubsCovered: Bool { subNeeded.isSubset(of: subCovered) }
        var missingSubs: Set<SubMuscles> { subNeeded.subtracting(subCovered) }

        /// Fraction of required submuscles covered (0...1). Useful when choosing the next target.
        var coverageRatio: Double {
            guard !subNeeded.isEmpty else { return 1.0 }
            let covered = subNeeded.intersection(subCovered).count
            return Double(covered) / Double(subNeeded.count)
        }
        
        mutating func incrementCount() { count += 1 }
        
        mutating func markCovered(_ subs: [SubMuscles]) {
            for s in subs { subCovered.insert(s) }
        }
    }
    
    // MARK: - Helpers

    /// Returns the weighted muscle whose count equals the **lowest** non-weighted count (if any).
    /// Useful to nudge selection so weighted stays ahead of non-weighted.
    func weightedMatchingLowestNonCount() -> Muscle? {
        guard let minNon = nonWeighted.map(\.count).min() else { return nil }
        return weighted.first(where: { $0.count == minNon })?.muscle
    }

    /// Lowest-count muscle from a list, with tie-breakers:
    /// 1) lower coverageRatio first (hit missing submuscles)
    /// 2) then by muscle name (stable selection)
    private func lowestCountMuscle(in list: [MuscleCoverage]) -> Muscle? {
        guard !list.isEmpty else { return nil }
        let sorted = list.sorted {
            if $0.count != $1.count { return $0.count < $1.count }
            if $0.coverageRatio != $1.coverageRatio { return $0.coverageRatio < $1.coverageRatio }
            return $0.muscle.rawValue < $1.muscle.rawValue
        }
        return sorted.first?.muscle
    }

    /// Prefer a weighted muscle at the lowest count; if none, fall back to lowest from all.
    private func lowestCountPrefWeighted() -> Muscle? {
        if let m = lowestCountMuscle(in: weighted) { return m }
        return lowestCountMuscle(in: muscleCoverage)
    }
}

extension CoverageState {
    // MARK: - Next-target policy
  
    /// Previously returned a list; keep it for internal use.
    func missingSubmuscles(for muscle: Muscle) -> [SubMuscles] {
        guard let idx = muscleCoverage.firstIndex(where: { $0.muscle == muscle }) else { return [] }
        let mc = muscleCoverage[idx]
        return Array(mc.missingSubs).sorted { $0.rawValue < $1.rawValue }
    }

    /// Pick a single submuscle to target:
    /// - Prefer the first missing submuscle (stable).
    /// - If none missing, pick the first from the default priority list.
    private func nextSubmuscle(for muscle: Muscle) -> SubMuscles? {
        let missing = missingSubmuscles(for: muscle)
        if let m = missing.first { return m }
        return Muscle.getSubMuscles(for: muscle).first
    }

    /// Your main chooser:
    /// - if not all muscles hit: return any 0-count, preferring weighted 0-count first
    /// - else:
    ///    1) if any weighted has count == lowest non-weighted count → pick that weighted (keeps weighted ahead)
    ///    2) if totals show weighted < 2× non-weighted → pick lowest-count weighted
    ///    3) otherwise pick the overall lowest (still prefers weighted due to tie-breaker)
    private func getNextTargetMuscle() -> Muscle? {
        if !allMusclesHit {
            // prefer missing weighted first
            if let w0 = weighted.first(where: { $0.count == 0 })?.muscle { return w0 }
            return muscleCoverage.first(where: { $0.count == 0 })?.muscle
        }

        // 1) keep weighted from falling behind non-weighted floor
        if let m = weightedMatchingLowestNonCount() { return m }

        // 2) softly enforce ~2×: if weighted total < 2 * non-weighted total, pick lowest-count weighted
        if totalWeightedCount < 2 * max(totalNonWeightedCount, 1) {
            if let m = lowestCountMuscle(in: weighted) { return m }
        }

        // 3) otherwise just pick the lowest, preferring weighted via helper
        return lowestCountPrefWeighted()
    }
    
    func orderedTargetSpecs() -> [TargetSpec] {
        var result: [TargetSpec] = []

        // 1) the exact muscle your policy picked
        if let primaryMuscle = getNextTargetMuscle() {
           let primarySub = nextSubmuscle(for: primaryMuscle)
           result.append(TargetSpec(muscle: primaryMuscle, submuscle: primarySub))
        }

        // 2) add the rest, in a deterministic order, but skip the one we already added
        let remaining = muscleCoverage
           .filter { mc in
               // skip the one already used
               if let first = result.first { return mc.muscle != first.muscle }
               return true
           }
           .sorted {
               // this is basically your tie-breaking logic
               if $0.count != $1.count { return $0.count < $1.count }
               if $0.coverageRatio != $1.coverageRatio { return $0.coverageRatio < $1.coverageRatio }
               if $0.weight != $1.weight { return $0.weight > $1.weight }
               return $0.muscle.rawValue < $1.muscle.rawValue
           }

        for mc in remaining {
           let missing = Array(mc.missingSubs).sorted { $0.rawValue < $1.rawValue }
           if let sub = missing.first {
               result.append(TargetSpec(muscle: mc.muscle, submuscle: sub))
           } else if let firstDefined = Muscle.getSubMuscles(for: mc.muscle).first {
               result.append(TargetSpec(muscle: mc.muscle, submuscle: firstDefined))
           } else {
               // muscle has no submuscles in model → still include it
               result.append(TargetSpec(muscle: mc.muscle, submuscle: nil))
           }
        }

        return result
    }
}

private extension CoverageState {
    private var weighted: [MuscleCoverage] { muscleCoverage.filter({ $0.weight == 2.0 }) }
    private var nonWeighted: [MuscleCoverage] { muscleCoverage.filter({ $0.weight == 1.0 }) }
    private var allMusclesHit: Bool { muscleCoverage.allSatisfy({ $0.count > 0 }) }
    private var allSubsHit: Bool { muscleCoverage.allSatisfy({ $0.areSubsCovered }) }
    // MARK: - Aggregates
    private var totalWeightedCount: Int { weighted.reduce(0) { $0 + $1.count } }
    private var totalNonWeightedCount: Int { nonWeighted.reduce(0) { $0 + $1.count } }
}

extension CoverageState {
    /// How we choose which ONE muscle gets the +1 `count` for this exercise.
    enum CountMode {
        /// Prefer highest-engagement primary (>= primaryMin); else top overall (>= overallMin).
        case primaryOrTop
        /// Only primaries may increment (>= primaryMin); otherwise no increment.
        case primaryOnly
        /// Top overall engagement muscle (>= overallMin), regardless of mover.
        case topOverall
    }

    /// Apply one exercise's coverage effects:
    /// - Marks submuscles covered if their engagement passes thresholds.
    /// - Increments the `count` for ONE chosen muscle (per countMode).
    mutating func apply(
        exercise: Exercise,
        countMode: CountMode = .primaryOrTop,
        primaryMin: Double = 0.20,          // 20% min to qualify as "primary" for count
        overallMin: Double = 0.10,          // 10% floor to consider any muscle for count
        subMinPrimary: Double = 0.20,       // mark primary submuscles at ≥20%
        subMinSecondary: Double = 0.30      // (often higher to avoid noise)
    ) {
        // 1) Mark submuscles from primary & secondary engagements
        for me in exercise.primaryMuscleEngagements {
            guard let idx = index(of: me.muscleWorked) else { continue }
            let subs = (me.submusclesWorked ?? []).filter { $0.engagementPercentage >= subMinPrimary }
                                                  .map(\.submuscleWorked)
            if !subs.isEmpty {
                print("\(exercise.name) primary subs: \(subs)")
                muscleCoverage[idx].markCovered(subs)
            }
        }
        for me in exercise.secondaryMuscleEngagements {
            guard let idx = index(of: me.muscleWorked) else { continue }
            let subs = (me.submusclesWorked ?? []).filter { $0.engagementPercentage >= subMinSecondary }
                                                  .map(\.submuscleWorked)
            if !subs.isEmpty {
                print("\(exercise.name) secondary subs: \(subs)")
                muscleCoverage[idx].markCovered(subs)
            }
        }

        // 2) Increment count for exactly one muscle
        if let target = pickTargetMuscle(
            for: exercise,
            mode: countMode,
            primaryMin: primaryMin,
            overallMin: overallMin
        ), let idx = index(of: target) {
            muscleCoverage[idx].incrementCount()
        }
    }

    // MARK: - Helpers

    private func index(of muscle: Muscle) -> Int? {
        muscleCoverage.firstIndex { $0.muscle == muscle }
    }

    private func pickTargetMuscle(
        for exercise: Exercise,
        mode: CountMode,
        primaryMin: Double,
        overallMin: Double
    ) -> Muscle? {
        let prim = exercise.primaryMuscleEngagements
        let all  = (exercise.primaryMuscleEngagements + exercise.secondaryMuscleEngagements)

        switch mode {
        case .primaryOrTop:
            if let m = prim.filter({ $0.engagementPercentage >= primaryMin })
                           .max(by: { $0.engagementPercentage < $1.engagementPercentage })?
                           .muscleWorked {
                return m
            }
            return all.filter({ $0.engagementPercentage >= overallMin })
                      .max(by: { $0.engagementPercentage < $1.engagementPercentage })?
                      .muscleWorked
                ?? exercise.topPrimaryMuscle   // very last fallback

        case .primaryOnly:
            return prim.filter({ $0.engagementPercentage >= primaryMin })
                       .max(by: { $0.engagementPercentage < $1.engagementPercentage })?
                       .muscleWorked

        case .topOverall:
            return all.filter({ $0.engagementPercentage >= overallMin })
                      .max(by: { $0.engagementPercentage < $1.engagementPercentage })?
                      .muscleWorked
        }
    }
}

extension CoverageState {
    private func deriveTargetMuscles(from categories: [SplitCategory]) -> (target: [Muscle], group: [Muscle]) {
        var targetMuscles: Set<Muscle> = []
        var groupMuscles: Set<Muscle> = []
        
        for category in categories {
            if let muscles = SplitCategory.muscles[category] { targetMuscles.formUnion(muscles) }
            if let groups = SplitCategory.groups(forGeneration: true)[category] { groupMuscles.formUnion(groups) }
        }
        
        return (Array(targetMuscles), Array(groupMuscles))
    }

    private func deriveTargetSubmuscles(from muscles: [Muscle]) -> [SubMuscles] {
        var targetSubmuscles: Set<SubMuscles> = []
        
        for muscle in muscles {
            if let submuscles = Muscle.subMuscles[muscle] { targetSubmuscles.formUnion(submuscles) }
        }
        
        return Array(targetSubmuscles)
    }
    
    func buildCoverageWeights(
        categories: [SplitCategory],
        primaryWeight: Double = 2.0,
        groupWeight: Double = 1.0
    ) -> [Muscle: Double]{
        // 1) Resolve primary & group muscles using your helpers
        let (primaryMuscles, groupMusclesAll) = deriveTargetMuscles(from: categories) // primary + group
        // (these are defined in your file) :contentReference[oaicite:0]{index=0}

        // 2) Remove any primary muscles from the group set
        var groupMuscles = Set(groupMusclesAll)
        for m in primaryMuscles { groupMuscles.remove(m) }

        // 3) Assign weights
        var weights: [Muscle: Double] = [:]
        weights.reserveCapacity(primaryMuscles.count + groupMuscles.count)

        // Primaries → weight 2.0
        for m in primaryMuscles {
            weights[m] = primaryWeight
        }

        // Groups (post-dedup) → weight 1.0 (don’t downgrade if somehow present)
        for m in groupMuscles {
            if weights[m] == nil {
                weights[m] = groupWeight
            }
        }

        return weights
    }
}
