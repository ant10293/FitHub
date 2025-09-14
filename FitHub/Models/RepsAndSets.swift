//
//  RepsAndSets.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import Foundation

// Helper method to get reps and sets based on the user's goal
struct RepsAndSets {
    var reps: RepDistribution
    var sets: SetDistribution
    var rest: RestPeriods
    var distribution: ExerciseDistribution
}

extension RepsAndSets {
    static func defaultRepsAndSets(for goal: FitnessGoal) -> RepsAndSets {
        goal.defaultRepsAndSets
    }
    
    static func determineRepsAndSets(
        for goal: FitnessGoal,
        customRestPeriod: RestPeriods?,
        customRepsRange: RepDistribution?,
        customSets: SetDistribution?,
        customDistribution: ExerciseDistribution?
    ) -> RepsAndSets {
        let rest = customRestPeriod ?? goal.defaultRest
        let sets = customSets ?? goal.defaultSets
        let reps = customRepsRange ?? goal.defaultReps
        
        let rawDist = customDistribution ?? goal.defaultDistribution
        let dist = ExerciseDistribution(distribution: rawDist.normalizeDistribution)
        
        return RepsAndSets(reps: reps, sets: sets, rest: rest, distribution: dist)
    }
}

extension RepsAndSets {
    func repRange(for effort: EffortType) -> ClosedRange<Int> { reps.reps(for: effort) }
    func getSets(for effort: EffortType) -> Int { sets.sets(for: effort) }
    func getRest(for type: RestType) -> Int { rest.rest(for: type) }
    
    var setRange: ClosedRange<Int> { sets.overallRange(filteredBy: distribution) }
    var repRange: ClosedRange<Int> { reps.overallRange(filteredBy: distribution) }
    var restRange: ClosedRange<Int> { rest.overallRange }
}

extension RepsAndSets {
    /// Ensures weights sum to 1.0 and ignores non-positive entries.
    private var normalizedDistribution: [EffortType: Double] { distribution.normalizeDistribution }
    
    private var averageRepsPerSet: Double {
        distribution.distribution.reduce(into: 0.0) { running, item in
            let (effort, weight) = item
            let range = repRange(for: effort)
            let mid = Double(range.lowerBound + range.upperBound) / 2.0
            running += mid * weight // weight already 0‒1
        }
    }

    /// Weighted average **sets per exercise** across effort types.
    var averageSetsPerExercise: Double {
        let dist = normalizedDistribution
        guard !dist.isEmpty else {
            // Fallback: average of provided set counts
            let vals = sets.distribution.values
            return vals.isEmpty ? 3.0 : Double(vals.reduce(0, +)) / Double(vals.count)
        }
        return dist.reduce(0.0) { acc, kv in
            let (effort, w) = kv
            let s = sets.distribution[effort] ?? 0
            return acc + (Double(s) * w)
        }
    }

    /// Use normalized weights for the rep average too (safer).
    var averageRepsPerSetWeighted: Double {
        let dist = normalizedDistribution
        guard !dist.isEmpty else { return averageRepsPerSet } // your original
        return dist.reduce(0.0) { running, kv in
            let (effort, w) = kv
            let r = repRange(for: effort)
            let mid = Double(r.lowerBound + r.upperBound) / 2.0
            return running + (mid * w)
        }
    }
}
