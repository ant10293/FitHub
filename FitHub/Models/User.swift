//
//  User.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/11/25.
//

import Foundation

// profile          = Profile()          // ← your new structs
struct Profile: Codable, Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var userId: String = ""
    var accountCreationDate: Date?
    var userName: String = ""
    var age: Int = 0
    var dob: Date = Date()
}

// physical         = PhysicalStats()
struct PhysicalStats: Codable {
    var gender: Gender = .male
    var avgSteps: Int = 0
    var activityLevel: ActivityLevel = .select
    var goal: FitnessGoal = .getStronger
    var carbs: Double = 0.0
    var fats: Double = 0.0
    var proteins: Double = 0.0
    var heightInches: Int = 0
    var heightFeet: Int = 0
    var currentMeasurements: [MeasurementType: Measurement] = [:]
    var pastMeasurements: [MeasurementType: [Measurement]] = [:]
}

//  workoutPrefs     = WorkoutPreferences()
struct WorkoutPreferences: Codable, Equatable {
    var customSets: Int? // Optional to override default sets
    var customRepsRange: ClosedRange<Int>? // Optional to override default reps range
    var customWorkoutDays: [daysOfWeek]? // Optional array to store custom days of the week
    var customWorkoutSplit: WorkoutWeek? // Optional custom split, overrides default logic based on days per week
    var customRestPeriod: Int?
    var workoutDaysPerWeek: Int = 0 // days per week user wants to work out
    var keepCurrentExercises: Bool = false
    var ResistanceType: ResistanceType = .any
    var setStructure: SetStructures = .pyramid
}

// setup            = Setup()
struct Setup: Codable {
    var setupState: SetupState = .welcomeView
    var isEquipmentSelected: Bool = false
    var questionAnswers: [String] = []
    var questionsAnswered: Bool = false
    var infoCollected: Bool = false
    var maxRepsEntered: Bool = false
    var oneRepMaxesEntered: Bool = false
}

// settings         = Settings()
struct Settings: Codable, Equatable {
    var restTimerEnabled: Bool = true
    var allowedNotifications: Bool = false
    //var allowedHKPermission: Bool = false
    var allowedCredentials: Bool = false
    var progressiveOverload: Bool = true
    var allowDeloading: Bool = true
    var userLanguage: Languages = .english
    var selectedTheme: Themes = .defaultMode // Default style
    var measurementUnit: UnitOfMeasurement = .imperial
    var roundingPreference: RoundingPreference = RoundingPreference()
    var stagnationPeriod: Int = 4 // Default to 4 weeks
    var progressiveOverloadPeriod: Int = 6 // Default to 6 weeks
    var progressiveOverloadStyle: ProgressiveOverloadStyle = .dynamic // Default style
    var muscleRestDuration: Int = 48 // Default to 48 hours
    var deloadIntensity: Int = 85
    var periodUntilDeload: Int = 2
    var useDateOnly: Bool = true // If true, only the date is considered
    var notifyBeforePlannedTime: Bool = true // If true, notify before planned time; otherwise, notify at the beginning of the day
    var notificationIntervals: [TimeInterval] = [] // Array of time intervals in seconds for notifications
    var notificationTimes: [DateComponents] = [] // 11 AM, 18 PM, etc.  The `.year/.month/.day` components stay nil.
    var defaultWorkoutTime: Date?  // Default workout time, initialized to the current time
    var enableSortPicker: Bool = true // disable ExerciseSortOptions picker
    var saveSelectedSort: Bool = false // save selections as new exerciseSortOption
    var sortByTemplateCategories: Bool = false // sort by template categories when editing a template with categories
    var hideUnequippedExercises: Bool = false // hide exercises that the user DOES NOT have equipment for in exercise selection or or exercise view
    var hideDifficultExercises: Bool = false // hide exercises that would be too difficult for the user
    var hideDislikedExercises: Bool = false // hide exercises that the user has disliked
    var hiddenExercises: [UUID] = []
}

// evaluation       = Evaluation()
struct Evaluation: Codable {
    var fitnessScore: Int = 0
    var strengthLevel: StrengthLevel = .beginner
    var determineStrengthLevelDate: Date?
    var strengthPercentile: Int = 0
    var isFamiliarWithGym: Bool = false // change this after certain number of completed workouts, or allow manual change
    var strengths: [Muscle: StrengthLevel]?
    var weaknesses: [Muscle: StrengthLevel]?
    var equipmentSelected: [GymEquipment] = []
    var favoriteExercises: [UUID] = []
    var dislikedExercises: [UUID] = []
}

// sessionTracking  = SessionTracking()
struct SessionTracking: Codable, Equatable {
    var totalNumWorkouts: Int = 0
    var workoutStreak: Int = 0
    var longestWorkoutStreak: Int = 0
    var selectedView: GraphView = .exercisePerformance
    //var selectedExercise: String = "Bench Press"
    var selectedExercise: UUID?
    var selectedMeasurement: MeasurementType = .weight
    var activeWorkout: WorkoutInProgress?
    var exerciseSortOption: ExerciseSortOption = .simple
}

// workoutPlans     = WorkoutPlans()
struct WorkoutPlans: Codable {
    var userTemplates: [WorkoutTemplate] = []
    var trainerTemplates: [WorkoutTemplate] = []
    var archivedTemplates: [WorkoutTemplate] = []
    var workoutsCreationDate: Date?
    var workoutsStartDate: Date?
    var logFileName: String?      // ← replace old logFileUrl
    var logFileURL: URL? { logFileName.map { Logger.url(for: $0) } }
    var generatedWeeksWorkout: Bool = false
    var completedWorkouts: [CompletedWorkout] = []
}
