//
//  Exercise.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI


struct CurrentExerciseState: Codable, Equatable {
    var id: UUID
    var name: String
    var index: Int
    var startTime: Int
}

// the saved max value is the max reps or the calculated one rep max (in most cases, because you still can enter a one rep max value)
struct MaxRecord: Codable, Identifiable {
    var id: UUID = UUID() // Unique identifier for each record
    var value: Double     // The max value (could be one-rep max weight or number of reps as double for consistency)
    var repsXweight: RepsXWeight?
    var date: Date        // Date when the record was set
}

struct ExercisePerformance: Identifiable, Codable {
    let id: UUID // Using the exercise id as the identifier
    var maxValue: Double?
    var repsXweight: RepsXWeight?
    var estimatedValue: Double?
    var currentMaxDate: Date?
    var pastMaxes: [MaxRecord]?
    
    init(exerciseId: UUID) {
        self.id = exerciseId
    }
}

 // for saving jsons
struct InitExercise: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var aliases: [String]?
    var image: String
    var muscles: [MuscleEngagement]
    var description: String
    var equipmentRequired: [String]
    var effort: EffortType
    var url: String
    var type: ResistanceType
    var difficulty: StrengthLevel
    var equipmentAdjustments: ExerciseEquipmentAdjustments?
    var limbMovementType: LimbMovementType?
    var repsInstruction: RepsInstruction?
    var weightInstruction: WeightInstruction?
}
extension InitExercise {
    /// Build a draft from an existing Exercise so the view can edit it.
    init(from ex: Exercise) {
        self.id                   = ex.id
        self.name                 = ex.name
        self.aliases              = ex.aliases
        self.image                = ex.image
        self.muscles              = ex.muscles
        self.description          = ex.description
        self.equipmentRequired    = ex.equipmentRequired
        self.effort               = ex.effort
        self.url                  = ex.url
        self.type                 = ex.type
        self.difficulty           = ex.difficulty
        self.limbMovementType     = ex.limbMovementType
        self.repsInstruction      = ex.repsInstruction
        self.weightInstruction    = ex.weightInstruction
        // add any new fields you’ve introduced since
    }
}
 
struct Exercise: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let aliases: [String]?
    let image: String
    let muscles: [MuscleEngagement]
    let description: String
    let equipmentRequired: [String]
    let effort: EffortType
    let url: String
    let type: ResistanceType
    let difficulty: StrengthLevel
    let equipmentAdjustments: ExerciseEquipmentAdjustments?
    let limbMovementType: LimbMovementType?
    let repsInstruction: RepsInstruction?
    let weightInstruction: WeightInstruction?
    var currentSet: Int = 1
    var isCompleted: Bool = false
    var warmUpDetails: [SetDetail] = []
    var setDetails: [SetDetail] = []
    var allSetDetails: [SetDetail] { warmUpDetails + setDetails }
    var warmUpSets: Int { warmUpDetails.count }
    var sets: Int { setDetails.count }
    var totalSets: Int { warmUpSets + sets }
    var draft1rm: Double? // [A] for workout generation
    var draftMaxReps: Int? // [B] for workout generation
    var isSupersettedWith: String?  // UUID String
    var currentWeekAvgRPE: Double?
    var previousWeeksAvgRPE: [Double]?
    var weeksStagnated: Int = 0
    var overloadProgress: Int = 0
    var timeSpent: Int = 0
    var fullImagePath: String { return "Exercises/\(image)" }
    var fullImage: Image { getFullImage(image, fullImagePath) }
}
extension Exercise {
    /// Highest-engagement primary muscle (nil if none)
    private var topPrimaryMuscle: Muscle? {
        primaryMuscleEngagements
            .max(by: { $0.engagementPercentage < $1.engagementPercentage })?
            .muscleWorked
    }

    /// Auto-derived split
    var splitCategory: SplitCategory {
        guard let dominant = topPrimaryMuscle else { return .all }

        return SplitCategory.muscles.first { _, muscles in
            muscles.contains(dominant)
        }?.key ?? .all
    }
    
    var groupCategory: SplitCategory? {
        guard let dominant = topPrimaryMuscle else { return .all }

        return SplitCategory.groups.first { _, muscles in
            muscles.contains(dominant)
        }?.key ?? .all
    }

    /// Returns an array of MuscleEngagement for the prime movers.
    var primaryMuscleEngagements: [MuscleEngagement] { muscles.filter { $0.isPrimary } }
    
    /// Returns an array of MuscleEngagement for the assisting muscles.
    var secondaryMuscleEngagements: [MuscleEngagement] { muscles.filter { !$0.isPrimary } }
    
    /// Returns just the `Muscle` enums for the prime movers.
    var primaryMuscles: [Muscle] { primaryMuscleEngagements.map { $0.muscleWorked } }
    
    /// Returns just the `Muscle` enums for the secondary muscles.
    var secondaryMuscles: [Muscle] { secondaryMuscleEngagements.map { $0.muscleWorked } }
    
    var primarySubMuscles: [SubMuscles]? {
        let subs = primaryMuscleEngagements.flatMap { $0.allSubMuscles }
        return subs.isEmpty ? nil : subs
    }
    
    /// Returns an array of all submuscles within the *secondary* muscle engagements, or `nil` if none.
    var secondarySubMuscles: [SubMuscles]? {
        let subs = secondaryMuscleEngagements.flatMap { $0.allSubMuscles }
        return subs.isEmpty ? nil : subs
    }
    
    /// Returns *all* `Muscle` (primary + secondary) enumerations.
    var allMuscles: [Muscle] { muscles.map { $0.muscleWorked } }
    
    var allSubMuscles: [SubMuscles]? {
        let subs = muscles.flatMap { $0.allSubMuscles }
        return subs.isEmpty ? nil : subs
    }
    
    /// Returns all submuscles for a given muscle in this exercise.
    func subMuscles(for muscle: Muscle) -> [SubMuscles] {
        let muscleEngagement = muscles.first { $0.muscleWorked == muscle }
        return muscleEngagement?.allSubMuscles ?? []
    }
    
    var isUpperBody: Bool {
        if let groupCategory = groupCategory {
            return SplitCategory.upperBody.contains(groupCategory)
        } else {
            return SplitCategory.upperBody.contains(splitCategory)
        }
    }
    
    var isLowerBody: Bool {
        if let groupCategory = groupCategory {
            return SplitCategory.lowerBody.contains(groupCategory)
        } else {
            return SplitCategory.lowerBody.contains(splitCategory)
        }
    }
    
    var isPush: Bool {
        if let groupCategory = groupCategory {
            return SplitCategory.push.contains(groupCategory)
        } else {
            return SplitCategory.push.contains(splitCategory)
        }
    }
    
    var isPull: Bool {
        if let groupCategory = groupCategory {
            return SplitCategory.pull.contains(groupCategory)
        } else {
            return SplitCategory.pull.contains(splitCategory)
        }
    }
}

extension Exercise {
    /// Convenience initialiser that copies everything static
    /// and leaves the live-session fields at their defaults.
    init(from initEx: InitExercise) {
        self.id                   = initEx.id
        self.name                 = initEx.name
        self.aliases              = initEx.aliases
        self.image                = initEx.image
        self.muscles              = initEx.muscles
        self.description          = initEx.description
        self.equipmentRequired    = initEx.equipmentRequired
        self.effort               = initEx.effort
        self.url                  = initEx.url
        self.type                 = initEx.type
        self.equipmentAdjustments = initEx.equipmentAdjustments
        self.difficulty           = initEx.difficulty
        self.limbMovementType     = initEx.limbMovementType
        self.repsInstruction      = initEx.repsInstruction
        self.weightInstruction    = initEx.weightInstruction
        // everything else already has a default
    }
}

extension Exercise {
    // MARK: – Public computed properties
    var musclesTextFormatted: Text { formattedMuscles(from: primaryMuscleEngagements + secondaryMuscleEngagements) }
    var primaryMusclesFormatted: Text { formattedMuscles(from: primaryMuscleEngagements) }
    var secondaryMusclesFormatted: Text { formattedMuscles(from: secondaryMuscleEngagements) }
    
    // MARK: – Shared formatter
    private func formattedMuscles(from engagements: [MuscleEngagement]) -> Text {
        // Build a bullet-point line for every engagement
        let lines: [Text] = engagements.map { e in
            let name = Text("• \(e.muscleWorked.rawValue): ").bold()

            let subs = e.allSubMuscles
                .map { $0.simpleName }
                .joined(separator: ", ")

            return subs.isEmpty ? name : name + Text(subs)
        }

        guard let first = lines.first else { return Text("• None") }
        return lines.dropFirst().reduce(first) { $0 + Text("\n") + $1 }
    }
}

enum RepsInstruction: String, Codable, CaseIterable {
    case perLeg = "Per Leg"
    case perArm = "Per Arm"
    case perSide = "Per Side"
}

enum WeightInstruction: String, Codable, CaseIterable {
    case perDumbbell = "Per Dumbbell"
    case perStack = "Per Stack"
}

enum CategorySelections: Hashable {
    case split(SplitCategory)
    case muscle(Muscle)
    case upperLower(UpperLower)
    case pushPull(PushPull)
    case difficulty(StrengthLevel)
    case resistanceType(ResistanceType)
    case effortType(EffortType)
    
  
    var title: String {
        switch self {
            case .split(let s): return s.rawValue
            case .muscle(let m): return m.rawValue
            case .upperLower(let u): return u.rawValue
            case .pushPull(let p): return p.rawValue
            case .difficulty(let d): return d.rawValue
            case .resistanceType(let r): return r.rawValue
        case .effortType(let e): return e.rawValue
        }
    }
}

enum FavoriteState: String, CaseIterable {
    case favorite = "Favorite"
    case disliked = "Disliked"
    case unmarked = "Unmarked"
}

enum UpperLower: String, Codable, CaseIterable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
}

enum PushPull: String, Codable, CaseIterable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
}

enum ExerciseSortOption: String, Codable, CaseIterable, Equatable {
    case simple = "Simple"     // Sort by Simple: All, Back, Legs, Arms, Abs, Shoulders, Chest, Biceps, Triceps
    
    case moderate = "Moderate"     // Sort by Moderate: All, Back, Quads, Calves, Hamstrings, Glutes, Abs, Shoulders, Chest, Biceps, Triceps, Forearms
    
    case complex = "Complex"     // Sort by Complex: All, Abs, Chest, Shoulders, Biceps, Triceps, Trapezius, Latissimus Dorsi, Erector Spinae, Quadriceps, Gluteus, Hamstrings, Hip Flexors, Stabilizers, Calves, Forearms, Neck
    
    case upperLower = "Upper/Lower"     // Sort by Upper Lower: Upper Body, Lower Body
    
    case pushPull = "Push/Pull/Legs"     // Sort by Push Pull: Push, Pull, Legs
    
    case difficulty = "Difficulty" // Sort by Beginner, Novice, Intermediate, Advanced, Elite
    
    case resistanceType = "Resistance Type" // Sort by Bodyweight, Weighted, Free Weight, Machine*
    
    case effortType = "Effort Type" // Sort by Bodyweight, Weighted, Free Weight, Machine*
    
    // Sort by template categories ([SplitCategory])
    case templateCategories = "Template Categories" // removes exercises and categories that are not in the template categories
}

enum ResistanceType: String, CaseIterable, Identifiable, Codable {
    case any = "Any"
    case bodyweight = "Bodyweight"
    case weighted = "Weighted"
    case freeWeight = "Free Weight"
    case machine = "Machine"
    //case banded = "Banded"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var usesWeight: Bool {
        switch self {
        case .bodyweight, .other /*,.banded*/:
            return false
        case .weighted, .freeWeight, .machine:
            return true
        default: return false
        }
    }
}

enum LimbMovementType: String, Codable, CaseIterable {
    case unilateral = "Unilateral" // One limb working at a time (e.g., glute kickbacks)
    case bilateralIndependent = "Bilateral Independent" // Both limbs work separately but simultaneously (e.g., dumbbell shoulder press)
    case bilateralDependent = "Bilateral Dependent" // Both limbs work together (e.g., bench press, squat)
    
    var description: String {
        switch self {
        case .unilateral:
            return "One limb working at a time" // would say 'per arm' or 'per leg' in caption font around the reps text
        case .bilateralIndependent:
            return "Both limbs working independently but simultaneously" // would say 'per arm' or 'per leg' in caption font around the weight text
        case .bilateralDependent:
            return "Both limbs working together at the same time"
        }
    }
}

enum EffortType: String, CaseIterable, Identifiable, Codable {
    case compound   = "Compound"    // multi-joint, dynamic
    case isolation  = "Isolation"   // single-joint, dynamic
    case isometric  = "Isometric"   // joint angle static, time-based load
    case plyometric = "Plyometric"
    //case cardio     = "Cardio"      // primarily metabolic
    
    var id: String { self.rawValue }
}

enum CallBackAction: String {
    case addSet, deleteSet, removeExercise, replaceExercise, viewDetail, viewAdjustments, saveTemplate
}
