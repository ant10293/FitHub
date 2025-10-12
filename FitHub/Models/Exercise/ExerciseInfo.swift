//
//  ExerciseInfo.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import Foundation
import SwiftUI

enum CategorySelections: Hashable {
    case split(SplitCategory)
    case muscle(Muscle)
    case upperLower(UpperLower)
    case pushPull(PushPull)
    case difficulty(StrengthLevel)
    case resistanceType(ResistanceType)
    case effortType(EffortType)
    case limbMovement(LimbMovementType)
  
    var title: String {
        switch self {
        case .split(let s): return s.rawValue
        case .muscle(let m): return m.rawValue
        case .upperLower(let ul): return ul.rawValue
        case .pushPull(let pp): return pp.rawValue
        case .difficulty(let d): return d.rawValue
        case .resistanceType(let rt): return rt.rawValue
        case .effortType(let et): return et.rawValue
        case .limbMovement(let lm): return lm.rawValue
        }
    }
}

enum FavoriteState: String, CaseIterable {
    case favorite = "Favorite"
    case disliked = "Disliked"
    case unmarked = "Unmarked"
    
    static func getState(for exercise: Exercise, userData: UserData) -> FavoriteState {
        return userData.evaluation.favoriteExercises.contains(exercise.id) ? .favorite
        : (userData.evaluation.dislikedExercises.contains(exercise.id) ? .disliked : .unmarked)
    }
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
    
    case limbMovement = "Limb Movement"
    
    // Sort by template categories ([SplitCategory])
    case templateCategories = "Template Categories" // removes exercises and categories that are not in the template categories
    
    func getDefaultSelection(templateCategories: [SplitCategory]?) -> CategorySelections {
        switch self {
        case .simple, .moderate: return .split(.all)
        case .complex: return .muscle(.all)
        case .upperLower: return .upperLower(.upperBody)
        case .pushPull: return .pushPull(.push)
        case .difficulty: return .difficulty(.beginner)
        case .resistanceType: return .resistanceType(.any)
        case .effortType: return .effortType(.compound)
        case .limbMovement: return .limbMovement(.unilateral)
        case .templateCategories:
            if let categories = templateCategories, let firstCat = categories.first {
                return .split(firstCat)
            } else {
                return .split(.all)
            }
        }
    }
}

enum ResistanceType: String, CaseIterable, Identifiable, Codable {
    case any = "Any"
    case bodyweight = "Bodyweight"
    case weighted = "Weighted"
    case freeWeight = "Free Weight"
    case machine = "Machine"
    case banded = "Banded"
    case other = "Other"
    
    var id: String { self.rawValue }
  
    static let forExercises: [ResistanceType] = [.freeWeight, .bodyweight, .machine, .banded]
}

enum RepsInstruction: String, Codable, CaseIterable {
    case perLeg = "Per Leg"
    case perArm = "Per Arm"
    case perSide = "Per Side"
}

enum WeightInstruction: String, Codable, CaseIterable {
    case perDumbbell = "Per Dumbbell"
    case perStack = "Per Stack"
    case perPeg = "Per Peg"
    // case perSleeve = "Per Sleeve"
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
    
    var displayInfoText: Text {
        Text("Limb movement: ").bold() + Text(self.rawValue) + Text("\n ") +
        Text(self.description).foregroundStyle(.secondary).font(.caption)
    }
    
    // for volume calculations
    var repsMultiplier: Int { switch self { case .unilateral: 2; default: 1 } }
    var weightMultiplier: Double { switch self { case .bilateralIndependent: 2; default: 1 } }
}

enum EffortType: String, CaseIterable, Identifiable, Codable {
    case compound   = "Compound"    // multi-joint, dynamic
    case isolation  = "Isolation"   // single-joint, dynamic
    case isometric  = "Isometric"   // joint angle static, time-based load
    case plyometric = "Plyometric"
    case cardio     = "Cardio"      // primarily metabolic
    
    var id: String { self.rawValue }
    
    static let strengthTypes: [EffortType] = [.compound, .isolation, .isometric, .plyometric]
        
    var usesReps: Bool {
        switch self {
        case .compound, .isolation, .plyometric:
            return true
        case .isometric, .cardio:
            return false
        }
    }
    
    // TODO: order in which the exercise with type should occur in the generated workout
    var order: Int {
        switch self {
        case .plyometric: return 1
        case .compound: return 2
        case .isolation: return 3
        case .isometric: return 4
        case .cardio: return 5
        }
    }
}

struct CurrentExerciseState: Codable, Equatable {
    var id: UUID
    var name: String
    var index: Int
    var startTime: Int
}

struct ExerciseInstructions: Codable, Hashable {
    private(set) var steps: [String] = []

    init(steps: [String] = []) { self.steps = steps }

    var count: Int { steps.count }

    func step(at index: Int) -> String? {
        guard steps.indices.contains(index) else { return nil }
        return steps[index]
    }

    mutating func add(_ text: String, at index: Int? = nil) {
        if let i = index, steps.indices.contains(i) {
            steps.insert(text, at: i)
        } else {
            steps.append(text)
        }
    }

    mutating func update(_ text: String, at index: Int) {
        guard steps.indices.contains(index) else { return }
        steps[index] = text
    }

    mutating func remove(at index: Int) {
        guard steps.indices.contains(index) else { return }
        steps.remove(at: index)
    }

    mutating func move(from: Int, to: Int) {
        guard steps.indices.contains(from) else { return }
        let clampedTo = max(0, min(to, steps.count - 1))
        let item = steps.remove(at: from)
        steps.insert(item, at: clampedTo)
    }
    
    // MARK: - Pretty printing
    func formattedString(prefix: String = "", numberingStyle: NumberingStyle = .oneDot, leadingNewline: Bool = false) -> String? {
        let clean = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !clean.isEmpty else { return nil }

        let body = clean.enumerated().map { idx, text in
            "\(prefix)\(numberingStyle.label(for: idx + 1)) \(text)"
        }
        .joined(separator: "\n")

        return (leadingNewline ? "\n" : "") + body
    }

    enum NumberingStyle {
        case oneDot        // "1."
        case oneParen      // "1)"
        case stepWord      // "Step 1:"
        case bullet        // "•" (no number)

        fileprivate func label(for n: Int) -> String {
            switch self {
            case .oneDot:   return "\(n)."
            case .oneParen: return "\(n))"
            case .stepWord: return "Step \(n):"
            case .bullet:   return "•"
            }
        }
    }
}

enum CallBackAction: String {
    case addSet, deleteSet, removeExercise, replaceExercise, viewDetail, viewAdjustments, saveTemplate
}

struct RPEentry: Hashable, Codable {
    var id: Date // workout start date
    var rpe: Double
    var completion: PeakMetric
}

struct RPEentries: Hashable, Codable {
    var entries: [RPEentry]
    
    var avgRPE: Double? {
        guard !entries.isEmpty else { return nil }
        let sum = entries.reduce(0.0) { $0 + $1.rpe }
        return sum / Double(entries.count)
    }

    var avgPeakValue: Double? {
        guard !entries.isEmpty else { return nil }
        let sum = entries.reduce(0.0) { $0 + $1.completion.actualValue }
        let avg = sum / Double(entries.count)
        return avg
    }
}
