//
//  SetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI

enum SetMetric: Codable, Equatable, Hashable {
    case reps(Int)
    case hold(TimeSpan)   // isometric: time under tension
    
    func adding(_ delta: Int) -> SetMetric {
        switch self {
        case .reps(let r): return .reps(max(1, r + delta))
        case .hold(let span): return .hold(.fromSeconds(max(1, span.inSeconds + delta)))
        }
    }
    
    func scaling(by factor: Double) -> SetMetric {
        switch self {
        case .reps(let r): return .reps(max(1, Int((Double(r) * factor).rounded(.down))))
        case .hold(let span): return .hold(.fromSeconds(max(1, Int((Double(span.inSeconds) * factor).rounded(.down)))))
        }
    }
    
    var repsValue: Int? {
        if case .reps(let n) = self { return n }
        return nil
    }
    
    var holdTime: TimeSpan? {
        if case .hold(let t) = self { return t }
        return nil
    }
    
    var fieldString: String {
        switch self {
        case .reps(let r): return r > 0 ? String(r) : ""
        case .hold(let span): return span.displayStringCompact
        }
    }
    
    var actualValue: Double {
        switch self {
        case .reps(let r): return Double(r)
        case .hold(let t): return Double(t.inSeconds)
        }
    }
    
    var label: String {
        switch self {
        case .reps: return "Reps"
        case .hold: return "Hold"
        }
    }
}

struct SetDetail: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let setNumber: Int
    var weight: Mass
    var planned: SetMetric
    var completed: SetMetric?
    var rpe: Double?
    var restPeriod: Int?
    
    mutating func updateCompletedMetrics(currentBest: PeakMetric) -> (newMax: PeakMetric?, rxw: RepsXWeight?) {
        // If nothing was logged, persist the plan as the completion.
        if completed == nil { completed = planned }
        let metric = completed ?? planned

        switch currentBest {
        case .maxReps(let bestReps):
            guard case .reps(let reps) = metric, reps > bestReps else { return (nil, nil) }
            return (.maxReps(reps), nil)

        case .maxHold(let bestTS):
            guard case .hold(let held) = metric, held.inSeconds > bestTS.inSeconds else { return (nil, nil) }
            return (.maxHold(held), nil)

        case .oneRepMax(let best1RM):
            // Need reps to estimate a 1RM from the set weight (+ RPE)
            guard case .reps(let reps) = metric, reps > 0 else { return (nil, nil) }
            guard let candidate = recalculate1RM(oneRm: best1RM), candidate.inKg > best1RM.inKg else { return (nil, nil) }
            return (.oneRepMax(candidate), RepsXWeight(reps: reps, weight: weight))
        }
    }

    private mutating func recalculate1RM(oneRm: Mass) -> Mass? {
        guard case .reps(let repsCompleted)? = completed, repsCompleted > 0 else { return nil }
        
        let base = OneRMFormula.calculateOneRepMax(
            weight: weight,
            reps: repsCompleted,
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
        }
    }
}
extension SetDetail {
    var metricFieldString: String { planned.fieldString }
    var weightFieldString: String { weight.displayValue > 0 ? weight.displayString : "" }

    func formattedCompletedText(usesWeight: Bool) -> Text {
            let head = Text("Set \(setNumber): ").bold()
            guard let completed = completed else { return head + Text("—") }
            
            switch (usesWeight, completed) {
            case (false, .reps(let repsDone)):
                return head + Text("\(repsDone) reps completed")
            case (true, .reps(let repsDone)):
                return head
                    + weight.formattedText()
                    + Text(" × ").foregroundStyle(.gray)
                    + Text("\(repsDone)")
                    + Text(" reps").fontWeight(.light)
            case (false, .hold(let t)):
                return head + Text(t.displayStringCompact) + Text(" hold").fontWeight(.light)
            case (true, .hold(let t)):
                return head
                    + weight.formattedText()
                    + Text(" × ").foregroundStyle(.gray)
                    + Text(t.displayStringCompact)
                    + Text(" hold").fontWeight(.light)
            }
        }
        
    func formattedPlannedText(usesWeight: Bool) -> Text {
        switch (usesWeight, planned) {
        case (false, .reps(let r)):
            return Text("\(r)") + Text(" reps planned").fontWeight(.light)
        case (true, .reps(let r)):
            return weight.formattedText()
                + Text(" × ").foregroundStyle(.gray)
                + Text("\(r)")
                + Text(" reps").fontWeight(.light)
        case (false, .hold(let t)):
            return Text(t.displayStringCompact) + Text(" hold planned").fontWeight(.light)
        case (true, .hold(let t)):
            return weight.formattedText()
                + Text(" × ").foregroundStyle(.gray)
                + Text(t.displayStringCompact)
                + Text(" hold").fontWeight(.light)
        }
    }
    
    static let secPerRep: Int = 3
    static let secPerSetup: Int = 90
    static let extraSecPerDiff: Int = 10
    static let secPerStep: Int = 5 // conversion for time-based sets
}

