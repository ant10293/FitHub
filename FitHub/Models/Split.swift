//
//  SplitTypes.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


enum SplitCategory: String, CaseIterable, Identifiable, Codable {
    // MARK: - Muscle Group
    case all = "All"
    case back = "Back"
    case legs = "Legs"
    case arms = "Arms"
    
    case abs = "Abs"
    case shoulders = "Shoulders"
    case chest = "Chest"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    // MARK: - Accessory Groups
    case calves = "Calves"
    case forearms = "Forearms"
    
    var id: String { self.rawValue }
    
    static let upperBody: Set<SplitCategory> = [.back, .shoulders, .arms, .chest, .biceps, .triceps, .forearms]
    static let lowerBody: Set<SplitCategory> = [.legs, .quads, .hamstrings, .glutes, .calves]
    static let push: Set<SplitCategory> = [.chest, .shoulders, .triceps]
    static let pull: Set<SplitCategory> = [.back, .biceps]
    static let armsFocus: Set<SplitCategory> = [.biceps, .triceps, .forearms]
    static let legsFocus: Set<SplitCategory> = [.quads, .hamstrings, .glutes, .calves]
    
    static let muscles: [SplitCategory: [Muscle]] = [
        .all: [.all],
        .abs: [.abdominals],
        .shoulders: [.deltoids, .rotatorCuff, .serratus],
        .chest: [.pectorals],
        .biceps: [.biceps],
        .triceps: [.triceps],
        .forearms: [.forearms],
        .quads: [.quadriceps],
        .hamstrings: [.hamstrings],
        .glutes: [.gluteus],
        .calves: [.calves]
    ]
     
    static let groups: [SplitCategory: [Muscle]] = [
         //.back: [.trapezius, .latissimusDorsi, .erectorSpinae, .scapularRetractors, .serratus], // should only include important
        .back: [.trapezius, .latissimusDorsi, .erectorSpinae],
        .legs: [.quadriceps, .hamstrings, .gluteus],
         //.legs: [.quadriceps, .hamstrings, .gluteus, .calves, .hipComplex, .deepHipRotators, .tibialis, .peroneals],
        .arms: [.biceps, .triceps]
        //.arms: [.biceps, .triceps, .forearms]
    ]

    static let hasFrontImages: Set<SplitCategory> = [
        .all, .legs, .arms, .abs, .chest, .shoulders, .biceps, .triceps, .forearms, .quads, .calves
    ]
    
    static let hasRearImages: Set<SplitCategory> = [
        .all, .legs, .arms, .shoulders, .back, .triceps, .forearms, .hamstrings, .glutes, .calves
    ]
    
    static let hasBothImages: Set<SplitCategory> = hasFrontImages.intersection(hasRearImages)
}

extension SplitCategory: CustomStringConvertible {
    public var description: String { rawValue }
    
    public var legDetail: String? {
        switch self {
        case .quads: return "Quad"
        case .glutes: return "Glute"
        case .hamstrings: return "Hamstring"
        case .calves: return "Calf"
        default:
            return nil
        }
    }
    
    static func legFocusCategories(_ categories: [SplitCategory]) -> [SplitCategory] {
        guard categories.contains(.legs) else { return [] }

        return categories.filter { legsFocus.contains($0) }
    }
    
    static func concatenateCategories(for categories: [SplitCategory]) -> String {
        // 1) “All” → “Full Body”
        if categories.contains(.all) {
            return "Full Body"
        }

        // 2) Split into leg‐subcategories vs. everything else
        let legSubcats = categories.filter { legsFocus.contains($0) }
        let others    = categories.filter { !legsFocus.contains($0) }

        var parts: [String] = []

        // 3) Only if the bare “.legs” was selected, group subcats under “Legs: … focused”
        if categories.contains(.legs) {
            if !legSubcats.isEmpty {
                let names = legSubcats.map { $0.legDetail ?? $0.rawValue }
                parts.append("Legs: " + names.joined(separator: ", ") + " focused")
            } else {
                // .legs alone, no finer subcats → just “Legs”
                parts.append("Legs")
            }
        }

        // 4) Now list any non‐leg (or subcat‐only) selections that weren’t already handled.
        //    If .legs was not in categories, we simply list all chosen categories (including subcats).
        if !categories.contains(.legs) {
            // Just show everything by rawValue
            parts = categories.map { $0.rawValue }
        } else {
            // .legs was in categories, so append any “other” (non‐leg) categories
            let otherNames = others
                // avoid re‐adding “.legs” itself
                .filter { $0 != .legs }
                .map { $0.rawValue }
            parts.append(contentsOf: otherNames)
        }

        return parts.joined(separator: ", ")
    }
    
    static var columnGroups: [[SplitCategory]] {
        [
            [.all, .shoulders, .back, .abs, .chest],
            [.legs, .quads, .glutes, .hamstrings, .calves],
            [.arms, .biceps, .triceps, .forearms]
        ]
    }
}

/*
enum SplitType: String, CaseIterable, Identifiable, Codable {
    case fullBody = "Full-Body"
    case broSplit = "Bro Split"
    case upperLower = "Upper / Lower"
    case pushPullLegs = "Push / Pull / Legs"
    case upperLowerPPL = "Upper / Lower + PPL"
    case arnoldSplit = "Arnold Split"
    case antagonistSplit = "Antagonist Split"
    case torsoLimb = "Torso / Limb"
    
    var id: String { self.rawValue }
    
    var frequencyRange: ClosedRange<Int> {
        switch self {
        case .fullBody: return 2...4
        case .broSplit: return 5...6
        case .upperLower: return 3...5
        case .pushPullLegs: return 3...6
        case .upperLowerPPL: return 5...6
        case .arnoldSplit: return 6...6
        case .antagonistSplit: return 4...6
        case .torsoLimb: return 4...5
        }
    }

    var minimumDaysRequired: Int {
        frequencyRange.lowerBound
    }
    
    var description: String {
        switch self {
        case .fullBody:
            return "Trains the entire body each session. Great for beginners or maximizing efficiency with fewer training days."
        case .broSplit:
            return "Focuses on one major muscle group per day. Popular in bodybuilding circles for high volume per body part."
        case .upperLower:
            return "Alternates between upper and lower body workouts. Balanced and time-efficient for both strength and hypertrophy."
        case .pushPullLegs:
            return "Divides workouts by movement pattern: push (chest/shoulders/triceps), pull (back/biceps), and legs. Easy to scale and structure."
        case .upperLowerPPL:
            return "Combines upper/lower and push/pull/legs into a hybrid rotation. Designed for more advanced lifters needing higher volume and variety."
        case .arnoldSplit:
            return "Classic six-day routine used by Arnold Schwarzenegger, pairing chest/back, shoulders/arms, and legs. Built for high volume and symmetry."
        case .antagonistSplit:
            return "Pairs opposing muscle groups (e.g., chest/back or biceps/triceps) to improve balance, efficiency, and recovery within workouts."
        case .torsoLimb:
            return "Separates workouts into torso (chest, back, shoulders) and limbs (arms, legs). Offers functional variety and recovery balance."
        }
    }
}
*/
