//
//  Settings.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


enum Gender: Hashable, Codable {
    case male, female, notSet
}

enum Languages: String, Codable, CaseIterable  {
    case english = "English"
    case spanish = "Spanish"
    case french = "French"
}

enum Themes: String, CaseIterable, Codable {
    case lightMode = "Light Mode"
    case darkMode = "Dark Mode"
    case defaultMode = "Default Mode" // uses device settings
}

enum ProgressiveOverloadStyle: String, CaseIterable, Codable {
    case increaseWeight = "Increase Weight"
    case increaseReps = "Increase Reps"
    case decreaseReps = "Decrease Reps"
    case dynamic = "Dynamic"
    
    var desc: String {
        switch self {
        case .increaseWeight:
            return "Weight is slightly increased while reps remain the same."
        case .increaseReps:
            return "Reps are increased per week while weight remains the same. At the end of the period, reps will decrease to original values and weight will be increased."
        case .decreaseReps:
            return "Reps are decreased per week while weight is increased. At the end of the period, reps will increase to orgininal values and weight will be decreased to accomodate the increased reps."
        case .dynamic:
            return "Reps will be increased each week. Once halfway through period, reps will return to original value and weight will be increased slightly. For remainder of weeks, reps will remain the same while weight increases."
        }
    }
    
    static func determineStyle(
        overloadStyle: ProgressiveOverloadStyle,
        overloadPeriod: Int,
        rAndS: RepsAndSets
    ) -> ProgressiveOverloadStyle {
        let incompatible = incompatibleOverloadStyle(
            overloadStyle: overloadStyle,
            overloadPeriod: overloadPeriod,
            rAndS: rAndS
        )
        
        return incompatible ? .dynamic : overloadStyle
    }
    
    static func incompatibleOverloadStyle(
        overloadStyle: ProgressiveOverloadStyle,
        overloadPeriod: Int,
        rAndS: RepsAndSets,
    ) -> Bool {
        guard overloadStyle == .decreaseReps else { return false }
        let range = rAndS.reps.overallRange(filteredBy: rAndS.distribution)
        if range.lowerBound <= overloadPeriod {
            return true
        } else {
            return false
        }
    }
}

enum SetStructures: String, CaseIterable, Codable, Identifiable {
    case pyramid = "Pyramid" // default: start with lowest weight and increase per set
    case reversePyramid = "Reverse Pyramid" // start with highest weight and decrease per set
    case fixed = "Fixed" // same weight and reps across all sets
    
    var id: String { self.rawValue }
    
    var desc: String {
        switch self {
        case .pyramid:
            return "Start with lighter weight and higher reps, increasing weight while decreasing reps for each subsequent set."
        case .reversePyramid:
            return "Start with heavier weight and lower reps, decreasing weight while increasing reps for each subsequent set."
        case .fixed:
            return "Same weight and reps across all sets."
        }
    }
}

struct SupersetSettings: Codable, Hashable {
    var enabled: Bool = false
    var equipmentOption: SupersetEquipmentOption = .sameEquipment
    var muscleOption: SupersetMuscleOption = .anyMuscle
    var ratio: Int = 30 // pct of exercises that can be supersetted
    
    var summary: String {
        guard enabled else { return "Disabled" }
        return "\(ratio)%"
    }
}

enum SupersetEquipmentOption: String, CaseIterable, Codable {
    case sameEquipment = "Same Equipment"
    case anyEquipment = "Any Equipment"
    
    var description: String {
        switch self {
        case .sameEquipment: "Supersetted exercises must use the same equipment."
        case .anyEquipment: "Supersetted exercises can use any equipment."
        }
    }
}

enum SupersetMuscleOption: String, CaseIterable, Codable {
    case sameMuscle = "Same Muscle"
    case relatedMuscle = "Related Muscle"
    case anyMuscle = "Any Muscle"
    
    var description: String {
        switch self {
        case .sameMuscle: "Supersetted exercises target the same muscle group."
        case .relatedMuscle: "Supersetted exercises target related muscle groups."
        case .anyMuscle: "Supersetted exercises can target any muscle group."
        }
    }
}
/*
struct OverloadSettings: Codable, Hashable {
    var progressiveOverload: Bool = true
    var progressiveOverloadPeriod: Int = 6 // Default to 6 weeks
    var progressiveOverloadStyle: ProgressiveOverloadStyle = .dynamic // Default style
    var customOverloadFactor: Double?
}

struct DeloadSettings: Codable, Hashable {
    var allowDeloading: Bool = true
    var deloadIntensity: Int = 85
    var periodUntilDeload: Int = 4
}

struct ExerciseSortSettings: Codable, Hashable {
    var enableSortPicker: Bool = true // disable ExerciseSortOptions picker
    var saveSelectedSort: Bool = false // save selections as new exerciseSortOption
    var sortByTemplateCategories: Bool = true // sort by template categories when editing a template with categories
    var hideUnequippedExercises: Bool = false // hide exercises that the user DOES NOT have equipment for in exercise selection or or exercise view
    var hideDifficultExercises: Bool = false // hide exercises that would be too difficult for the user
    var hideDislikedExercises: Bool = false // hide exercises that the user has disliked
}

struct SetDisplaySettings: Codable, Hashable {
    var restTimerEnabled: Bool = true
    var hideRpeSlider: Bool = false
    var hideCompletedInput: Bool = false
    var hideExerciseImage: Bool = false
}
*/

struct SetIntensitySettings: Codable, Hashable {
    var minIntensity: Int = 70
    var maxIntensity: Int = 90
    var fixedIntensity: Int = 80
    var topSet: TopSetOption = .lastSet
    
    func summary(setStructure: SetStructures) -> String {
        if setStructure == .fixed || topSet == .allSets {
            return "\(fixedIntensity)%"
        } else {
            return "\(minIntensity)%-\(maxIntensity)%"
        }
    }
}

struct WarmupSettings: Codable, Hashable {
    var includeSets: Bool = false // include warmup sets in workout generation
    var minIntensity: Int = 50
    var maxIntensity: Int = 75
    var setCountModifier: WarmupSetCountModifier = .oneHalf
    var exerciseSelection: WarmupExerciseSelection = .compoundWeighted
    
    func summary(setDistribution: SetDistribution, effortDistribution: EffortDistribution) -> String {
        guard self.includeSets else { return "None" }
        
        let range = setDistribution.overallRange(filteredBy: effortDistribution)
        let minWarmupSets = self.setCountModifier.warmupSetCount(for: range.lowerBound)
        let maxWarmupSets = self.setCountModifier.warmupSetCount(for: range.upperBound)
        
        return Format.formatRange(range: minWarmupSets...maxWarmupSets)
    }
}

enum WarmupSetCountModifier: String, Codable, Equatable, CaseIterable {
    case oneQuarter = "1/4"
    case oneHalf = "1/2"
    case threeQuarters = "3/4"
    case oneToOne = "1/1"
    
    var displayName: String { rawValue }
    
    var fraction: Double {
        switch self {
        case .oneQuarter: return 0.25
        case .oneHalf: return 0.5
        case .threeQuarters: return 0.75
        case .oneToOne: return 1.0
        }
    }
    
    /// Calculate the number of warmup sets based on working set count
    func warmupSetCount(for workingSets: Int) -> Int {
        max(1, Int(round(Double(workingSets) * fraction)))
    }
}

enum WarmupExerciseSelection: String, Codable, Equatable, CaseIterable {
    case compoundWeighted = "Compound Weighted"
    case allWeighted = "All Weighted"
    
    var description: String {
        switch self {
        case .compoundWeighted: "Only compound weighted rep-based exercises will include warmup sets."
        case .allWeighted: "All weighted rep-based exercises will include warmup sets."
        }
    }
    
    func isCompatible(exercise: Exercise) -> Bool {
        guard exercise.allowedWarmup else { return false }
        switch self {
        case .compoundWeighted: return exercise.effort == .compound
        case .allWeighted: return true
        }
    }
}
