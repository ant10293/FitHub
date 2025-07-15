//
//  Core.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


struct Notification: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var body: String
    var triggerDate: Date
    var workoutName: String
}

struct RepsXWeight: Codable, Hashable {
    var reps: Int
    var weight: Double
}

/*
struct PerformanceUpdate: Codable, Hashable {
    var exerciseName: String
    var value: Double
    var repsXweight: RepsXWeight?
    var setNumber: Int?
}
*/

struct PerformanceUpdate: Codable, Hashable {
    var exerciseId: UUID
    var exerciseName: String
    var value: Double
    var repsXweight: RepsXWeight?
    var setNumber: Int?
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case select = "Select"
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly active"
    case moderatelyActive = "Moderately active"
    case veryActive = "Very active"
    case superActive = "Super active"
    
    var id: String { self.rawValue }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .superActive: return 1.9
        case .select: return 1.0 // Default value for 'select', though it might not be used
        }
    }
    
    var estimatedSteps: Int {
        switch self {
        case .sedentary: return 3000
        case .lightlyActive: return 5000
        case .moderatelyActive: return 7500
        case .veryActive: return 10000
        case .superActive: return 12500
        case .select: return 0
        }
    }
    
    var description: String {
        switch self {
        case .sedentary:
            return "Spend most of the day sitting (i.e. desk job)"
        case .lightlyActive:
            return "Spend a good part of the day on my feet (e.g. teacher or cashier)"
        case .moderatelyActive:
            return "Spend a good part of the day doing moderate physical activity (e.g. server/food runner or parcel driver)"
        case .veryActive:
            return "Spend a good part of the day doing heavy physical activities (e.g. construction worker or mover)"
        case .superActive:
            return "Spend most of the day doing intense physical activity (e.g. professional athlete or training for a marathon)"
        case .select:
            return ""
        }
    }
}

enum StrengthLevel: String, CaseIterable, Codable {
    case beginner = "Beg."
    case novice = "Nov."
    case intermediate = "Int."
    case advanced = "Adv."
    case elite = "Elite"
    
    var strengthValue: Int {
        switch self {
        case .beginner: return 1
        case .novice: return 2
        case .intermediate: return 3
        case .advanced: return 4
        case .elite: return 5
        }
    }
    
    var percentile: Double {
        switch self {
        case .beginner: return 0.2
        case .novice: return 0.5
        case .intermediate: return 0.8
        case .advanced: return 0.95
        case .elite: return 1.0
        }
    }
    
    var fullName: String {
        switch self {
        case .beginner: return "Beginner"
        case .novice: return "Novice"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .elite: return "Elite"
        }
    }
    
    static let categories: [String] = StrengthLevel.allCases.map(\.rawValue)
}

enum FitnessGoal: String, Codable, CaseIterable {
    case buildMuscle = "Build Muscle"
    case getStronger = "Get Stronger"
    case buildMuscleGetStronger = "Build Muscle and Get Stronger"
    // case improveEndurance = "Improve Endurance"  // New goal
    
    var name: String {
        switch self {
        case .buildMuscle:
            return "Build Muscle"
        case .getStronger:
            return "Get Stronger"
        case .buildMuscleGetStronger:
            return "Build Muscle & Get Stronger"
            /* case .improveEndurance:
             return "Improve Endurance"*/
        }
    }
    
    static func determineRestPeriod(for goal: FitnessGoal) -> Int {
        switch goal {
        case .buildMuscle:
            return 60 // 60 for isolation, 90 for compound
        case .getStronger:
            return 120 // 180 for isolation, 240 for compound
        case .buildMuscleGetStronger:
            return 90 // 120 for isolation, 180 for compound
            /* case .improveEndurance:
             return 30*/
        }
    }
    
    static func getRepsAndSets(for goal: FitnessGoal, restPeriod: Int) -> RepsAndSets {
        switch goal {
        case .buildMuscle:
            // Hypertrophy: Higher volume, moderate rest, high intensity
            return RepsAndSets(repsRange: 8...12, sets: 5, restPeriod: restPeriod) // 4 sets for isolation, 5 for compound
        case .getStronger:
            // Strength: Lower reps, more sets, longer rest, very high intensity
            return RepsAndSets(repsRange: 3...6, sets: 3, restPeriod: restPeriod) // 3 sets for isolation, 4 for compound
        case .buildMuscleGetStronger:
            // Hybrid: Blend of hypertrophy and strength, moderate reps, variable sets, moderate rest
            return RepsAndSets(repsRange: 6...10, sets: 4, restPeriod: restPeriod) // 4 sets for all?
            /* case .improveEndurance:
             return RepsAndSets(repsRange: 12...20, sets: 3, restPeriod: restPeriod)*/
        }
    }
    
    var detailDescription: String {
        switch self {
        case .buildMuscle:
            return "Reps: 8-12, Sets: 3, Rest: 60s"
            //return "Reps: \(self.repsAndSets), Sets: 3, Rest: 60s"
        case .getStronger:
            return "Reps: 3-6, Sets: 5, Rest: 120s"
        case .buildMuscleGetStronger:
            return "Reps: 6-10, Sets: 4, Rest: 90s"
            /*case .improveEndurance:
             return "Reps: 12-20, Sets: 3, Rest: 30s"*/
        }
    }
    
    var shortDescription: String {
        switch self {
        case .buildMuscle:
            return "Hypertrophy focused"
        case .getStronger:
            return "Strength focused"
        case .buildMuscleGetStronger:
            return "Hybrid focus"
            /*   case .improveEndurance:
             return "Endurance focused"*/
        }
    }
}

enum SetupState: Codable {
    case welcomeView
    case healthKitView
    case detailsView
    case goalView
    case finished
}

// landers unused
enum OneRMFormula {
    case epleys, landers, brzycki
    
    static func calculateOneRepMax(weight: Double, reps: Int, formula: OneRMFormula) -> Double {
        let weightInKg = weight * 0.453592
        let repsCount = Double(reps)
        
        switch formula {
        case .epleys:
            return (weightInKg * (1 + 0.0333 * repsCount)) * 2.2
        case .landers:
            return ((100 * weightInKg) / (101.3 - 2.67123 * repsCount)) * 2.2
        case .brzycki:
            return weight / (1.0278 - 0.0278 * repsCount)
        }
    }
    
    var description: String {
        switch self {
        case .epleys:
            return "1RM = weight(kg) × (1 + reps ÷ 30)"
        case .landers:
            return "1RM = 100 × weight(kg) ÷ (101.3 − 2.67123 × reps)"
        case .brzycki:
            return "1RM = weight(lb) ÷ (1.0278 − 0.0278 × reps)"
        }
    }
    
    /// “Auto‐select” rule: up to 8 reps → Brzycki; beyond 8 reps → Epley.
    static func recommendedFormula(forReps reps: Int) -> OneRMFormula {
        return reps <= 8 ? .brzycki : .epleys
    }
}

enum BMI {
    static func calculateBMI(heightInches: Int, heightFeet: Int, weight: Double) -> Double {
        let inches = Double(heightInches)
        let feet = Double(heightFeet)
        
        let totalInches = (feet * 12) + inches
        
        return (weight / (totalInches * totalInches)) * 703
    }
    
    static func recommendGoalBasedOnBMI(bmi: Double) -> FitnessGoal {
        switch bmi {
        case ..<18.5:
            return .buildMuscle
        case 18.5..<25.0:
            return .getStronger
        case 25.0...:
            return .buildMuscleGetStronger
        default:
            return .getStronger
        }
    }
}
