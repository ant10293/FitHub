//
//  Settings.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


enum Gender: Hashable, Codable { case male, female, notSet }

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
