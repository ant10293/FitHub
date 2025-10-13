//
//  Performance.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import Foundation
import SwiftUI

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
            return .none
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
    //var repsXweight: RepsXWeight?
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
                //existingUpdate.repsXweight = update.repsXweight
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
    //var repsXweight: RepsXWeight?
    var loadXmetric: LoadXMetric?
    var setId: UUID?
}
/*
struct RepsXWeight: Codable, Hashable {
    var reps: Int
    var weight: Mass
    
    var formattedText: Text {
        weight.formattedText()
        + Text(" x \(reps) ")
        + Text("reps").fontWeight(.light)
    }
}
*/
struct LoadXMetric: Codable, Hashable {
    let load: SetLoad
    let metric: SetMetric
    
    var formattedText: Text {
        SetDetail.formatLoadMetric(load: load, metric: metric)
    }
}

/*
struct TimedHold: Codable, Equatable {
    var weight: Mass?
    var time: TimeSpan
}

struct LoadedCarry: Codable, Equatable {
    var weight: Mass
    var distance: Distance
}

struct EndurancePR: Codable, Equatable {
    var distance: Distance
    var time: TimeSpan
    var speed: Speed?
    var incline: Incline?
}
*/

enum PeakMetric: Codable, Equatable, Hashable {
    case oneRepMax(Mass)     // e.g. 140 kg
    case maxReps(Int)      // e.g. 32 reps
    case maxHold(TimeSpan) // e.g 90 sec or 60 kg for 30 sec
    case none
    //case maxCarry(LoadedCarry) // e.g. 90 kg for 20 meters
    //case endurance(EndurancePR) // e.g. 800m in 0:02:03 (or 2 min 3 sec)
    
    var actualValue: Double {
        switch self {
        case .oneRepMax(let mass): return mass.inKg
        case .maxReps(let reps): return Double(reps)
        case .maxHold(let time): return Double(time.inSeconds)
        case .none: return 0
        }
    }
    
    var displayValue: Double {
        switch self {
        case .oneRepMax(let mass): return mass.displayValue
        case .maxReps: return self.actualValue
        case .maxHold: return self.actualValue
        case .none: return self.actualValue
        }
    }
    
    var displayValueString: String {
        switch self {
        case .maxHold(let span):
            return span.displayStringCompact
        case .oneRepMax, .maxReps:
            return displayValue > 0 ? Format.smartFormat(displayValue) : ""
        case .none: return ""
        }
    }
    
    private var fieldLabel: String? {
        switch self {
        case .oneRepMax, .maxReps: return unitLabel
        case .maxHold: return nil
        case .none: return nil
        }
    }
    
    var labeledText: Text {
        let base = Text(displayValueString)
        guard let label = fieldLabel, !label.isEmpty else { return base }
        return base + Text(" ") + Text(label).fontWeight(.light)
    }
    
    var loggingEntry: String {
        let base = "\(performanceTitle): \(displayValueString)"
        guard let label = fieldLabel, !label.isEmpty else { return base }
        return base + " " + label
    }
    
    var formattedText: Text {
        return Text("\(performanceTitle): ").bold() + labeledText
    }
    
    var performanceTitle: String {
        switch self {
        case .oneRepMax: return "One Rep Max"
        case .maxReps: return "Max Reps"
        case .maxHold: return "Max Hold"
        case .none: return ""
        }
    }
    
    var unitLabel: String {
        switch self {
        case .oneRepMax: return UnitSystem.current.weightUnit
        case .maxReps: return "reps"
        case .maxHold: return "time"
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
        case .none:
            return ""
        }
        return base + suffix
    }
}




