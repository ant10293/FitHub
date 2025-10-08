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
    case cardio(TimeOrSpeed)
    
    func scaling(by factor: Double) -> SetMetric {
        switch self {
        case .reps(let r): return .reps(max(1, Int((Double(r) * factor).rounded(.down))))
        case .hold(let span): return .hold(.fromSeconds(max(1, Int((Double(span.inSeconds) * factor).rounded(.down)))))
        case .cardio: return self
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
    
    var timeSpeed: TimeOrSpeed? {
        if case .cardio(let ts) = self { return ts }
        return nil
    }
    
    var secondsValue: Int? {
        switch self {
        case .cardio(let ts): return ts.time.inSeconds
        case .hold(let t): return t.inSeconds
        case .reps: return nil
        }
    }
    
    var fieldString: String {
        switch self {
        case .reps(let r): return r > 0 ? String(r) : ""
        case .hold(let span): return span.inSeconds > 0 ? span.displayStringCompact : ""
        case .cardio(let ts): return ts.fieldString
        }
    }
    
    var actualValue: Double {
        switch self {
        case .reps(let r): return Double(r)
        case .hold(let t): return Double(t.inSeconds)
        case .cardio(let ts): return ts.actualValue
        }
    }
    
    var label: String {
        switch self {
        case .reps: return "Reps"
        case .hold: return "Time"
        case .cardio(let ts): return ts.label
        }
    }
    
    var iconName: String {
        switch self {
        case .reps: return "number"
        case .hold: return "clock"
        case .cardio: return "clock"
        }
    }
    
    /// Returns (volumeKg, reps) for this metric given raw kg & movement multipliers.
    func volumeContribution(weightKg: Double, repsMul: Int, weightMul: Double) -> (volume: Double, reps: Int) {
        switch self {
        case .reps(let r):
            let reps = r * repsMul
            let kg   = weightKg * weightMul
            return (kg * Double(reps), reps)
        case .hold, .cardio:
            return (0, 0)
        }
    }
}
