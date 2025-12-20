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
        case .carry50mLoad:
            if let meters = metric.metersValue, let weight = load.weight {
                let load50m = WeightedCarryFormula.equivalentCarryLoad(weight: weight, distance: meters)
                return .carry50mLoad(load50m)
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
            guard let reps = metric.repsValue, reps > 0, let weight = load.weight else { return (nil, nil) }
            guard let candidate = recalculate1RM(best: best1RM, completedWeight: weight, completedReps: reps) else { return (nil, nil) }
            return (.oneRepMax(candidate), LoadXMetric(load: load, metric: .reps(reps)))
            
        case .hold30sLoad(let bestLoad):
            guard let held = metric.holdTime, held.inSeconds > 0, let weight = load.weight else { return (nil, nil) }
            guard let candidate = recalculateHoldLoad(best: bestLoad, weight: weight, duration: held) else { return (nil, nil) }
            return (.hold30sLoad(candidate), LoadXMetric(load: load, metric: .hold(held)))

        case .carry50mLoad(let bestLoad):
            guard let meters = metric.metersValue, meters.inM > 0, let weight = load.weight else { return (nil, nil) }
            guard let candidate = recalculateCarryLoad(best: bestLoad, weight: weight, distance: meters) else { return (nil, nil) }
            return (.carry50mLoad(candidate), LoadXMetric(load: load, metric: .carry(meters)))

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

    /// Convert (weight × distance) carry to an equivalent load at reference distance.
    func recalculateCarryLoad(best: Mass, weight: Mass, distance: Meters) -> Mass? {
        let new = WeightedCarryFormula.equivalentCarryLoad(
            weight: weight,
            distance: distance
        )

        return new.inKg > best.inKg ? new : nil
    }

    static func calculateSetWeight(oneRm: Mass, reps: Int, formula: OneRMFormula = .canonical) -> Mass {
        let p = formula.percent(at: max(1, reps))   // %1RM fraction
        return Mass(kg: oneRm.inKg * p)
    }

    mutating func bumpPlanned(by steps: Int) {
        switch planned {
        case .reps(let r):
            planned = .reps(max(0, r + steps))
        case .hold(let s):
            let seconds = max(0, s.inSeconds + steps * SetDetail.secPerStep)
            planned = .hold(TimeSpan(seconds: seconds))
        case .carry(let m):
            // For distance, we'll use a simple increment (e.g., 5m per step)
            let incrementM = Double(steps * SetDetail.metersPerStep)
            planned = .carry(Meters(meters: max(0, m.inM + incrementM)))
        case .cardio:
            break
        }
    }
}

extension SetDetail {
    static func formatLoadMetric(load: SetLoad, metric: SetMetric, simple: Bool = false) -> Text {
        // separators
        let sepTimes = Text(" × ")
        let sepAt    = Text(" @ ")
        func light(_ s: String) -> Text { Text(s).fontWeight(.light) }

        // adapters to avoid duplication
        func W(_ w: Mass)   -> Text { simple ? Text(w.displayString) : w.formattedText() }
        func D(_ d: Distance) -> Text { simple ? Text(d.displayString) : d.formattedText }
        func T(_ t: TimeSpan) -> Text { Text(t.displayStringCompact) }

        switch (load, metric) {
        case (.weight(let w), .reps(let r)):
            return W(w) + sepTimes + Text("\(r)") + (simple ? Text("") : light(" reps"))
            
        case(.band(let b), .reps(let r)):
            return Text(b.level.displayName) + sepTimes + Text("\(r)") + (simple ? Text("") : light(" reps"))
            
        case (.none, .reps(let r)):
            return Text("\(r)") + (simple ? Text("") : light(" reps"))

        case (.weight(let w), .hold(let t)):
            return W(w) + sepTimes + T(t) + (simple ? Text("") : light(" hold"))

        case (.none, .hold(let t)):
            return T(t) + (simple ? Text("") : light(" hold"))

        case (.weight(let w), .carry(let d)):
            return W(w) + sepTimes + Text(d.displayString) + Text(" m") + (simple ? Text("") : light(" carry"))

        case (.distance(let d), .cardio(let ts)):
            return D(d) + sepAt + ts.speed.formattedText

        default:
            return Text("—")
        }
    }

    var formattedCompletedText: Text {
        SetDetail.formatLoadMetric(load: load, metric: completed ?? planned.zeroValue)
    }

    var formattedPlannedText: Text {
        SetDetail.formatLoadMetric(load: load, metric: planned)
    }

    static let secPerMeter: Double = 1.5

    static func secPerRep(for reps: Int, isWarm: Bool) -> Int {
        guard reps > 0 else { return 2 }

        // Base: slower for low reps, faster for high reps
        // 1–5 reps: ~3s each
        // 6–12 reps: ~2s each
        // 13–20 reps: ~1.5s each
        // 21+ reps: ~1s each
        let base: Double
        switch reps {
        case 1...5:   base = 3.0
        case 6...12:  base = 2.0
        case 13...20: base = 1.5
        default:      base = 1.0
        }

        // Warm-ups move a bit faster (about 25% faster)
        let adjusted = isWarm ? base * 0.75 : base
        return Int(round(adjusted))
    }

    static let secPerSetup: Int = 90
    static let extraSecPerDiff: Int = 10
    static let secPerStep: Int = 5 // conversion for time-based sets
    static let metersPerStep: Int = 5
}

enum TopSetOption: String, Codable, Equatable, CaseIterable {
    case firstSet, lastSet, allSets

    var displayName: String {
        switch self {
        case .firstSet: return "First Set"
        case .lastSet: return "Last Set"
        case .allSets: return "All Sets"
        }
    }

    var footerText: String {
        switch self {
        case .firstSet:
            return "The first set will use maximum intensity, with subsequent sets decreasing in intensity."
        case .lastSet:
            return "The last set will use maximum intensity, with earlier sets building up to it."
        case .allSets:
            return "All sets will use the \"Fixed Intensity\" value above. This is typically only used for advanced training protocols."
        }
    }
}
