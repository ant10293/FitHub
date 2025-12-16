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

enum ExEquipLocation: String {
    case user, bundled, none
}

// landers unused
enum OneRMFormula {
    case epleys, landers, brzycki, oconnor

    static let canonical: OneRMFormula = .brzycki

    @inline(__always)
    func percent(at reps: Int) -> Double {
        let r = max(1, reps) // clamp to sane range
        switch self {
        case .epleys:
            // 1RM = W * (1 + 0.0333*r)  =>  % = 1 / (1 + 0.0333*r)
            return 1.0 / (1.0 + 0.0333 * Double(r))
        case .landers:
            // 1RM = (100*W) / (101.3 − 2.67123*r)  =>  % = (101.3 − 2.67123*r) / 100
            return max((101.3 - 2.67123 * Double(r)) / 100.0, 0.0001)
        case .brzycki:
            // 1RM = W / (1.0278 − 0.0278*r)  =>  % = (1.0278 − 0.0278*r)
            return max(1.0278 - 0.0278 * Double(r), 0.0001)
        case .oconnor:
            // 1RM = W * (1 + 0.025*r)  =>  % = 1 / (1 + 0.025*r)
            return 1.0 / (1.0 + 0.025 * Double(r))
        }
    }

    static func calculateOneRepMax(weight: Mass, reps: Int, formula: OneRMFormula = canonical) -> Mass {
        guard weight.inKg > 0, reps > 1 else { return weight }
        let p = formula.percent(at: reps) // %1RM fraction
        return Mass(kg: weight.inKg / p)
    }

    /// Calculate approximate reps for a given percentage of 1RM
    /// This is the inverse of `percent(at:)`
    @inline(__always)
    func reps(at percent: Double) -> Int {
        let clamped = max(0.0001, min(1.0, percent)) // Clamp to valid range
        switch self {
        case .epleys:
            // % = 1 / (1 + 0.0333*r)  =>  r = (1/% - 1) / 0.0333
            let r = (1.0 / clamped - 1.0) / 0.0333
            return max(1, Int(round(r)))
        case .landers:
            // % = (101.3 - 2.67123*r) / 100  =>  r = (101.3 - 100*%) / 2.67123
            let r = (101.3 - 100.0 * clamped) / 2.67123
            return max(1, Int(round(r)))
        case .brzycki:
            // % = 1.0278 - 0.0278*r  =>  r = (1.0278 - %) / 0.0278
            let r = (1.0278 - clamped) / 0.0278
            return max(1, Int(round(r)))
        case .oconnor:
            // % = 1 / (1 + 0.025*r)  =>  r = (1/% - 1) / 0.025
            let r = (1.0 / clamped - 1.0) / 0.025
            return max(1, Int(round(r)))
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
        case .oconnor:
            return "1RM = weight(kg) × (1 + 0.025 × reps)"
        }
    }
}

enum WeightedHoldFormula {
    static let canonical: TimeSpan = .init(seconds: 30)

    /// Convert (weight × time) hold to an equivalent load at reference time.
    static func equivalentHoldLoad(
        weight: Mass,                  // effective kg for the hold
        duration: TimeSpan,          // seconds
        reference: TimeSpan = canonical,
        exponent k: Double = 0.5
    ) -> Mass {
        let t = max(1.0, Double(duration.inSeconds))
        let tRef = max(1.0, Double(reference.inSeconds))
        let scale = pow(t / tRef, k)
        return Mass(kg: weight.inKg * scale)
    }
}

enum WeightedCarryFormula {
    static let canonical: Meters = Meters(meters: 50) // 50 meters

    /// Convert (weight × distance) carry to an equivalent load at reference distance.
    static func equivalentCarryLoad(
        weight: Mass,                  // effective kg for the carry
        distance: Meters,              // distance covered
        reference: Meters = canonical,
        exponent k: Double = 0.5
    ) -> Mass {
        let d = max(1.0, distance.inM)
        let dRef = max(1.0, reference.inM)
        let scale = pow(d / dRef, k)
        return Mass(kg: weight.inKg * scale)
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
        let bmr: Double = 10.0 * weightKg + 6.25 * heightCm - 5 * age
        if gender == .male {
            return bmr + 5
        } else {
            return bmr - 161
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

enum LegalURL {
    static let urlPrefix = "https://ant10293.github.io/fithub-legal/"

    case privacyPolicy, termsOfService, affiliateTerms

    var rawURL: String {
        LegalURL.urlPrefix + urlSuffix + "/"
    }

    var urlSuffix: String {
        switch self {
        case .privacyPolicy: "privacy"
        case .termsOfService: "terms"
        case .affiliateTerms: "affiliate-terms"
        }
    }

    var title: String {
        switch self {
        case .privacyPolicy: "Privacy Policy"
        case .termsOfService: "Terms of Service"
        case .affiliateTerms: "Affiliate Terms & Conditions"
        }
    }
}

enum EquipmentOption {
    case originalOnly, alternativeOnly, both, dynamic
}

// MARK: global Affiliate System flag
let useAffiliateSystem: Bool = false
