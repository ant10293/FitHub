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
    var gender: Gender = .notSet
    var avgSteps: Int = 0
    var activityLevel: ActivityLevel = .select
    var goal: FitnessGoal = .getStronger
    var carbs: Double = 0.0
    var fats: Double = 0.0
    var proteins: Double = 0.0
    var height: Length = .init(cm: 0)
    var currentMeasurements: [MeasurementType: Measurement] = [:]
    var pastMeasurements: [MeasurementType: [Measurement]] = [:]
}

//  workoutPrefs     = WorkoutPreferences()
struct WorkoutPreferences: Codable, Equatable {
    var customSets: SetDistribution?
    var customRepsRange: RepDistribution?
    var customWorkoutDays: [DaysOfWeek]? // Optional array to store custom days of the week
    var customWorkoutTimes: WorkoutTimes?
    var customWorkoutSplit: WorkoutWeek? // Optional custom split, overrides default logic based on days per week
    var customRestPeriods: RestPeriods?
    var workoutDaysPerWeek: Int = 3 // days per week user wants to work out
    var keepCurrentExercises: Bool = false
    //var withPerformanceData: Bool = true // only use exercises with performance data when creating workouts
    var ResistanceType: ResistanceType = .any
    var setStructure: SetStructures = .pyramid
    var customDuration: Int? /// minutes
    var customDistribution: ExerciseDistribution?
    //var supersetSettings: SupersetSettings = SupersetSettings()
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
    var allowedCredentials: Bool = false
    var progressiveOverload: Bool = true
    var allowDeloading: Bool = true
    var userLanguage: Languages = .english
    var selectedTheme: Themes = .defaultMode // Default style
    var roundingPreference: RoundingPreference = RoundingPreference()
    var stagnationPeriod: Int = 4 // Default to 4 weeks
    var progressiveOverloadPeriod: Int = 6 // Default to 6 weeks
    var progressiveOverloadStyle: ProgressiveOverloadStyle = .dynamic // Default style
    var muscleRestDuration: Int = 48 // Default to 48 hours
    var deloadIntensity: Int = 85
    var customOverloadFactor: Double?
    var periodUntilDeload: Int = 2
    var useDateOnly: Bool = true // If true, only the date is considered
    var notifyBeforePlannedTime: Bool = true // If true, notify before planned time; otherwise, notify at the beginning of the day
    var notifications: Notifications = Notifications()
    var defaultWorkoutTime: DateComponents?  // Default workout time, [.hour, .minute]
    var enableSortPicker: Bool = true // disable ExerciseSortOptions picker
    var saveSelectedSort: Bool = false // save selections as new exerciseSortOption
    var sortByTemplateCategories: Bool = true // sort by template categories when editing a template with categories
    var hideUnequippedExercises: Bool = false // hide exercises that the user DOES NOT have equipment for in exercise selection or or exercise view
    var hideDifficultExercises: Bool = false // hide exercises that would be too difficult for the user
    var hideDislikedExercises: Bool = false // hide exercises that the user has disliked
    var hiddenExercises: Set<UUID> = []
    var hideRpeSlider: Bool = false // TODO: Implement
    //var monthlyStrengthUpdate: Bool = true
    // var hideCompletedInput: Bool = false
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
    var equipmentSelected: [UUID] = []
    var favoriteExercises: Set<UUID> = []
    var dislikedExercises: Set<UUID> = []
    var availablePlates: WeightPlates = WeightPlates()
}

// sessionTracking  = SessionTracking()
struct SessionTracking: Codable, Equatable {
    var totalNumWorkouts: Int = 0
    var workoutStreak: Int = 0
    var longestWorkoutStreak: Int = 0
    var selectedView: GraphView = .exercisePerformance
    var selectedExercise: UUID?
    var selectedMeasurement: MeasurementType = .weight
    var activeWorkout: WorkoutInProgress?
    var exerciseSortOption: ExerciseSortOption = .moderate
}

// workoutPlans     = WorkoutPlans()
struct WorkoutPlans: Codable, Equatable {
    var userTemplates: [WorkoutTemplate] = []
    var trainerTemplates: [WorkoutTemplate] = []
    var archivedTemplates: [WorkoutTemplate] = []
    var workoutsCreationDate: Date?
    var workoutsStartDate: Date?
    var logFileName: String?      // ← replace old logFileUrl
    var logFileURL: URL? { logFileName.map { Logger.url(for: $0) } }
    var generatedWeeksWorkout: Bool = false // TODO: remove
    var completedWorkouts: [CompletedWorkout] = []
}
