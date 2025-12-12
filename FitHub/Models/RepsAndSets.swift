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
    var distribution: EffortDistribution
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
        customDistribution: EffortDistribution?
    ) -> RepsAndSets {
        let rest = customRestPeriod ?? goal.defaultRest
        let sets = customSets ?? goal.defaultSets
        let reps = customRepsRange ?? goal.defaultReps

        let rawDist = customDistribution ?? goal.defaultDistribution
        let dist = EffortDistribution(distribution: rawDist.normalizeDistribution)

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
