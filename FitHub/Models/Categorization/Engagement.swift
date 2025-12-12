//
//  Engagement.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/14/25.
//

import Foundation
import SwiftUI

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

    /// Dict of submuscles -> engagementPercentage
    var submuscleDict: [SubMuscles: Double] {
        (submusclesWorked ?? []).reduce(into: [:]) { dict, s in
            dict[s.submuscleWorked] = s.engagementPercentage
        }
    }
}

extension MuscleEngagement {
    /// Returns a similarity percentage (0...100) between two MuscleEngagements.
    func similarity(to other: MuscleEngagement) -> Double {
        // 1) Primary engagement similarity (0...1)
        let primaryDiff = abs(engagementPercentage - other.engagementPercentage)
        let primarySimilarity = (1.0 - min(primaryDiff, 100.0) / 100.0).clamped01

        // 2) Sub-muscle engagement similarity (0...1)
        let dictA = submuscleDict
        let dictB = other.submuscleDict

        let submuscleSimilarity: Double
        if dictA.isEmpty && dictB.isEmpty {
            submuscleSimilarity = 1.0
        } else {
            let allKeys = Set(dictA.keys).union(dictB.keys)

            var sumMin: Double = 0
            var sumMax: Double = 0

            for key in allKeys {
                let aVal = dictA[key] ?? 0
                let bVal = dictB[key] ?? 0
                sumMin += Swift.min(aVal, bVal)
                sumMax += Swift.max(aVal, bVal)
            }

            submuscleSimilarity = (sumMax == 0) ? 1.0 : (sumMin / sumMax)
        }

        // 3) Penalize if primary muscle / mover differ, but don't zero out
        let muscleMatchFactor: Double = (muscleWorked == other.muscleWorked) ? 1.0 : 0.7
        let moverMatchFactor: Double  = (mover == other.mover) ? 1.0 : 0.9

        // 4) Blend components
        let primaryWeight    = 0.5
        let submuscleWeight  = 0.5

        var combined =
            primaryWeight   * primarySimilarity +
            submuscleWeight * submuscleSimilarity

        combined *= muscleMatchFactor
        combined *= moverMatchFactor

        return (combined.clamped01 * 100.0)
    }
}

extension Collection where Element == MuscleEngagement {
    /// Returns a similarity percentage (0...100) between two *sets* of MuscleEngagement.
    func similarityPct(to other: [MuscleEngagement]) -> Double {
        let thisArray = Array(self)

        // Empty vs empty -> perfect match
        if thisArray.isEmpty && other.isEmpty {
            return 100.0
        }

        let dictA = thisArray.collapsedByMuscle()
        let dictB = other.collapsedByMuscle()
        let allMuscles = Set(dictA.keys).union(dictB.keys)

        var sumWeightedOverlap: Double = 0
        var sumUnion: Double = 0

        for muscle in allMuscles {
            let a = dictA[muscle]?.engagementPercentage ?? 0
            let b = dictB[muscle]?.engagementPercentage ?? 0

            let minVal = Swift.min(a, b)
            let maxVal = Swift.max(a, b)
            sumUnion += maxVal

            if let aEng = dictA[muscle], let bEng = dictB[muscle], maxVal > 0 {
                let perMuscleSim01 = aEng.similarity(to: bEng) / 100.0
                sumWeightedOverlap += minVal * perMuscleSim01
            }
        }

        // Also compare submuscles directly across all engagements
        let submuscleDictA = thisArray.collapsedBySubmuscle()
        let submuscleDictB = other.collapsedBySubmuscle()
        let allSubmuscles = Set(submuscleDictA.keys).union(submuscleDictB.keys)

        var submuscleSumWeightedOverlap: Double = 0
        var submuscleSumUnion: Double = 0

        for submuscle in allSubmuscles {
            let a = submuscleDictA[submuscle] ?? 0
            let b = submuscleDictB[submuscle] ?? 0

            let minVal = Swift.min(a, b)
            let maxVal = Swift.max(a, b)
            submuscleSumUnion += maxVal

            if maxVal > 0 {
                // Calculate similarity based on overlap ratio
                let submuscleSim01 = minVal / maxVal
                submuscleSumWeightedOverlap += minVal * submuscleSim01
            }
        }

        // Blend muscle-level and submuscle-level similarities
        let muscleSimilarity01 = (sumUnion > 0) ? (sumWeightedOverlap / sumUnion) : 1.0
        let submuscleSimilarity01 = (submuscleSumUnion > 0) ? (submuscleSumWeightedOverlap / submuscleSumUnion) : 1.0

        // Weight: 60% muscle-level, 40% submuscle-level
        let muscleWeight = 0.6
        let submuscleWeight = 0.4
        let combinedSimilarity01 = muscleWeight * muscleSimilarity01 + submuscleWeight * submuscleSimilarity01

        return (combinedSimilarity01.clamped01 * 100.0)
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

    /// Keeps the entry with the highest engagementPercentage per muscle.
    func collapsedByMuscle() -> [Muscle: MuscleEngagement] {
        reduce(into: [:]) { dict, m in
            if let existing = dict[m.muscleWorked] {
                if m.engagementPercentage > existing.engagementPercentage {
                    dict[m.muscleWorked] = m
                }
            } else {
                dict[m.muscleWorked] = m
            }
        }
    }

    /// Collapses all submuscle engagements across all muscle engagements, keeping the highest engagement percentage per submuscle.
    func collapsedBySubmuscle() -> [SubMuscles: Double] {
        reduce(into: [:]) { dict, muscleEngagement in
            guard let submuscles = muscleEngagement.submusclesWorked else { return }
            for submuscleEngagement in submuscles {
                let submuscle = submuscleEngagement.submuscleWorked
                let engagement = submuscleEngagement.engagementPercentage
                if let existing = dict[submuscle] {
                    dict[submuscle] = Swift.max(existing, engagement)
                } else {
                    dict[submuscle] = engagement
                }
            }
        }
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
