//
//  Performance.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import Foundation
import SwiftUI

// the saved max value is the max reps or the calculated one rep max (in most cases, because you still can enter a one rep max value)
struct MaxRecord: Codable, Identifiable {
    var id: UUID = UUID() // Unique identifier for each record (for graphing)
    var value: PeakMetric
    var repsXweight: RepsXWeight?
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
            // Overwrite existing record if necessary
            if updatedMax[index].value.actualValue < update.value.actualValue {
                updatedMax[index].value = update.value
                updatedMax[index].repsXweight = update.repsXweight
                updatedMax[index].setId = update.setId
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
    var repsXweight: RepsXWeight?
    var setId: UUID?
}

struct RepsXWeight: Codable, Hashable {
    var reps: Int
    var weight: Mass
    
    var formattedText: Text {
        weight.formattedText()
        + Text(" x \(reps) ")
        + Text("reps").fontWeight(.light)
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
    //case maxCarry(LoadedCarry) // e.g. 90 kg for 20 meters
    //case endurance(EndurancePR) // e.g. 800m in 0:02:03 (or 2 min 3 sec)
    
    var actualValue: Double {
        switch self {
        case .oneRepMax(let mass): return mass.inKg
        case .maxReps(let reps): return Double(reps)
        case .maxHold(let time): return Double(time.inSeconds)
        }
    }
    
    var displayValue: Double {
        switch self {
        case .oneRepMax(let mass): return mass.displayValue
        case .maxReps: return self.actualValue
        case .maxHold: return self.actualValue
        }
    }
    
    var displayValueString: String {
        switch self {
        case .maxHold(let span):
            return span.displayStringCompact
        case .oneRepMax, .maxReps:
            return displayValue > 0 ? Format.smartFormat(displayValue) : ""
        }
    }

    var unitLabel: String? {
        switch self {
        case .oneRepMax: return UnitSystem.current.weightUnit
        case .maxReps: return "reps"
        case .maxHold: return nil
        }
    }
    
    var formattedText: Text {
        return Text("\(performanceTitle): ").bold() + labeledText
    }
    
    var labeledText: Text {
        let base = Text(displayValueString)
        guard let label = unitLabel, !label.isEmpty else { return base }
        return base + Text(" ") + Text(label).fontWeight(.light)
    }
    
    var loggingEntry: String {
        switch self {
        case .oneRepMax: return "\(performanceTitle): \(displayValueString) kg"
        case .maxReps: return "\(performanceTitle): \(displayValueString) reps"
        case .maxHold: return "\(performanceTitle): \(displayValueString)"
        }
    }
    
    private var performanceTitle: String {
        switch self {
        case .oneRepMax: return "One Rep Max"
        case .maxReps: return "Max Reps"
        case .maxHold: return "Time"
        }
    }
    
    var percentileHeader: String {
        let base = "Use this table to determine your working "
        let suffix: String
        switch self {
        case .oneRepMax(_):
            suffix = "weight for each rep range."
        case .maxReps(_):
            suffix = "reps based on exertion percentage."
        case .maxHold(_):
            suffix = "hold time based on exertion percentage."
        }
        return base + suffix
    }
}

