//
//  SetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI

struct SetDetail: Identifiable, Hashable, Codable {
    let id: UUID
    let setNumber: Int
    var load: SetLoad
    var planned: SetMetric
    var completed: SetMetric?
    var rpe: Double?
    var restPeriod: Int?
    
    init(id: UUID? = nil, setNumber: Int, load: SetLoad, planned: SetMetric) {
        self.id = id ?? UUID()
        self.setNumber = setNumber
        self.load = load
        self.planned = planned
    }
    
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
        case .hold30sLoad:
            if let hold = metric.holdTime, let weight = load.weight {
                let load30s = WeightedHoldFormula.equivalentHoldLoad(weight: weight, duration: hold)
                return .hold30sLoad(load30s)
            }
        case .none:
            return nil
        }
        
        return nil
    }
    
    mutating func updateCompletedMetrics(currentBest: PeakMetric) -> (newMax: PeakMetric?, lxm: LoadXMetric?) {
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
            guard let candidate = recalculate1RM(best: best1RM, completedWeight: weight, completedReps: reps) else { return (nil, nil) }
            return (.oneRepMax(candidate), LoadXMetric(load: .weight(weight), metric: .reps(reps)))
        
        case .hold30sLoad(let bestLoad):
            guard let held = metric.holdTime, held.inSeconds > 0, let weight = load.weight else { return (nil, nil) }
            guard let candidate = recalculateHoldLoad(best: bestLoad, weight: weight, duration: held) else { return (nil, nil) }
            return (.hold30sLoad(candidate), LoadXMetric(load: .weight(weight), metric: .hold(held)))
            
        case .none:
            return (nil, nil)
        }
    }

    private func recalculate1RM(best: Mass, completedWeight: Mass, completedReps: Int) -> Mass? {
        let base = OneRMFormula.calculateOneRepMax(
            weight: completedWeight,
            reps: completedReps
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
        return adjusted.inKg > best.inKg ? adjusted : nil
    }
    
    /// Multiplier that *reduces* the estimated 1 RM as RPE drops:
    /// RPE 10 → 100 %   (×1.00)
    /// RPE  9 →  97 %   (×0.97)
    /// RPE  8 →  94 %   (×0.94) … etc
    static func rpeMultiplier(for rpe: Double) -> Double {
        let clamped = min(max(rpe, 1), 10)
        return 1.0 - 0.03 * (10.0 - clamped)
    }
    
    /// Convert (weight × time) hold to an equivalent load at reference time.
    func recalculateHoldLoad(best: Mass, weight: Mass, duration: TimeSpan) -> Mass? {
        let new = WeightedHoldFormula.equivalentHoldLoad(
            weight: weight,
            duration: duration
        )
        
        return new.inKg > best.inKg ? new : nil
    }

    static func calculateSetWeight(oneRm: Mass, reps: Int, formula: OneRMFormula = .canonical) -> Mass {
        let p = formula.percent(at: max(1, reps))   // %1RM fraction
        return Mass(kg: oneRm.inKg * p)
    }
    
    mutating func bumpPlanned(by steps: Int, secondsPerStep: Int) {
        switch planned {
        case .reps(let r):
            planned = .reps(max(0, r + steps))
        case .hold(let s):
            let seconds = max(0, s.inSeconds + steps * secondsPerStep)
            planned = .hold(TimeSpan(seconds: seconds))
        case .cardio: break
        }
    }
}

extension SetDetail {
    static func formatLoadMetric(load: SetLoad, metric: SetMetric) -> Text {
        // tiny helpers so the switch body stays readable
        let sepTimes = Text(" × ")
        let sepDash  = Text(" - ")
        func light(_ s: String) -> Text { Text(s).fontWeight(.light) }

        switch (load, metric) {
        case (.weight(let w), .reps(let r)):
            return w.formattedText() + sepTimes + Text("\(r)") + light(" reps")

        case (.none, .reps(let r)):
            return Text("\(r)") + light(" reps")

        case (.weight(let w), .hold(let t)):
            return w.formattedText() + sepTimes + Text(t.displayStringCompact) + light(" hold")

        case (.none, .hold(let t)):
            return Text(t.displayStringCompact) + light(" hold")

        case (.distance(let d), .cardio(let ts)):
            return d.formattedText + sepDash + Text(ts.time.displayString)

        default:
            return Text("—")
        }
    }

    var formattedCompletedText: Text {
        let head = Text("Set \(setNumber): ").bold()
        guard let completed else { return head + Text("—") }
        return head + SetDetail.formatLoadMetric(load: load, metric: completed)
    }

    var formattedPlannedText: Text {
        SetDetail.formatLoadMetric(load: load, metric: planned)
    }
    
    static let secPerRep: Int = 3
    static let secPerSetup: Int = 90
    static let extraSecPerDiff: Int = 10
    static let secPerStep: Int = 5 // conversion for time-based sets
}

