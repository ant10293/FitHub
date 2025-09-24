//
//  SetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI

struct SetDetail: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let setNumber: Int
    var load: SetLoad
    var planned: SetMetric
    var completed: SetMetric?
    var rpe: Double?
    var restPeriod: Int?
    
    func completedPeakMetric(peak: PeakMetric) -> PeakMetric? {
        let metric = completed ?? planned
        
        switch peak {
        case .maxReps: if let reps = metric.repsValue { return .maxReps(reps) }
        case .maxHold: if let held = metric.holdTime { return .maxHold(held) }
        case .oneRepMax:
            if let reps = metric.repsValue, let weight = load.weight {
                let oneRM = OneRMFormula.calculateOneRepMax(weight: weight, reps: reps, formula: .brzycki)
                return .oneRepMax(oneRM)
            }
        }
        
        return nil
    }
    
    mutating func updateCompletedMetrics(currentBest: PeakMetric) -> (newMax: PeakMetric?, rxw: RepsXWeight?) {
        // If nothing was logged, persist the planned as the completion.
        if completed == nil { completed = planned } // MARK: Essential for updating peakMetric
        let metric = completed ?? planned

        switch currentBest {
        case .maxReps(let bestReps):
            guard let reps = metric.repsValue, reps > bestReps else { return (nil, nil) }
            return (.maxReps(reps), nil)

        case .maxHold(let bestTS):
            guard let held = metric.holdTime, held.inSeconds > bestTS.inSeconds else { return (nil, nil) }
            return (.maxHold(held), nil)

        case .oneRepMax(let best1RM):
            // Need reps to estimate a 1RM from the set weight (+ RPE)
            guard let reps = metric.repsValue, reps > 0, let weight = load.weight else { return (nil, nil) }
            let rxw: RepsXWeight = .init(reps: reps, weight: weight)
            guard let candidate = recalculate1RM(oneRm: best1RM, completed: rxw), candidate.inKg > best1RM.inKg else { return (nil, nil) }
            return (.oneRepMax(candidate), rxw)
        }
    }

    private mutating func recalculate1RM(oneRm: Mass, completed: RepsXWeight) -> Mass? {
        let base = OneRMFormula.calculateOneRepMax(
            weight: completed.weight,
            reps: completed.reps,
            formula: .brzycki
        )

        // Apply RPE multiplier (if any) by constructing a new Mass
        /*let adjusted: Mass = {
            if let rpe, rpe > 0 {
                let factor = SetDetail.rpeMultiplier(for: rpe)
                return Mass(kg: base.inKg * factor)
            } else {
                return base
            }
        }()*/
        let adjusted = base

        // Only return if it truly beats the current 1RM
        return adjusted.inKg > oneRm.inKg ? adjusted : nil
    }
    
    /*
    static func calculateSetWeight(oneRm: Mass, reps: Int) -> Mass {
        // Epley‐based percentage: 1RM × (1 + reps × 0.0333)  ⇒  weight = 1RM / (1 + reps × 0.0333)
        let r = Double(reps)
        let percent = 1.0 / (1.0 + 0.0333 * r)
        let weight = oneRm.inKg * percent
        return Mass(kg: weight)
    }
    */
    
    static func calculateSetWeight(oneRm: Mass, reps: Int) -> Mass {
        let r = max(1, reps)                           // no 0-rep sets
        let percent = max(0.0, (37.0 - Double(r)) / 36.0)
        let weight = oneRm.inKg * percent
        return Mass(kg: weight)
    }
    
    /// Multiplier that *reduces* the estimated 1 RM as RPE drops:
    /// RPE 10 → 100 %   (×1.00)
    /// RPE  9 →  97 %   (×0.97)
    /// RPE  8 →  94 %   (×0.94) … etc
    static func rpeMultiplier(for rpe: Double) -> Double {
        let clamped = min(max(rpe, 1), 10)
        return 1.0 - 0.03 * (10.0 - clamped)
    }
    
    mutating func resetState() {
        completed = nil
        rpe = nil
    }
    
    mutating func bumpPlanned(by steps: Int, secondsPerStep: Int) {
        switch planned {
        case .reps(let r):
            planned = .reps(max(0, r + steps))
        case .hold(let s):
            let seconds = max(0, s.inSeconds + steps * secondsPerStep)
            planned = .hold(TimeSpan(seconds: seconds))
        //case .cardio: break
        }
    }
}
extension SetDetail {
    var metricFieldString: String { planned.fieldString }
    var weightFieldString: String {
        guard let weight = load.weight, weight.displayValue > 0 else { return "" }
        return weight.displayString
    }
    
    var formattedCompletedText: Text {
        let head = Text("Set \(setNumber): ").bold()
        guard let completed = completed else { return head + Text("—") }

        switch (load, completed) {
        case (.weight(let w), .reps(let r)):
            return head
                + w.formattedText()
                + Text(" × ").foregroundStyle(.gray)
                + Text("\(r)") + Text(" reps").fontWeight(.light)

        case (.none, .reps(let r)):
            return head + Text("\(r) reps completed")

        case (.weight(let w), .hold(let t)):
            return head
                + w.formattedText()
                + Text(" × ").foregroundStyle(.gray)
                + Text(t.displayStringCompact)
                + Text(" hold").fontWeight(.light)

        case (.none, .hold(let t)):
            return head + Text(t.displayStringCompact) + Text(" hold completed").fontWeight(.light)

        case (.distance(let d), .hold(let t)):
            // If you support cardio sets with distance × time
            return head
                + d.formattedText
                + Text(" × ").foregroundStyle(.gray)
                + Text(t.displayStringCompact)
                + Text(" hold").fontWeight(.light)

        default:
            return head + Text("—")
        }
    }
    
    // Planned
    var formattedPlannedText: Text {
        switch (load, planned) {
        case (.weight(let w), .reps(let r)):
            return w.formattedText()
                + Text(" × ").foregroundStyle(.gray)
                + Text("\(r)") + Text(" reps").fontWeight(.light)

        case (.none, .reps(let r)):
            return Text("\(r)") + Text(" reps").fontWeight(.light)

        case (.weight(let w), .hold(let t)):
            return w.formattedText()
                + Text(" × ").foregroundStyle(.gray)
                + Text(t.displayStringCompact)
                + Text(" hold").fontWeight(.light)

        case (.none, .hold(let t)):
            return Text(t.displayStringCompact) + Text(" hold").fontWeight(.light)

        case (.distance(let d), .hold(let t)):
            // distance × time planned
            return d.formattedText
                + Text(" × ").foregroundStyle(.gray)
                + Text(t.displayStringCompact)
                + Text(" hold").fontWeight(.light)

        default:
            return Text("—")
        }
    }
    
    static let secPerRep: Int = 3
    static let secPerSetup: Int = 90
    static let extraSecPerDiff: Int = 10
    static let secPerStep: Int = 5 // conversion for time-based sets
}

