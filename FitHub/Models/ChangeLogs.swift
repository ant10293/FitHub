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

struct MaxRecordInfo: Codable {
    let currentMax: MaxRecord?
    let csvEstimate: PeakMetric?
    let lastUpdated: Date?
    let daysSinceLastUpdate: Int?

    var displayText: Text {
        if let currentMax = currentMax {
            return Text("Current \(currentMax.value.formattedText) (set \(currentMax.date.shortDate))")
        } else if let csvEstimate = csvEstimate {
            return Text("Estimated \(csvEstimate.formattedText)")
        } else {
            return Text("No max recorded")
        }
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
        case prUpdate = "PR Update"
        case deload = "Deload"
        case endedDeload = "Ended Deload"
        case reset = "Reset"
        case stagnation = "Stagnation"
        case none = "No Change"
    }

    var progressionIcon: String {
        switch progressionType {
        case .progressiveOverload: return "arrow.up.circle.fill"
        case .prUpdate:            return "trophy.fill"
        case .deload: return "arrow.down.circle.fill"
        case .endedDeload: return "arrow.right.circle.fill"
        case .reset: return "arrow.clockwise.circle.fill"
        case .stagnation: return "plus.circle.fill"
        case .none: return "minus.circle.fill"
        }
    }

    var progressionColor: Color {
        switch progressionType {
        case .progressiveOverload: return .green
        case .prUpdate:            return .gold
        case .deload: return .orange
        case .endedDeload:         return .teal
        case .reset: return .blue
        case .stagnation: return .yellow
        case .none: return .secondary
        }
    }
}
