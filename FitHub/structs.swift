import Foundation
import SwiftUI

struct SelectedTemplate {
    var id: UUID
    var name: String
    var index: Int
    var isUserTemplate: Bool
}

struct CurrentExerciseState: Codable {
    var id: UUID
    var name: String
    var index: Int
    var startTime: Int
}

struct RepsXWeight: Codable, Hashable {
    var reps: Int
    var weight: Double
}

struct PerformanceUpdate: Codable, Hashable {
    var exerciseName: String
    var value: Double
    var repsXweight: RepsXWeight?
    var setNumber: Int?
}

// the saved max value is the max reps or the calculated one rep max (in most cases, because you still can enter a one rep max value)
struct MaxRecord: Codable, Identifiable {
    var id: UUID = UUID() // Unique identifier for each record
    var value: Double     // The max value (could be one-rep max weight or number of reps as double for consistency)
    var repsXweight: RepsXWeight?
    var date: Date        // Date when the record was set
}

struct ExercisePerformance: Identifiable, Codable {
    var id: String // Using the exercise name as the identifier
    var maxValue: Double?
    var repsXweight: RepsXWeight?
    var estimatedValue: Double?
    var currentMaxDate: Date?
    var pastMaxes: [MaxRecord]?
    
    init(name: String) {
        self.id = name
    }
}

// Helper method to get reps and sets based on the user's goal
struct RepsAndSets {
    var repsRange: ClosedRange<Int>
    var sets: Int
    var restPeriod: Int  // Seconds of rest between sets
    
    static func determineRepsAndSets(customRestPeriod: Int?, goal: FitnessGoal, customRepsRange: ClosedRange<Int>?, customSets: Int?) -> RepsAndSets {
        let restPeriod = customRestPeriod ?? FitnessGoal.determineRestPeriod(for: goal)
        let repsAndSets = customRepsRange != nil && customSets != nil
        ? RepsAndSets(repsRange: customRepsRange!, sets: customSets!, restPeriod: restPeriod)
        : FitnessGoal.getRepsAndSets(for: goal, restPeriod: restPeriod)
        
        return repsAndSets
    }
}

struct SubMuscleEngagement: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let submuscleWorked: SubMuscles
    let engagementPercentage: Double
}


struct MuscleEngagement:  Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let muscleWorked: Muscle
    let engagementPercentage: Double
    let isPrimary: Bool
    let submusclesWorked: [SubMuscleEngagement]?
}
extension MuscleEngagement {
    /// Returns a list of SubMuscles for the muscle engagement, or an empty array if `submusclesWorked` is nil.
    var allSubMuscles: [SubMuscles] {
        submusclesWorked?.map { $0.submuscleWorked } ?? []
    }
}

struct ExerciseEquipmentAdjustments: Codable, Identifiable, Equatable, Hashable {
    var id: String // Using the exercise name as the identifier
    var exercise: String
    var equipmentAdjustments: [AdjustmentCategories: AdjustmentValue]
    let adjustmentImage: String
    
    static func ==(lhs: ExerciseEquipmentAdjustments, rhs: ExerciseEquipmentAdjustments) -> Bool {
        return lhs.id == rhs.id &&
        lhs.exercise == rhs.exercise &&
        lhs.equipmentAdjustments == rhs.equipmentAdjustments &&
        lhs.adjustmentImage == rhs.adjustmentImage
    }
}

struct Exercise: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var currentSet: Int = 1
    var isCompleted: Bool = false
    let name: String
    var aliases: [String]?
    let image: String
    var warmUpDetails: [SetDetail] = []
    var setDetails: [SetDetail] = []
    var allSetDetails: [SetDetail] { warmUpDetails + setDetails }
    var warmUpSets: Int { warmUpDetails.count }
    var sets: Int { setDetails.count }
    var totalSets: Int { warmUpSets + sets }
    var groupCategory: SplitCategory?
    var splitCategory: SplitCategory
    let muscles: [MuscleEngagement]
    var exDesc: String
    var equipmentRequired: [EquipmentName]
    var alternativeEquipmentMapping: [EquipmentName: [EquipmentName]]? // Dictionary mapping required to optional alternative
    var exDistinction: ExerciseDistinction
    let url: String
    let usesWeight: Bool
    var oneRepMax: Double?
    var maxReps: Int?
    var equipmentAdjustments: ExerciseEquipmentAdjustments?
    var difficulty: ExerciseDifficulty
    var isSupersettedWith: String?  // Track the superset exercise
    var limbMovementType: LimbMovementType?
    var repsInstruction: String?
    var weightInstruction: String?
    var weeksStagnated: Int = 0
    var manualOverloading: Bool = false
    var overloadProgress: Int = 0
    var timeSpent: Int = 0
    var fullImagePath: String { return "Exercises/\(image)" }
}
extension Exercise {
    /// Returns an array of MuscleEngagement for the prime movers.
    var primaryMuscleEngagements: [MuscleEngagement] {
        muscles.filter { $0.isPrimary }
    }
    
    /// Returns an array of MuscleEngagement for the assisting muscles.
    var secondaryMuscleEngagements: [MuscleEngagement] {
        muscles.filter { !$0.isPrimary }
    }
    
    /// Returns just the `Muscle` enums for the prime movers.
    var primaryMuscles: [Muscle] {
        primaryMuscleEngagements.map { $0.muscleWorked }
    }
    
    /// Returns just the `Muscle` enums for the secondary muscles.
    var secondaryMuscles: [Muscle] {
        secondaryMuscleEngagements.map { $0.muscleWorked }
    }
    
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
    var allMuscles: [Muscle] {
        muscles.map { $0.muscleWorked }
    }
    
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


struct SetDetail: Identifiable, Hashable, Codable {
    var id = UUID()
    var setNumber: Int
    var weight: Double
    var reps: Int
    var repsCompleted: Int?
    var restPeriod: Int?
    
    mutating func updateCompletedReps(repsCompleted: Int, maxReps: Int) -> (newMaxReps: Int?, updated: Bool) {
        self.repsCompleted = repsCompleted
        
        if repsCompleted > maxReps {
            print("New Max Reps:", repsCompleted)
            print("Current Max Reps:", maxReps)
            
            return (newMaxReps: repsCompleted, updated: true)
        } else {
            return (newMaxReps: nil, updated: false)
        }
    }
    
    mutating func updateCompletedRepsAndRecalculate(repsCompleted: Int, oneRepMax: Double) -> (new1RM: Double?, updated: Bool) {
        self.repsCompleted = repsCompleted
        
        if repsCompleted != 0 {
            if let new1RM = recalculate1RM(oneRepMax: oneRepMax) {
                return (new1RM: new1RM, updated: true)
            } else {
                return (new1RM: nil, updated: false) // No change in 1RM.
            }
        } else {
            return (new1RM: nil, updated: false)
        }
    }
    
    // modify for consistency
    private mutating func recalculate1RM(oneRepMax: Double) -> Double? {
        guard let repsCompleted = repsCompleted, repsCompleted > 0 else { return nil }
        let new1RM = weight / (1.0278 - 0.0278 * Double(repsCompleted))
        if new1RM <= oneRepMax {
            print("new 1rm: \(new1RM) is not greater than current 1rm of \(oneRepMax)")
            return nil
        }
        print("New 1RM calculated: \(new1RM)")
        
        return new1RM
    }
    
    mutating func calculateWeight(oneRepMax: Double) {
        self.weight = SetDetail.calculateWeight(oneRepMax: oneRepMax, reps: self.reps)
    }
    
    mutating func calculateReps(maxReps: Int, setStructure: SetStructures, numSets: Int) {
        self.reps = SetDetail.calculateReps(maxReps: maxReps, setNumber: setNumber, setStructure: setStructure, numSets: numSets)
    }
    
    static func calculateWeight(oneRepMax: Double, reps: Int) -> Double {
        let percentage: Double
        switch reps {
        case 1:
            percentage = 1.00
        case 2:
            percentage = 0.95
        case 3:
            percentage = 0.93
        case 4:
            percentage = 0.90
        case 5:
            percentage = 0.87
        case 6:
            percentage = 0.85
        case 7:
            percentage = 0.83
        case 8:
            percentage = 0.80
        case 9:
            percentage = 0.77
        case 10:
            percentage = 0.75
        case 11:
            percentage = 0.73
        case 12:
            percentage = 0.70
        case 13:
            percentage = 0.68
        case 14:
            percentage = 0.66
        default:
            percentage = 0.65 // For reps more than 12, use 65% as a safe estimate
        }
        return oneRepMax * percentage
    }
    
    static func calculateReps(maxReps: Int, setNumber: Int, setStructure: SetStructures, numSets: Int) -> Int {
        switch setStructure {
        case .pyramid:
            let minReps = Int(Double(maxReps) * 0.8)
            let incrementPerSet = (maxReps - minReps) / max(1, numSets - 1)
            let calculatedReps = (minReps + incrementPerSet * (setNumber - 1)) + 1
            return min(maxReps, calculatedReps) // Ensure it doesn't exceed maxReps
            
        case .reversePyramid:
            // Start with max reps and decrease progressively
            let decreasePerSet = max(1, Int(0.1 * Double(maxReps)))
            let calculatedReps = max(1, maxReps - decreasePerSet * (setNumber - 1))
            return calculatedReps
            
        case .fixed:
            // Use 95% of the max reps for all sets
            return Int(Double(maxReps) * 0.95)
        }
    }
}

struct GymEquipment: Identifiable, Codable {
    var id: UUID = UUID()
    var name: EquipmentName
    var alternativeEquipment: [EquipmentName]?
    var image: String
    var isSelected: Bool
    var equCategory: EquipmentCategory // Ensure this includes a case for "All"
    var adjustments: [AdjustmentCategories]?
    var baseWeight: Int?
    var description: String
    var fullImagePath: String {
        return "Equipment/\(image)"
    }
}

struct Measurement: Codable, Identifiable {
    var id: UUID = UUID()
    let type: MeasurementType
    let value: Double
    let date: Date
}


struct WorkoutTemplate: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var exercises: [Exercise] // Define Exercise as per your app's needs
    var categories: [SplitCategory]
    var dayIndex: Int?
    var date: Date?
    var notificationIDs: [String] = [] // Store notification identifiers for removal
    var estimatedCompletionTime: Int?
    
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
            let difficultyValue = ExerciseDifficulty.getDifficultyValue(for: exercise.difficulty)
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
}

struct CompletedWorkout: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var template: WorkoutTemplate
    var updatedMax: [PerformanceUpdate]
    var duration: Int
    var date: Date
}

struct WorkoutInProgress: Codable {
    var template: WorkoutTemplate
    var elapsedTime: Int
    var currentExerciseState: CurrentExerciseState?
    var dateStarted: Date
    var exercises: [Exercise]
    var updatedMax: [PerformanceUpdate]
}

struct WorkoutWeek: Identifiable, Codable {
    var id = UUID()
    var categories: [[SplitCategory]]
    
    static func createSplit(forDays days: Int) -> WorkoutWeek {
        var workoutWeek = WorkoutWeek(categories: [])
        
        switch days {
        case 3: // Full body workouts
            workoutWeek.categories = [
                [.all], // Index 0
                [.all], // Index 1
                [.all]  // Index 2
            ]
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
            workoutWeek.categories = []
        }
        
        return workoutWeek
    }
    
    func categoryForDay(index: Int) -> [SplitCategory] {
        // Ensure we loop around if the index exceeds the length of the categories array
        if categories.isEmpty {
            return []
        }
        return categories[index % categories.count]
    }
    
    mutating func setCategoriesForDay(index: Int, categories: [SplitCategory]) {
        if index < self.categories.count {
            self.categories[index] = categories
        } else {
            // Handle error or dynamically adjust the array size
        }
    }
}

