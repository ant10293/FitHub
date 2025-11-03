//
//  Engagement.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/14/25.
//

import Foundation

struct SubMuscleEngagement: Hashable, Codable {
    var submuscleWorked: SubMuscles
    var engagementPercentage: Double
}
 
struct MuscleEngagement: Hashable, Codable {
    var muscleWorked: Muscle
    var engagementPercentage: Double
    var mover: MoverType
    var submusclesWorked: [SubMuscleEngagement]?
}
extension MuscleEngagement {
    var allSubMuscles: [SubMuscles] { submusclesWorked?.map { $0.submuscleWorked } ?? [] }
    var topSubMuscle: SubMuscles? {
        submusclesWorked?.max { $0.engagementPercentage < $1.engagementPercentage }?.submuscleWorked
    }
}

extension Sequence where Element == MuscleEngagement {
    /// Only primary movers
    var primary: [MuscleEngagement] { filter { $0.mover == .primary } }

    /// Only assistants
    var secondary: [MuscleEngagement] { filter { $0.mover == .secondary } }

    /// Primary muscles only
    var primaryMuscles: [Muscle] { primary.map(\.muscleWorked) }

    /// Secondary muscles only
    var secondaryMuscles: [Muscle] { secondary.map(\.muscleWorked) }

    /// All muscles (primary + secondary)
    var allMuscles: [Muscle] { map(\.muscleWorked) }

    /// Flatten all submuscles across engagements
    var allSubMuscles: [SubMuscles] { flatMap(\.allSubMuscles) }

    /// Highest-engagement primary muscle (nil if none)
    var topPrimaryMuscle: Muscle? {
        primary.max { $0.engagementPercentage < $1.engagementPercentage }?.muscleWorked
    }
}

enum MoverType: String, Codable, Hashable, CaseIterable {
    case primary, secondary, tertiary, stabilizer
    
    var displayName: String {
        switch self {
        case .primary: return "Primary"
        case .secondary: return "Secondary"
        case .tertiary: return "Tertiary"
        case .stabilizer: return "Stabilizer"
        }
    }
}
