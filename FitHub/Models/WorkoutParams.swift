//
//  WorkoutParams.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/19/25.
//

import Foundation

enum WorkoutParams {
    static func determineOverloadFactor(
        age: Int,
        frequency: Int,                 // sessions per week (this exercise or body part)
        strengthLevel: StrengthLevel,   // e.g., .novice/.intermediate/.advanced/.elite
        goal: FitnessGoal,              // your app’s goal enum
        customFactor: Double?
    ) -> Double {
        return customFactor
        ?? getOverloadFactor(age: age, frequency: frequency, strengthLevel: strengthLevel, goal: goal)
    }
    /// Scales progressive overload aggressiveness. 1.0 = baseline.
    /// Apply this to your step size (reps/time/weight) before rounding.
    static func getOverloadFactor(
        age: Int,
        frequency: Int,                 // sessions per week (this exercise or body part)
        strengthLevel: StrengthLevel,   // e.g., .novice/.intermediate/.advanced/.elite
        goal: FitnessGoal               // your app’s goal enum
    ) -> Double {
        // --- Age multiplier (recovery tends to slow modestly with age)
        // <30: 1.00, 30–39: 0.97, 40–49: 0.93, 50–59: 0.88, 60+: 0.82
        let ageMul: Double = {
            switch age {
            case ..<30: return 1.00
            case 30...39: return 0.97
            case 40...49: return 0.93
            case 50...59: return 0.88
            default: return 0.82
            }
        }()

        // --- Frequency multiplier (more weekly exposure → smaller per-session jumps)
        // 1x: 1.05, 2x: 1.00, 3x: 0.95, 4x: 0.90, 5x+: 0.85
        
        let freqMul: Double = {
            switch frequency {
            case 1, 2:  return 1.00
            case 3:     return 0.95
            case 4:     return 0.90
            case 5, 6:  return 0.85
            default:    return 0.80
            }
        }()

        // --- Strength level multiplier (stronger lifters progress slower)
        // novice 1.10, intermediate 1.00, advanced 0.92, elite 0.85
        let levelMul: Double = {
            switch strengthLevel {
            case .beginner:      return 1.15
            case .novice:        return 1.10
            case .intermediate:  return 1.00
            case .advanced:      return 0.92
            case .elite:         return 0.85
            }
        }()

        // --- Goal multiplier (how aggressive should overload be for this goal?)
        // tune to your model of effort types
        let goalMul: Double = {
            switch goal {
            case .getStronger:                return 1.05
            case .buildMuscle:                return 1.00
            case .buildMuscleGetStronger:     return 1.02
            case .athleticPerformance:        return 0.98
            case .generalFitness:             return 0.95
            case .loseWeight:                 return 0.92
            case .improveEndurance:           return 0.90
            }
        }()

        // Combine and clamp
        let raw = 1.0 * ageMul * freqMul * levelMul * goalMul
        return min(max(raw, 0.60), 1.40)
    }

    static func determineWorkoutDuration(
        age: Int,
        frequency: Int,
        strengthLevel: StrengthLevel,
        goal: FitnessGoal,
        customDuration: Int?
    ) -> Int {
        return customDuration
        ?? defaultWorkoutDuration(age: age, frequency: frequency, strengthLevel: strengthLevel, goal: goal)
    }
    
    /// Heuristic workout duration (minutes) based on user profile.
    /// Returns a value rounded to the nearest 5 and clamped to 25…90.
    static func defaultWorkoutDuration(
        age: Int,
        frequency: Int,
        strengthLevel: StrengthLevel,
        goal: FitnessGoal
    ) -> Int {
        var minutes = 45 // base

        // Age
        switch age {
        case ..<30: minutes += 5
        case 30..<40: break
        case 40..<50: minutes -= 5
        case 50..<60: minutes -= 10
        default: minutes -= 15
        }

        // Training frequency (days/week)
        switch frequency {
        case ..<3: minutes += 10   // fewer days → longer sessions
        case 3...4: break
        case 5: minutes -= 5
        default: minutes -= 10   // 6–7 days → shorter sessions
        }
        
        switch max(1, min(frequency, 7)) {
        case 1: minutes += 30
        case 2: minutes += 20
        case 3: minutes += 10
        case 4: break
        case 5: minutes -= 5
        case 6: minutes -= 10
        case 7: minutes -= 20
        default: break
        }

        // Strength level
        minutes += {
            switch strengthLevel {
            case .beginner: return -10
            case .novice: return -5
            case .intermediate: return 0
            case .advanced: return 10
            case .elite: return 15
            }
        }()

        minutes += {
            switch goal {
            case .buildMuscle:               return 0
            case .getStronger:               return 10
            case .buildMuscleGetStronger:    return 5
            case .loseWeight:                return -5    // shorter rests / circuits
            case .improveEndurance:          return 0     // short rests, but more steady work
            case .generalFitness:            return 0
            case .athleticPerformance:       return 5     // mixed work, some longer rest blocks
            }
        }()

        // Clamp and round to nearest 5
        minutes = min(max(minutes, 25), 90)
        let remainder = minutes % 5
        if remainder >= 3 { minutes += (5 - remainder) } else { minutes -= remainder }
        return minutes
    }
}
