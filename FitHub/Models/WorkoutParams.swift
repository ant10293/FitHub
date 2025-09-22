//
//  WorkoutParams.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/19/25.
//

import Foundation

enum WorkoutParams {
    static func determineWorkoutDuration(
        age: Int,
        frequency: Int,
        strengthLevel: StrengthLevel,
        goal: FitnessGoal,
        customDuration: Int?
    ) -> Int {
        return customDuration
        ?? defaultWorkoutDuration(age: age, frequency: frequency, strengthLevel: strengthLevel, goal: goal).inMinutes
    }
    
    /// Heuristic workout duration (minutes) based on user profile.
    /// Returns a value rounded to the nearest 5 and clamped to 25…90.
    static func defaultWorkoutDuration(
        age: Int,
        frequency: Int,
        strengthLevel: StrengthLevel,
        goal: FitnessGoal
    ) -> TimeSpan {
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

        // Clamp and round to nearest 15
        minutes = min(max(minutes, 25), 90)
        let remainder = minutes % 15
        if remainder >= 8 {
            minutes += (15 - remainder)   // round up
        } else {
            minutes -= remainder          // round down
        }
        
        return TimeSpan.fromMinutes(minutes)
    }
}
