//
//  Performance.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import Foundation
import SwiftUI

enum PeakMetric: Codable, Equatable, Hashable {
    case oneRepMax(Mass)     // e.g. 140 kg
    case maxReps(Int)      // e.g. 32 reps
    case maxHold(TimeSpan) // e.g 90 sec or 60 kg for 30 sec
    case hold30sLoad(Mass)
    case none
    
    var actualValue: Double {
        switch self {
        case .oneRepMax(let mass): return mass.inKg
        case .maxReps(let reps): return Double(reps)
        case .maxHold(let time): return Double(time.inSeconds)
        case .hold30sLoad(let mass): return mass.inKg
        case .none: return 0
        }
    }
    
    var displayValue: Double {
        switch self {
        case .oneRepMax(let mass): return mass.displayValue
        case .maxReps, .maxHold: return self.actualValue // unit doesnt matter
        case .hold30sLoad(let mass): return mass.displayValue
        case .none: return self.actualValue
        }
    }
    
    var displayString: String {
        switch self {
        case .oneRepMax(let mass): return mass.displayString
        case .maxReps(let reps): return String(reps)
        case .maxHold(let time): return time.displayStringCompact
        case .hold30sLoad(let mass): return mass.displayString
        case .none: return ""
        }
    }
    
    var unitLabel: String? {
        switch self {
        case .oneRepMax, .hold30sLoad: return UnitSystem.current.weightUnit
        case .maxReps: return "reps"
        case .maxHold: return "sec"
        case .none: return nil
        }
    }

    var performanceTitle: String {
        switch self {
        case .oneRepMax: return "One Rep Max"
        case .maxReps: return "Max Reps"
        case .maxHold: return "Max Hold"
        case .hold30sLoad: return "30s Max Load"
        case .none: return ""
        }
    }
    
    var percentileHeader: String {
        let base = "Use this table to determine your working "
        let suffix: String
        switch self {
        case .oneRepMax:
            suffix = "weight for each rep range."
        case .maxReps:
            suffix = "reps based on exertion percentage."
        case .maxHold:
            suffix = "hold time based on exertion percentage."
        case .hold30sLoad:
            suffix = "load for a 30-second hold based on exertion percentage."
        case .none:
            return ""
        }
        return base + suffix
    }
}

extension PeakMetric {
    private var displayLabel: String? {
        switch self {
        case .oneRepMax, .hold30sLoad: return unitLabel
        case .maxHold, .maxReps, .none: return nil
        }
    }
    
    var labeledText: Text {
        let base = Text(displayString)
        guard let label = displayLabel, !label.isEmpty else { return base }
        return base + Text(" ") + Text(label).fontWeight(.light)
    }
    
    var formattedText: Text {
        return Text("\(performanceTitle): ").bold() + labeledText
    }
    
    var placeholder: String {
        let base: String = "Enter"
        
        if let placeholderLabel {
            return base + " (\(placeholderLabel))"
        } else {
            return base + " value"
        }
    }
    
    private var placeholderLabel: String? {
        switch self {
        case .maxHold: return "h:m:s"
        default: return unitLabel
        }
    }
}

extension Optional where Wrapped == PeakMetric {
    var valid: PeakMetric? {
        guard let v = self, v.actualValue > 0 else { return nil }
        return v
    }
}

enum ExerciseUnit: String {
    case weightXreps, repsOnly, timeOnly, weightXtime, distanceXtimeOrSpeed
    
    func getPeakMetric(metricValue: Double) -> PeakMetric {
        switch self {
        case .weightXreps:
            return .oneRepMax(Mass(kg: metricValue))
        case .repsOnly:
            return .maxReps(Int(metricValue))
        case .timeOnly:
            return .maxHold(TimeSpan(seconds: Int(metricValue)))
        // FIXME: temporary - must add PeakMetric cases
        case .weightXtime:
            return .hold30sLoad(Mass(kg: metricValue))
        case .distanceXtimeOrSpeed:
            return .none
        }
    }
    
    // MARK: no support for weighted hold and cardio exercises
    var supportsPR: Bool {
        let peak = getPeakMetric(metricValue: 0)
        switch peak {
        case .none: return false
        default: return true
        }
    }
}

// the saved max value is the max reps or the calculated one rep max (in most cases, because you still can enter a one rep max value)
struct MaxRecord: Codable, Identifiable {
    var id: UUID = UUID() // Unique identifier for each record (for graphing)
    var value: PeakMetric
    var loadXmetric: LoadXMetric?
    var date: Date        // Date when the record was set
}

struct ExercisePerformance: Identifiable, Codable {
    let id: UUID // Using the exercise id as the identifier
    var estimatedValue: PeakMetric?     // csv
    var currentMax: MaxRecord?     // curent
    var pastMaxes: [MaxRecord]?     // past
    
    init(exerciseId: UUID) {
        self.id = exerciseId
    }
}

struct PerformanceUpdates: Codable, Hashable {
    var updatedMax: [PerformanceUpdate] = []
    
    var prExerciseIDs: [UUID] { updatedMax.map(\.exerciseId) }

    mutating func updatePerformance(_ update: PerformanceUpdate) {
        if let index = updatedMax.firstIndex(where: { $0.exerciseId == update.exerciseId }) {
            var existingUpdate = updatedMax[index]
            // Overwrite existing record if necessary
            if existingUpdate.value.actualValue < update.value.actualValue {
                existingUpdate.value = update.value
                existingUpdate.loadXmetric = update.loadXmetric
                existingUpdate.setId = update.setId
                updatedMax[index] = existingUpdate
            }
        } else {
            // Add new record
            updatedMax.append(update)
        }
    }
}

struct PerformanceUpdate: Codable, Hashable {
    var exerciseId: UUID
    var value: PeakMetric
    var loadXmetric: LoadXMetric?
    var setId: UUID?
}

struct LoadXMetric: Codable, Hashable {
    let load: SetLoad
    let metric: SetMetric
    
    func formattedText(simple: Bool = false) -> Text {
        SetDetail.formatLoadMetric(load: load, metric: metric, simple: simple)
    }
}
