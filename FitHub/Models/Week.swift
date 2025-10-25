//
//  Week.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI


struct WorkoutWeek: Identifiable, Codable, Equatable {
    var id = UUID()
    var categories: [[SplitCategory]]
    
    static func createSplit(forDays days: Int) -> WorkoutWeek {
        var workoutWeek = WorkoutWeek(categories: [])
        
        switch days {
        case 2:
            workoutWeek.categories = Array(repeating: [.all], count: 2)
        case 3: // Full body workouts
            workoutWeek.categories = Array(repeating: [.all], count: 3)
        case 4: // Upper/Lower split
            workoutWeek.categories = [
                [.chest, .triceps, .shoulders], // Index 0
                [.legs, .quads],                // Index 2
                [.back, .biceps, .shoulders],   // Index 1
                [.legs, .glutes, .hamstrings]   // Index 3
            ]
        case 5: // Upper/Lower/Push/Pull/Legs
            workoutWeek.categories = [
                [.chest, .back, .biceps],       // Index 0 - Upper Body
                [.legs, .quads, .hamstrings],   // Index 1 - Lower Body
                [.chest, .triceps, .shoulders], // Index 2 - Push
                [.back, .biceps],               // Index 3 - Pull
                [.legs, .shoulders]             // Index 4 - Legs & Abs
            ]
        case 6: // Push/Pull/Legs repeated
            workoutWeek.categories = [
                [.chest, .triceps, .shoulders], // Index 0
                [.back, .biceps],               // Index 1
                [.legs, .quads],                // Index 2
                [.chest, .triceps, .shoulders], // Index 3
                [.back, .biceps],               // Index 4
                [.legs, .hamstrings]            // Index 5
            ]
        default:
            // Rest or custom split, use a sensible default or empty
            workoutWeek.categories = Array(repeating: [.all], count: days)
        }
        
        return workoutWeek
    }
    
    func categoryForDay(index: Int) -> [SplitCategory] {
        // Ensure we loop around if the index exceeds the length of the categories array
        if categories.isEmpty { return [] }
        return categories[index % categories.count]
    }
    
    static func determineSplit(customSplit: WorkoutWeek?, daysPerWeek: Int) -> WorkoutWeek {
        let defaultSplit = WorkoutWeek.createSplit(forDays: daysPerWeek)
        guard let customSplit else { return defaultSplit }
        if customSplit.categories.count != daysPerWeek || customSplit.categories.contains(where: { $0.isEmpty }) {
            return defaultSplit
        } else {
            return customSplit
        }
    }
}


enum DaysOfWeek: String, CaseIterable, Codable, Comparable, Equatable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    // Explicitly define the order of the week days
    static let orderedDays: [DaysOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    
    static func < (lhs: DaysOfWeek, rhs: DaysOfWeek) -> Bool {
        guard let lIdx = orderedDays.firstIndex(of: lhs), let rIdx = orderedDays.firstIndex(of: rhs)
        else { return false }
        return lIdx < rIdx
    }
    
    static func defaultDays(for workoutDaysPerWeek: Int) -> [DaysOfWeek] {
        switch workoutDaysPerWeek {
        case 2:
            return [.monday, .friday]
        case 3:
            return [.monday, .wednesday, .friday]  // Typical three-day split
        case 4:
            return [.monday, .tuesday, .thursday, .friday]  // Typical four-day split
        case 5:
            return [.monday, .tuesday, .wednesday, .thursday, .friday]  // Typical five-day split
        case 6:
            return [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]  // Typical six-day split
        default:
            // Default to the number of days evenly distributed
            return Array(orderedDays.prefix(workoutDaysPerWeek))
        }
    }
    
    static func getWorkoutDayIndexes(for frequency: Int) -> [Int] {
        // Default days calculation based on frequency
        switch frequency {
        case 2:
            return [0, 4]
        case 3:
            return [0, 2, 4]  // Monday, Wednesday, Friday
        case 4:
            return [0, 1, 3, 4]  // Monday, Tuesday, Thursday, Friday
        case 5:
            return [0, 1, 2, 3, 4]  // Monday to Friday
        case 6:
            return [0, 1, 2, 3, 4, 5]  // Monday to Saturday
        default:
            return []
        }
    }
    
    static func calculateWorkoutDayIndexes(customWorkoutDays: [DaysOfWeek]?, workoutDaysPerWeek: Int) -> [Int] {
        if let customDays = customWorkoutDays, !customDays.isEmpty {
            // Use custom workout days if they are set
            return customDays.compactMap { DaysOfWeek.orderedDays.firstIndex(of: $0) }
        } else {
            // Fallback to default indexes if no custom days are set
            return getWorkoutDayIndexes(for: workoutDaysPerWeek)
        }
    }
    
    static func resolvedWorkoutDays(customWorkoutDays: [DaysOfWeek]?, workoutDaysPerWeek: Int) -> [DaysOfWeek] {
        // ❶ Start with any custom days the user already chose
        var result = (customWorkoutDays ?? [])
            .uniqued()            // remove accidental duplicates while preserving order
            .sorted()             // Monday→Sunday, thanks to Comparable conformance
        
        // ❷ If the user picked fewer days than the new frequency,
        //    append defaults until we hit the target
        if result.count < workoutDaysPerWeek {
            for day in defaultDays(for: workoutDaysPerWeek) where !result.contains(day) {
                result.append(day)
                if result.count == workoutDaysPerWeek { break }
            }
        }
        
        // ❸ If they picked more days than the new frequency,
        //    keep the first *n* days in week order
        if result.count > workoutDaysPerWeek {
            result = Array(result.prefix(workoutDaysPerWeek))
        }
        
        // ❹ Final guarantee: sorted & sized correctly
        return result.sorted()
    }
    
    /// Returns a single `Text` containing all day short-names, comma-separated and bold.
    static func dayListText(_ days: [DaysOfWeek]) -> Text {
        let pieces = days
            .sorted() // keep a stable order (Mon…Sun)
            .map { Text($0.shortName).bold() }

        // stitch `Text` values together with “, ” separators
        return pieces.enumerated().reduce(Text("")) { acc, elem in
            let (idx, txt) = elem
            let sep = idx < pieces.count - 1 ? Text(", ") : Text("")
            return acc + txt + sep
        }
    }
}

/*
struct WorkoutSchedule: Codable {
    var customWorkoutTimes: [DaysOfWeek: DateComponents] = [:]
    var customWorkoutDays: [DaysOfWeek]? // Optional array to store custom days of the week
    var workoutDaysPerWeek: Int = 3 // days per week user wants to work out
    var customWorkoutSplit: WorkoutWeek? // Optional custom split, overrides default logic based on days per week
    
    // Helper to get workout time for a specific day
    func workoutTime(for day: DaysOfWeek) -> DateComponents? {
        return customWorkoutTimes[day]
    }
    
    // Helper to check if a day has a scheduled workout
    func hasWorkoutScheduled(for day: DaysOfWeek) -> Bool {
        return customWorkoutTimes[day] != nil
    }
    
    // Helper to get all scheduled workout days
    var scheduledDays: [DaysOfWeek] { return Array(customWorkoutTimes.keys) }
}
*/
