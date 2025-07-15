//
//  SetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


struct SetDetail: Identifiable, Hashable, Codable {
    var id = UUID()
    var setNumber: Int
    var weight: Double
    var reps: Int
    var repsCompleted: Int?
    var rpe: Double?
    var restPeriod: Int?
    
    mutating func updateCompletedReps(repsCompleted: Int, maxReps: Int) -> (newMaxReps: Int?, updated: Bool) {
        self.repsCompleted = repsCompleted
        
        if repsCompleted > maxReps {
            //print("New Max Reps:", repsCompleted)
            return (newMaxReps: repsCompleted, updated: true)
        } else {
            return (newMaxReps: nil, updated: false)
        }
    }
    
    mutating func updateCompletedRepsAndRecalculate(repsCompleted: Int, oneRepMax: Double) -> (new1RM: Double?, updated: Bool) {
        self.repsCompleted = repsCompleted
        
        if repsCompleted != 0 {
            if let new1RM = recalculate1RM(oneRepMax: oneRepMax) {
                return (new1RM: new1RM, updated: true)
            } else {
                return (new1RM: nil, updated: false) // No change in 1RM.
            }
        } else {
            return (new1RM: nil, updated: false)
        }
    }
    
    // modify for consistency
    private mutating func recalculate1RM(oneRepMax: Double) -> Double? {
        guard let repsCompleted = repsCompleted, repsCompleted > 0 else { return nil }
        var new1rm = OneRMFormula.calculateOneRepMax(weight: weight, reps: repsCompleted, formula: OneRMFormula.recommendedFormula(forReps: repsCompleted))
        if let rpe = rpe, rpe > 0 { new1rm *= SetDetail.rpeMultiplier(for: rpe) }
        
        return new1rm > oneRepMax ? new1rm : nil // Accept only if it really beats the old record
    }
    
    static func calculateSetWeight(oneRepMax: Double, reps: Int) -> Double {
        // Epley‐based percentage: 1RM × (1 + reps × 0.0333)  ⇒  weight = 1RM / (1 + reps × 0.0333)
        let r = Double(reps)
        let percent = 1.0 / (1.0 + 0.0333 * r)
        return oneRepMax * percent
    }
    
    /// Multiplier that *reduces* the estimated 1 RM as RPE drops:
    /// RPE 10 → 100 %   (×1.00)
    /// RPE  9 →  97 %   (×0.97)
    /// RPE  8 →  94 %   (×0.94) … etc
    static func rpeMultiplier(for rpe: Double) -> Double {
        let clamped = min(max(rpe, 1), 10)
        return 1.0 - 0.03 * (10.0 - clamped)
    }

    static func predictive1RM(weight: Double, reps: Int, rpe: Double) -> Double {
        var new1rm = OneRMFormula.calculateOneRepMax(weight: weight, reps: reps, formula: OneRMFormula.recommendedFormula(forReps: reps))
        if rpe > 0 { new1rm *= rpeAdjustment(for: rpe) }
        return new1rm
        
        func rpeAdjustment(for rpe: Double) -> Double {
            // Clamp to the valid range 1...10
            let clamped = max(1.0, min(rpe, 10.0))
            let pctOfMax = 1.0 - 0.03 * (10.0 - clamped)
            return 1.0 / pctOfMax
        }
    }
}


// Helper method to get reps and sets based on the user's goal
struct RepsAndSets {
    var repsRange: ClosedRange<Int>
    var sets: Int
    var restPeriod: Int  // Seconds of rest between sets
    
    static func determineRepsAndSets(customRestPeriod: Int?, goal: FitnessGoal, customRepsRange: ClosedRange<Int>?, customSets: Int?) -> RepsAndSets {
        let restPeriod = customRestPeriod ?? FitnessGoal.determineRestPeriod(for: goal)
        let repsAndSets = customRepsRange != nil && customSets != nil
        ? RepsAndSets(repsRange: customRepsRange!, sets: customSets!, restPeriod: restPeriod)
        : FitnessGoal.getRepsAndSets(for: goal, restPeriod: restPeriod)
        
        return repsAndSets
    }
}
