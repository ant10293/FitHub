//
//  ChangeLog.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/17/25.
//

import Foundation
import SwiftUI

struct WorkoutChangelog: Codable, Identifiable {
    var id: UUID = UUID()
    let generationDate: Date
    let weekStartDate: Date
    let isNextWeek: Bool
    let templates: [TemplateChangelog]
    let generationStats: GenerationStats
}

struct GenerationStats: Codable {
    let totalGenerationTime: TimeInterval
    let exercisesSelected: Int
    let exercisesKept: Int
    let exercisesChanged: Int
    let performanceUpdates: Int
    let progressiveOverloadApplied: Int
    let deloadsApplied: Int
}

struct TemplateChangelog: Codable, Identifiable {
    var id: UUID = UUID()
    let dayName: String
    let dayIndex: Int
    let previousTemplate: WorkoutTemplate?
    let newTemplate: WorkoutTemplate
    let changes: [ExerciseChange]
    let metadata: TemplateMetadata
}

struct TemplateMetadata: Codable {
    let estimatedDuration: TimeSpan?
    let totalSets: Int
    let totalVolume: Mass
    let categories: [SplitCategory]
}

struct ExerciseChange: Codable, Identifiable {
    var id: UUID = UUID()
    let exerciseName: String
    let changeType: ChangeType
    let previousExercise: Exercise?
    let newExercise: Exercise
    let setChanges: [SetChange]
    let progressionDetails: ProgressionDetails?
    let maxRecordInfo: MaxRecordInfo? // NEW: Add this
    
    enum ChangeType: String, Codable, CaseIterable {
        case new = "New Exercise"
        case kept = "Kept Exercise"
        case replaced = "Replaced Exercise"
        case modified = "Modified Exercise"
        
        var color: Color {
            switch self {
            case .new: return .green
            case .kept: return .blue
            case .replaced: return .orange
            case .modified: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .new: return "plus.circle.fill"
            case .kept: return "checkmark.circle.fill"
            case .replaced: return "arrow.triangle.2.circlepath"
            case .modified: return "pencil.circle.fill"
            }
        }
    }
}

// NEW: Add this structure for max record info
struct MaxRecordInfo: Codable {
    let currentMax: MaxRecord?
    let csvEstimate: PeakMetric?
    let lastUpdated: Date?
    let weeksSinceLastUpdate: Int?
    
    var displayText: String {
        if let currentMax = currentMax {
            return "Current \(currentMax.value.loggingEntry) (set \(Format.shortDate(from: currentMax.date)))"
        } else if let csvEstimate = csvEstimate {
            return "Estimated \(csvEstimate.loggingEntry) (from CSV data)"
        } else {
            return "No max recorded"
        }
    }
}

struct SetChange: Codable, Identifiable {
    var id: UUID = UUID()
    let setNumber: Int
    let previousSet: SetDetail?
    let newSet: SetDetail
    let loadChange: LoadChange?
    let metricChange: MetricChange?
    
    struct LoadChange: Codable {
        let previous: SetLoad
        let new: SetLoad
        let percentageChange: Double
        let isIncrease: Bool
    }
    
    struct MetricChange: Codable {
        let previous: SetMetric
        let new: SetMetric
        let isReps: Bool
        let previousValue: Double
        let newValue: Double
        let percentageChange: Double
    }
}

struct ProgressionDetails: Codable {
    let progressionType: ProgressionType
    let previousWeek: Int
    let newWeek: Int
    let stagnationWeeks: Int
    let appliedChange: String
    
    enum ProgressionType: String, Codable {
        case progressiveOverload = "Progressive Overload"
        case deload = "Deload"
        case reset = "Reset"
        case stagnation = "Stagnation"
        case none = "No Change"
    }
    
    var progressionIcon: String {
        switch progressionType {
        case .progressiveOverload: return "arrow.up.circle.fill"
        case .deload: return "arrow.down.circle.fill"
        case .reset: return "arrow.clockwise.circle.fill"
        case .stagnation: return "plus.circle.fill"
        case .none: return "minus.circle.fill"
        }
    }
    
    var progressionColor: Color {
        switch progressionType {
        case .progressiveOverload: return .green
        case .deload: return .orange
        case .reset: return .blue
        case .stagnation: return .yellow
        case .none: return .secondary
        }
    }
}
