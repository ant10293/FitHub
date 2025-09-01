//
//  Core.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI

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

enum SetupState: Codable {
    case welcomeView, healthKitView, detailsView, goalView, finished
}

enum inOut { case input, output }

// landers unused
enum OneRMFormula {
    case epleys, landers, brzycki, oconnor
    
    static func calculateOneRepMax(weight: Mass, reps: Int, formula: OneRMFormula) -> Mass {
        guard reps > 1 else { return weight }   // 1 rep ⇒ already a 1 RM
        let r = Double(reps), w = weight.inKg
        guard w > 0 else { return weight }

        let resultKg: Double
        switch formula {
        case .epleys:
            // 1RM = W * (1 + 0.0333 * r)
            resultKg = w * (1.0 + 0.0333 * r)

        case .landers:
            // 1RM = (100 * W) / (101.3 − 2.67123 * r)
            // Denominator can approach zero at very high reps; clamp to stay safe.
            let denom = max(101.3 - 2.67123 * r, 0.0001)
            resultKg = (100.0 * w) / denom

        case .brzycki:
            // 1RM = W / (1.0278 − 0.0278 * r)
            // Clamp denominator to avoid blow-ups past ~37 reps (we clamp reps anyway).
            let denom = max(1.0278 - 0.0278 * r, 0.0001)
            resultKg = w / denom

        case .oconnor:
            // 1RM = W * (1 + 0.025 * r)
            resultKg = w * (1.0 + 0.025 * r)
        }

        return Mass(kg: resultKg)
    }

    var description: String {
        switch self {
        case .epleys:
            return "1RM = weight(kg) × (1 + reps ÷ 30)"
        case .landers:
            return "1RM = 100 × weight(kg) ÷ (101.3 − 2.67123 × reps)"
        case .brzycki:
            return "1RM = weight(lb) ÷ (1.0278 − 0.0278 × reps)"
        case .oconnor:
            return "1RM = weight(kg) × (1 + 0.025 × reps)"
        }
    }
    
    /// “Auto‐select” rule: up to 8 reps → Brzycki; beyond 8 reps → Epley.
    static func recommendedFormula(forReps reps: Int) -> OneRMFormula {
        return reps <= 10 ? .epleys : .oconnor
    }
}

enum BMI {
    static func calculateBMI(heightCm: Double, weightKg: Double) -> Double {
        let heightM = heightCm / 100.0                     // convert to metres
        guard heightM > 0 else { return 0 }                // avoid div‑by‑zero
        
        let bmi = weightKg / (heightM * heightM)
        return (bmi * 10).rounded() / 10                   // 1 decimal place
    }
    
    static func recommendGoalBasedOnBMI(bmi: Double) -> FitnessGoal {
        switch bmi {
        case ..<18.5:
            return .buildMuscle
        case 18.5..<22.0:
            return .getStronger
        case 22.0..<25.0:
            return .generalFitness
        case 25.0..<30.0:
            return .buildMuscleGetStronger
        case 30...:
            return .loseWeight
        default:
            return .getStronger
        }
    }
}

enum BMR {
    static func calculateBMR(gender: Gender, weightKg: Double, heightCm: Double, age: Double) -> Double {
        if gender == .male {
            return 10.0 * weightKg + 6.25 * heightCm - 5 * age + 5
        } else {
            return 10.0 * weightKg + 6.25 * heightCm - 5 * age - 161
        }
    }
}

enum RestType: String, CaseIterable, Identifiable, Hashable, Codable {
    case warmup = "Warm-up"
    case working = "Working"
    case superset = "Superset"
    
    var id: String { rawValue }
    
    var note: String {
        switch self {
        case .warmup:   "Rest between warm-up sets"
        case .working:  "Rest between working sets"
        case .superset: "Rest between supersetted sets"
        }
    }
}

/*
struct SupersetSettings: Codable, Hashable {
    var enabled: Bool = false
    var style: SupersetOption = .sameEquipment
    var maxPairs: Int = 1         // 0–2 recommended
    var restBetweenSupersets: Int?
}

enum SupersetOption: String, CaseIterable, Codable {
    case sameEquipment, sameMuscle, relatedMuscle
}
*/

