//
//  Workout.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


struct SelectedTemplate {
    var id: UUID
    var name: String
    var index: Int
    var isUserTemplate: Bool
}

struct WorkoutTemplate: Identifiable, Hashable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var exercises: [Exercise] // Define Exercise as per your app's needs
    var categories: [SplitCategory]
    var dayIndex: Int?
    var date: Date?
    var notificationIDs: [String] = [] // Store notification identifiers for removal
    var estimatedCompletionTime: Int?
}

extension WorkoutTemplate {
    static func estimateCompletionTime(for template: WorkoutTemplate, completedWorkouts: [CompletedWorkout]) -> Int {
        // Constants for estimating time
        let timePerRep = 3 // Average time per rep in seconds
        let timePerExerciseSetup = 120 // Time to set up for each exercise in seconds
        let additionalTimePerDifficultyLevel = 10 // Additional seconds for complex exercises
        
        // Start with total time as 0
        var totalTime = 0
        
        for exercise in template.exercises {
            // Base time: Sets × Reps × Time Per Rep
            let repsPerSet = exercise.setDetails.map { $0.reps }.reduce(0, +)
            let baseTime = repsPerSet * timePerRep
            
            // Rest time: Rest Period × (Sets - 1) [Rest between sets only]
            let restTime = (exercise.setDetails.first?.restPeriod ?? 0) * (exercise.setDetails.count - 1)
            
            // Difficulty adjustment
            let difficultyValue = exercise.difficulty.strengthValue
            let difficultyTime = additionalTimePerDifficultyLevel * difficultyValue
            
            // Setup time per exercise
            totalTime += baseTime + restTime + difficultyTime + timePerExerciseSetup
        }
        // Historical adjustment: average completion time of similar past workouts
        let pastDurations = completedWorkouts.filter {
            $0.name == template.name && $0.template.categories == template.categories
        }.map { $0.duration }
        
        if let avgPastDuration = pastDurations.average {
            totalTime = Int(Double(totalTime) * 0.2 + Double(avgPastDuration) * 0.8) // 80% historical, 20% estimation
        } else {
            // If no exact matches, find workouts with similar categories
            let templateCategories = Set(template.categories)
            let similarWorkouts = completedWorkouts.filter {
                let workoutCategories = Set($0.template.categories)
                let commonCategories = templateCategories.intersection(workoutCategories)
                return !commonCategories.isEmpty
            }
            let similarDurations = similarWorkouts.map { $0.duration }
            if let avgSimilarDuration = similarDurations.average {
                totalTime = Int(Double(totalTime) * 0.8 + Double(avgSimilarDuration) * 0.2) // 80% estimation, 20% historical
            }
        }
        return totalTime
    }
    // Helper method to determine the number of exercises per workout
    static func determineExercisesPerWorkout(basedOn age: Int, frequency: Int, strengthLevel: StrengthLevel) -> Int {
        let baseCount = 5 // Base number of exercises per workout
        var modifier = 0
        
        // Modifier based on age
        if age < 30 {
            modifier += 2 // Younger individuals might handle more exercises
        } else if age > 50 {
            modifier -= 1 // Older individuals might need fewer exercises
        }
        
        // Modifier based on workout frequency
        switch frequency {
        case 3...4:
            modifier += 1
        case 5...6:
            modifier += 2
        default:
            break
        }
        
        // Modifier based on fitness score
        switch strengthLevel {
            case .beginner:
                modifier -= 2 // Fewer exercises for beginners
            case .novice:
                modifier -= 1
            case .intermediate:
                // No additional modifier for intermediates
                break
            case .advanced:
                modifier += 1
            case .elite:
                modifier += 2 // More exercises for advanced users
        }
        
        return max(1, baseCount + modifier) // Ensure at least one exercise per workout
    }
    
    static func shouldDisableTemplate(template: WorkoutTemplate) -> Bool {
        var shouldDisable: Bool = false
        
        if template.exercises.isEmpty {
            shouldDisable = true
        } else {
            for exercise in template.exercises {
                if exercise.setDetails.isEmpty {
                    shouldDisable = true
                    break
                }
            }
        }
        return shouldDisable
    }
    
    // List of names of exercises already in the template for quick lookup
    var exerciseNames: Set<String> { Set(exercises.map { $0.name }) }
    
    var numExercises: Int { exercises.count }
}

struct CompletedWorkout: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var template: WorkoutTemplate
    var updatedMax: [PerformanceUpdate]
    var duration: Int
    var date: Date
}

struct WorkoutInProgress: Codable, Equatable {
    var template: WorkoutTemplate
    var elapsedTime: Int
    var currentExerciseState: CurrentExerciseState?
    var dateStarted: Date
    var updatedMax: [PerformanceUpdate]
}

struct TemplateProgress {
    let exerciseIdx: Int
    let numExercises: Int
    let isLastExercise: Bool
    let restTimerEnabled: Bool
    let restPeriod: Int
}

struct WorkoutSummaryData {
    let totalVolume: Double
    let totalWeight: Double
    let totalReps: Int
    let totalTime: String
    let exercisePRs: [String]
}
