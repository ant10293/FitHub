//
//  Distribution.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/19/25.
//

import Foundation

struct RepDistribution: Codable, Hashable {
    var distribution: [EffortType: ClosedRange<Int>]

    /// Get a range for a given effort type (safe fallback)
    func reps(for type: EffortType) -> ClosedRange<Int> { distribution[type] ?? 0...0 }
        
    mutating func modify(for type: EffortType, with value: ClosedRange<Int>) {
        distribution[type] = value
    }
    
    static let types: [EffortType] = EffortType.allCases.filter({ $0.usesReps }) // only types that use reps
    
    func overallRange(filteredBy exercise: ExerciseDistribution,
                      requirePositiveShare: Bool = true) -> ClosedRange<Int> {
        Self.getOverallRange(from: distribution,
                             filteredBy: exercise,
                             requirePositiveShare: requirePositiveShare)
    }

    /// "lo–hi" string for the filtered range.
    func formattedTotalRange(filteredBy exercise: ExerciseDistribution,
                             requirePositiveShare: Bool = true) -> String {
        Format.formatRange(range: overallRange(filteredBy: exercise,
                                               requirePositiveShare: requirePositiveShare))
    }

    /// Static variant.
    static func getOverallRange(from reps: [EffortType: ClosedRange<Int>],
                                filteredBy exercise: ExerciseDistribution,
                                requirePositiveShare: Bool = true) -> ClosedRange<Int> {
        let filtered = reps.filter { (type, _) in
            requirePositiveShare
            ? exercise.percentage(for: type) > 0
            : exercise.distribution.keys.contains(type)
        }
        guard !filtered.isEmpty else { return 0...0 }
        let lows  = filtered.values.map { $0.lowerBound }
        let highs = filtered.values.map { $0.upperBound }
        return (lows.min() ?? 0)...(highs.max() ?? 0)
    }
}

struct SetDistribution: Codable, Hashable {
    var distribution: [EffortType: Int]
    
    func sets(for type: EffortType) -> Int { distribution[type] ?? 0 }
    
    mutating func modify(for type: EffortType, with value: Int) {
        distribution[type] = value
    }
    
    func overallRange(filteredBy exercise: ExerciseDistribution,
                      requirePositiveShare: Bool = true) -> ClosedRange<Int> {
        Self.getOverallRange(from: distribution,
                             filteredBy: exercise,
                             requirePositiveShare: requirePositiveShare)
    }

    /// "lo–hi" string for the filtered set range.
    func formattedTotalRange(filteredBy exercise: ExerciseDistribution,
                             requirePositiveShare: Bool = true) -> String {
        Format.formatRange(range: overallRange(filteredBy: exercise,
                                               requirePositiveShare: requirePositiveShare))
    }

    /// Static variant.
    static func getOverallRange(from sets: [EffortType: Int],
                                filteredBy exercise: ExerciseDistribution,
                                requirePositiveShare: Bool = true) -> ClosedRange<Int> {
        let filtered = sets.filter { (type, _) in
            requirePositiveShare
            ? exercise.percentage(for: type) > 0
            : exercise.distribution.keys.contains(type)
        }
        guard !filtered.isEmpty else { return 0...0 }
        let vals = Array(filtered.values)
        return (vals.min() ?? 0)...(vals.max() ?? 0)
    }
}

struct ExerciseDistribution: Codable, Hashable {
    var distribution: [EffortType: Double]
    
    var total: Double { distribution.values.reduce(0, +) }

    func percentage(for type: EffortType) -> Double { distribution[type] ?? 0 }
    
    func displayPct(for type: EffortType) -> Int {
        Int((percentage(for: type) * 100).rounded())
    }
    
    mutating func modify(for type: EffortType, with value: Double) {
        distribution[type] = value
    }
    
    var normalizeDistribution: [EffortType: Double] {
        let filtered = distribution.filter { $0.value > 0 }
        let sum = filtered.values.reduce(0, +)
        guard sum > 0 else {
            let keys = Array(distribution.keys)
            guard !keys.isEmpty else { return [:] }
            let w = 1.0 / Double(keys.count)
            return Dictionary(uniqueKeysWithValues: keys.map { ($0, w) })
        }
        return filtered.mapValues { $0 / sum }
    }
}

struct RestPeriods: Codable, Hashable {
    var distribution: [RestType: Int]
    
    var overallRange: ClosedRange<Int> { RestPeriods.getOverallRange(from: distribution) }
    
    func rest(for type: RestType) -> Int { distribution[type] ?? 0 }
    
    static func getOverallRange(from sets: [RestType: Int], ignoringZeros: Bool = true) -> ClosedRange<Int> {
        let values = ignoringZeros ? sets.values.filter { $0 > 0 } : Array(sets.values)
        guard let lo = values.min(), let hi = values.max() else { return 0...0 }
        return lo...hi
    }
    
    mutating func modify(for type: RestType, with value: Int) {
        distribution[type] = value
    }
    
    static func determineRestPeriods(customRest: RestPeriods?, goal: FitnessGoal) -> RestPeriods {
        return customRest ?? goal.defaultRest
    }
}

struct WorkoutTimes: Codable, Hashable {
    var distribution: [DaysOfWeek: DateComponents]
    
    func time(for day: DaysOfWeek) -> DateComponents? { distribution[day] }

    mutating func modify(for day: DaysOfWeek, with components: DateComponents) {
        distribution[day] = components
    }
}
