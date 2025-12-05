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
    var age: Int = 0
    var dob: Date?
    var accountCreationDate: Date?
    var referralCode: String?
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
    // TODO: should be a single dict, not current & past
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
    var paramsBeforeSwitch: ParamsBeforeSwitch?
    //var withPerformanceData: Bool = true // only use exercises with performance data when creating workouts
    var resistance: ResistanceType = .any
    var setStructure: SetStructures = .pyramid
    var customDuration: TimeSpan?
    var customDistribution: EffortDistribution?
    //var supersetSettings: SupersetSettings = SupersetSettings()
    var maxBwRepCapMultiplier: Double = 2.0 // MARK: no editing implemented yet
    //var minHoldTime: TimeSpan = .init(seconds: 30)
    //var maxHoldTime: TimeSpan = .init(minutes: 5)
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
    var progressiveOverload: Bool = true
    var progressiveOverloadPeriod: Int = 6 // Default to 6 weeks
    var progressiveOverloadStyle: ProgressiveOverloadStyle = .dynamic // Default style
    var customOverloadFactor: Double?

    var allowDeloading: Bool = true
    var periodUntilDeload: Int = 4
    var deloadIntensity: Int = 85
    
    var userLanguage: Languages = .english
    var selectedTheme: Themes = .defaultMode // Default style
    var roundingPreference: RoundingPreference = .init()
    var muscleRestDuration: Int = 48 // Default to 48 hours
    
    var setIntensity: SetIntensitySettings = .init()
    var warmupSettings: WarmupSettings = .init()
    
    var useDateOnly: Bool = true // If true, only the date is considered
    var defaultWorkoutTime: DateComponents?  // Default workout time, [.hour, .minute]

    var workoutReminders: Bool = true
    var notifications: Notifications = .init()
    
    var enableSortPicker: Bool = true // disable ExerciseSortOptions picker
    var saveSelectedSort: Bool = false // save selections as new exerciseSortOption
    var sortByTemplateCategories: Bool = true // sort by template categories when editing a template with categories
    var hideUnequippedExercises: Bool = false // hide exercises that the user DOES NOT have equipment for in exercise selection or or exercise view
    var hideDifficultExercises: Bool = false // hide exercises that would be too difficult for the user
    var hideDislikedExercises: Bool = false // hide exercises that the user has disliked
    
    var restTimerEnabled: Bool = true
    var hideRpeSlider: Bool = false
    var hideCompletedInput: Bool = false
    var hideExerciseImage: Bool = false
    
    //var hiddenExercises: Set<Exercise.ID> = []
    //var monthlyStrengthUpdate: Bool = true
}

// evaluation       = Evaluation()
struct Evaluation: Codable {
    var strengthLevel: StrengthLevel = .beginner
    var determineStrengthLevelDate: Date?
    var isFamiliarWithGym: Bool = false // change this after certain number of completed workouts, or allow manual change
    var strengths: [Muscle: StrengthLevel]?
    var weaknesses: [Muscle: StrengthLevel]?
    var availableEquipment: Set<GymEquipment.ID> = []
    var favoriteExercises: Set<Exercise.ID> = []
    var dislikedExercises: Set<Exercise.ID> = []
    var availablePlates: WeightPlates = WeightPlates()
    var askedRPEprompt: Bool = false
}

// sessionTracking  = SessionTracking()
struct SessionTracking: Codable, Equatable {
    var totalNumWorkouts: Int = 0
    var workoutStreak: Int = 0
    var longestWorkoutStreak: Int = 0
    var selectedView: GraphView = .exercisePerformance
    var selectedExercise: Exercise.ID?
    var selectedMeasurement: MeasurementType = .weight
    var activeWorkout: WorkoutInProgress?
    var exerciseSortOption: ExerciseSortOption = .moderate
}

// workoutPlans     = WorkoutPlans()
struct WorkoutPlans: Codable, Equatable {
    var userTemplates: [WorkoutTemplate] = []
    var trainerTemplates: [WorkoutTemplate] = []
    var allTemplates: [WorkoutTemplate] { userTemplates + trainerTemplates }
    var archivedTemplates: [WorkoutTemplate] = []
    var workoutsCreationDate: Date?
    var workoutsStartDate: Date?
    var completedWorkouts: [CompletedWorkout] = []
}
