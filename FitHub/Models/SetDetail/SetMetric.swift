//
//  SetMetric.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//

import Foundation
import SwiftUI

enum SetMetric: Codable, Equatable, Hashable {
    case reps(Int)
    case hold(TimeSpan)   // isometric: time under tension
    case carry(Meters)  // carry: distance covered
    case cardio(TimeOrSpeed)

    var fieldString: String {
        switch self {
        case .reps(let r): return r > 0 ? String(r) : ""
        case .hold(let span): return span.fieldString
        case .carry(let m): return m.fieldString
        case .cardio(let tos): return tos.fieldString
        }
    }

    var actualValue: Double {
        switch self {
        case .reps(let r): return Double(r)
        case .hold(let t): return Double(t.inSeconds)
        case .carry(let m): return m.inM
        case .cardio(let ts): return ts.actualValue
        }
    }

    var label: String {
        switch self {
        case .reps: return "Reps"
        case .hold: return "Time"
        case .carry: return "Meters"
        case .cardio(let ts): return ts.label
        }
    }

    var zeroValue: Self {
        switch self {
        case .reps: return .reps(0)
        case .hold: return .hold(.init())
        case .carry: return .carry(.init())
        case .cardio: return .cardio(.init())
        }
    }

    var unit: UnitCategory {
        switch self {
        case .reps: return .reps
        case .hold: return .time
        case .carry: return .carryDistance
        case .cardio(let tos): return tos.unit
        }
    }

    var displayString: String {
        switch self {
        case .reps(let r): return String(r)
        case .hold(let t): return t.displayStringCompact
        case .carry(let m): return m.displayString
        case .cardio(let tos): return tos.displayString
        }
    }

   var formattedText: Text {
       switch self {
       case .reps: return Text(displayString)
       case .hold(let t): return Text(t.displayStringCompact)
       case .carry(let m): return m.formattedText
       case .cardio(let tos): return tos.formattedText
       }
   }
}

extension SetMetric {
    var repsValue: Int? {
        if case .reps(let n) = self { return n }
        return nil
    }

    var holdTime: TimeSpan? {
        if case .hold(let t) = self { return t }
        return nil
    }

    var timeSpeed: TimeOrSpeed? {
        if case .cardio(let tos) = self { return tos }
        return nil
    }

    var metersValue: Meters? {
        if case .carry(let m) = self { return m }
        return nil
    }

    var secondsValue: Int? {
        switch self {
        case .cardio(let ts): return ts.time.inSeconds
        case .hold(let t): return t.inSeconds
        case .reps, .carry: return nil
        }
    }
}

extension SetMetric {
    /// Returns (volumeKg, reps) for this metric given raw kg & movement multipliers.
    func volumeContribution(weightKg: Double, repsMul: Int, weightMul: Double) -> (volume: Double, reps: Int) {
        switch self {
        case .reps(let r):
            let reps = r * repsMul
            let kg   = weightKg * weightMul
            return (kg * Double(reps), reps)

        case .hold:
            return (weightKg, 0)

        case .carry:
            return (weightKg, 0)

        case .cardio:
            return (0, 0)
        }
    }

    // for progression
    func scaling(by factor: Double) -> SetMetric {
        switch self {
        case .reps(let r): return .reps(max(1, Int((Double(r) * factor).rounded(.down))))
        case .hold(let span): return .hold(TimeSpan(seconds: (max(1, Int((Double(span.inSeconds) * factor).rounded(.down))))))
        case .carry(let m): return .carry(Meters(meters: max(1.0, m.inM * factor)))
        case .cardio: return self
        }
    }
}

extension SetMetric {
    var iconName: String {
        switch self {
        case .reps: return "number"
        case .hold, .cardio: return "clock"
        case .carry: return "figure.walk"
        }
    }
}
