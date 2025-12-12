//
//  Sorting.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


enum CompletedExerciseSortOption: String, CaseIterable, Identifiable {
    case mostRecent = "Most Recent"
    case leastRecent = "Least Recent"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case mostSets = "Most Sets"
    case leastSets = "Least Sets"

    var id: String { self.rawValue }
}

enum CompletedWorkoutSortOption: String, CaseIterable, Identifiable {
    case mostRecent = "Most Recent"
    case leastRecent = "Least Recent"
    case thisMonth = "This Month"
    case longestDuration = "Longest Duration"
    case shortestDuration = "Shortest Duration"

    var id: String { self.rawValue }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case month = "month"
    case sixMonths = "6 months"
    case year = "year"
    case allTime = "all time"

    var id: String { rawValue }
}

enum GraphView: String, Identifiable, Codable, CaseIterable, Equatable {
    case exercisePerformance = "Exercise Performance"
    case bodyMeasurements = "Body Measurements"

    var id: String { self.rawValue }
}

enum RestTimerSetType: String, CaseIterable, Identifiable {
    case warmUp = "Warm-up Sets"
    case working = "Working Sets"

    var id: String { rawValue }
}
