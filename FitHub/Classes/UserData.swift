//
//  UserData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//
import SwiftUI
import Foundation
import Combine

class UserData: ObservableObject, Codable {
    private let saveQueue = DispatchQueue(label: "com.FitHubApp.UserData.save")
    
    /// Queue used for **scheduling** (not for the actual work)
    private let debounceQueue = DispatchQueue(label: "com.FitHubApp.UserData.debounce")

    /// One pending task per‑key; when you ask to save the same key twice in quick
    /// succession the first task is cancelled and replaced.
    private var pendingSingleSaves: [CodingKeys: DispatchWorkItem] = [:]

    /// One pending task for the “save the whole object” call
    private var pendingFullSave: DispatchWorkItem?
    
    // MARK: - Profile Info
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var userId: String = ""
    @Published var accountCreationDate: Date?
    @Published var userName: String = ""
    @Published var age: Int = 0
    @Published var dob: Date = Date()
    
    // MARK: - Physical Stats
    @Published var gender: Gender = .male
    @Published var avgSteps: Int = 0
    @Published var activityLevel: ActivityLevel = .select
    @Published var goal: FitnessGoal = .getStronger
    @Published var carbs: Double = 0.0
    @Published var fats: Double = 0.0
    @Published var proteins: Double = 0.0
    @Published var heightInches: Int = 0
    @Published var heightFeet: Int = 0
    @Published var currentMeasurements: [MeasurementType: Measurement] = [:]
    @Published var pastMeasurements: [MeasurementType: [Measurement]] = [:]
    
    // MARK: - Workout Preferences
    @Published var customSets: Int? // Optional to override default sets
    @Published var customRepsRange: ClosedRange<Int>? // Optional to override default reps range
    @Published var customWorkoutDays: [daysOfWeek]? // Optional array to store custom days of the week
    @Published var customWorkoutSplit: WorkoutWeek? // Optional custom split, overrides default logic based on days per week
    @Published var keepCurrentExercises: Bool = false
    @Published var exerciseType: ExerciseType = .default // bodyweight, exclude bodyweight
    @Published var customRestPeriod: Int?
    @Published var setStructure: SetStructures = .pyramid
    @Published var workoutDaysPerWeek: Int = 0 // days per week user wants to work out
    
    // MARK: - Setup State
    @Published var setupState: SetupState = .welcomeView
    @Published var isEquipmentSelected: Bool = false
    @Published var questionAnswers: [String] = []
    @Published var questionsAnswered: Bool = false
    @Published var infoCollected: Bool = false
    @Published var maxRepsEntered: Bool = false
    @Published var oneRepMaxesEntered: Bool = false
    
    // MARK: - App Settings
    @Published var restTimerEnabled: Bool = true
    @Published var allowedNotifications: Bool = false
    @Published var allowedCredentials: Bool = false
    @Published var progressiveOverload: Bool = true
    @Published var userLanguage: Languages = .english
    @Published var selectedTheme: Themes = .defaultMode // Default style
    @Published var measurementUnit: UnitOfMeasurement = .imperial
    @Published var roundingPreference: [EquipmentCategory: Double] = [.weightMachines: 2.5, .cableMachines: 2.5, .platedMachines: 5, .barsPlates: 5, .smallWeights : 5]
    @Published var stagnationPeriod: Int = 4 // Default to 4 weeks
    @Published var progressiveOverloadPeriod: Int = 6 // Default to 6 weeks
    @Published var progressiveOverloadStyle: ProgressiveOverloadStyle = .dynamic // Default style
    @Published var muscleRestDuration: Int = 48 // Default to 48 hours
    @Published var useDateOnly: Bool = true // If true, only the date is considered
    @Published var notifyBeforePlannedTime: Bool = true // If true, notify before planned time; otherwise, notify at the beginning of the day
    @Published var notificationTimes: [TimeInterval] = [] // Array of time intervals in seconds for notifications
    @Published var defaultWorkoutTime: Date?  // Default workout time, initialized to the current time

    // MARK: - Evaluation / Fitness Level
    @Published var fitnessScore: Int = 0
    @Published var strengthLevel: StrengthLevel = .beginner
    @Published var determineStrengthLevelDate: Date?
    @Published var strengthPercentile: Int = 0
    @Published var isFamiliarWithGym: Bool = false // change this after certain number of completed workouts, or allow manual change
    @Published var strengths: [Muscle: StrengthLevel]?
    @Published var weaknesses: [Muscle: StrengthLevel]?
    @Published var equipmentSelected: [GymEquipment] = []
    @Published var favoriteExercises: [String] = []
    @Published var dislikedExercises: [String] = []
    
    // MARK: - Workout History / Session Tracking
    @Published var totalNumWorkouts: Int = 0
    @Published var workoutStreak: Int = 0
    @Published var longestWorkoutStreak: Int = 0
    @Published var selectedView: GraphView = .exercisePerformance
    @Published var selectedExercise: String = "Bench Press"
    @Published var selectedMeasurement: MeasurementType = .weight
    @Published var activeWorkout: WorkoutInProgress?
    @Published var exerciseSortOption: ExerciseSortOption = .simple
    
    // MARK: - Workout Plans
    @Published var userTemplates: [WorkoutTemplate] = []
    @Published var trainerTemplates: [WorkoutTemplate] = []
    @Published var workoutsCreationDate: Date?
    @Published var workoutsStartDate: Date?
    @Published var generatedWeeksWorkout: Bool = false
    @Published var completedWorkouts: [CompletedWorkout] = []
    
    init(){}
    
    enum CodingKeys: CodingKey {
        case firstName, lastName, email, userId, accountCreationDate, userName, age, dob
        case gender, avgSteps, activityLevel, goal, carbs, fats, proteins, heightInches, heightFeet, currentMeasurements, pastMeasurements
        case customSets, customRepsRange, customWorkoutDays, customWorkoutSplit, keepCurrentExercises, exerciseType, customRestPeriod, setStructure, workoutDaysPerWeek
        case setupState, isEquipmentSelected, questionAnswers, questionsAnswered, infoCollected, maxRepsEntered, oneRepMaxesEntered
        case restTimerEnabled, allowedNotifications, allowedCredentials, progressiveOverload, userLanguage, selectedTheme, measurementUnit, roundingPreference, stagnationPeriod,
            progressiveOverloadPeriod, progressiveOverloadStyle, muscleRestDuration, useDateOnly, notifyBeforePlannedTime, notificationTimes, defaultWorkoutTime
        case fitnessScore, strengthLevel, determineStrengthLevelDate, strengthPercentile, isFamiliarWithGym, strengths, weaknesses, equipmentSelected, favoriteExercises, dislikedExercises
        case totalNumWorkouts, workoutStreak, longestWorkoutStreak, selectedView, selectedExercise, selectedMeasurement, activeWorkout, exerciseSortOption
        case userTemplates, trainerTemplates, workoutsCreationDate, workoutsStartDate, generatedWeeksWorkout, completedWorkouts
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // MARK: - Profile Info
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        userId = try container.decode(String.self, forKey: .userId)
        accountCreationDate = try container.decodeIfPresent(Date.self, forKey: .accountCreationDate)
        userName = try container.decode(String.self, forKey: .userName)
        dob = try container.decode(Date.self, forKey: .dob)
        age = try container.decode(Int.self, forKey: .age)

        // MARK: - Physical Stats
        gender = try container.decode(Gender.self, forKey: .gender)
        avgSteps = try container.decode(Int.self, forKey: .avgSteps)
        activityLevel = try container.decode(ActivityLevel.self, forKey: .activityLevel)
        goal = try container.decode(FitnessGoal.self, forKey: .goal)
        carbs = try container.decode(Double.self, forKey: .carbs)
        fats = try container.decode(Double.self, forKey: .fats)
        proteins = try container.decode(Double.self, forKey: .proteins)
        heightFeet = try container.decode(Int.self, forKey: .heightFeet)
        heightInches = try container.decode(Int.self, forKey: .heightInches)
        currentMeasurements = try container.decode([MeasurementType: Measurement].self, forKey: .currentMeasurements)
        pastMeasurements = try container.decode([MeasurementType: [Measurement]].self, forKey: .pastMeasurements)

        // MARK: - Workout Preferences
        customSets = try container.decodeIfPresent(Int.self, forKey: .customSets)
        customRepsRange = try container.decodeIfPresent(ClosedRange<Int>.self, forKey: .customRepsRange)
        customWorkoutDays = try container.decodeIfPresent([daysOfWeek].self, forKey: .customWorkoutDays)
        customWorkoutSplit = try container.decodeIfPresent(WorkoutWeek.self, forKey: .customWorkoutSplit)
        keepCurrentExercises = try container.decode(Bool.self, forKey: .keepCurrentExercises)
        exerciseType = try container.decode(ExerciseType.self, forKey: .exerciseType)
        customRestPeriod = try container.decodeIfPresent(Int.self, forKey: .customRestPeriod)
        setStructure = try container.decode(SetStructures.self, forKey: .setStructure)
        workoutDaysPerWeek = try container.decode(Int.self, forKey: .workoutDaysPerWeek)
        
        // MARK: - Setup State
        setupState = try container.decode(SetupState.self, forKey: .setupState)
        isEquipmentSelected = try container.decode(Bool.self, forKey: .isEquipmentSelected)
        questionAnswers = try container.decode([String].self, forKey: .questionAnswers)
        questionsAnswered = try container.decode(Bool.self, forKey: .questionsAnswered)
        infoCollected = try container.decode(Bool.self, forKey: .infoCollected)
        maxRepsEntered = try container.decode(Bool.self, forKey: .maxRepsEntered)
        oneRepMaxesEntered = try container.decode(Bool.self, forKey: .oneRepMaxesEntered)

        // MARK: - App Settings
        restTimerEnabled = try container.decode(Bool.self, forKey: .restTimerEnabled)
        allowedNotifications = try container.decode(Bool.self, forKey: .allowedNotifications)
        allowedCredentials = try container.decode(Bool.self, forKey: .allowedCredentials)
        progressiveOverload = try container.decode(Bool.self, forKey: .progressiveOverload)
        userLanguage = try container.decode(Languages.self, forKey: .userLanguage)
        selectedTheme = try container.decode(Themes.self, forKey: .selectedTheme)
        measurementUnit = try container.decode(UnitOfMeasurement.self, forKey: .measurementUnit)
        roundingPreference = try container.decode([EquipmentCategory: Double].self, forKey: .roundingPreference)
        stagnationPeriod = try container.decode(Int.self, forKey: .stagnationPeriod)
        progressiveOverloadPeriod = try container.decode(Int.self, forKey: .progressiveOverloadPeriod)
        progressiveOverloadStyle = try container.decode(ProgressiveOverloadStyle.self, forKey: .progressiveOverloadStyle)
        muscleRestDuration = try container.decode(Int.self, forKey: .muscleRestDuration)
        useDateOnly = try container.decode(Bool.self, forKey: .useDateOnly)
        notifyBeforePlannedTime = try container.decode(Bool.self, forKey: .notifyBeforePlannedTime)
        notificationTimes = try container.decode([TimeInterval].self, forKey: .notificationTimes)
        defaultWorkoutTime = try container.decodeIfPresent(Date.self, forKey: .defaultWorkoutTime)

        // MARK: - Evaluation / Fitness Level
        fitnessScore = try container.decode(Int.self, forKey: .fitnessScore)
        strengthLevel = try container.decode(StrengthLevel.self, forKey: .strengthLevel)
        determineStrengthLevelDate = try container.decodeIfPresent(Date.self, forKey: .determineStrengthLevelDate)
        strengthPercentile = try container.decode(Int.self, forKey: .strengthPercentile)
        isFamiliarWithGym = try container.decode(Bool.self, forKey: .isFamiliarWithGym)
        strengths = try container.decodeIfPresent([Muscle: StrengthLevel].self, forKey: .strengths)
        weaknesses = try container.decodeIfPresent([Muscle: StrengthLevel].self, forKey: .weaknesses)

        // MARK: - Workout History / Session Tracking
        equipmentSelected = try container.decode([GymEquipment].self, forKey: .equipmentSelected)
        favoriteExercises = try container.decode([String].self, forKey: .favoriteExercises)
        dislikedExercises = try container.decode([String].self, forKey: .dislikedExercises)
        totalNumWorkouts = try container.decode(Int.self, forKey: .totalNumWorkouts)
        workoutStreak = try container.decode(Int.self, forKey: .workoutStreak)
        longestWorkoutStreak = try container.decode(Int.self, forKey: .longestWorkoutStreak)
        selectedView = try container.decode(GraphView.self, forKey: .selectedView)
        selectedExercise = try container.decode(String.self, forKey: .selectedExercise)
        selectedMeasurement = try container.decode(MeasurementType.self, forKey: .selectedMeasurement)
        activeWorkout = try container.decodeIfPresent(WorkoutInProgress.self, forKey: .activeWorkout)
        exerciseSortOption = try container.decode(ExerciseSortOption.self, forKey: .exerciseSortOption)

        // MARK: - Workout Plans
        userTemplates = try container.decode([WorkoutTemplate].self, forKey: .userTemplates)
        trainerTemplates = try container.decode([WorkoutTemplate].self, forKey: .trainerTemplates)
        workoutsCreationDate = try container.decodeIfPresent(Date.self, forKey: .workoutsCreationDate)
        workoutsStartDate = try container.decodeIfPresent(Date.self, forKey: .workoutsStartDate)
        generatedWeeksWorkout = try container.decode(Bool.self, forKey: .generatedWeeksWorkout)
        completedWorkouts = try container.decode([CompletedWorkout].self, forKey: .completedWorkouts)
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // MARK: - Profile Info
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(email, forKey: .email)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(accountCreationDate, forKey: .accountCreationDate)
        try container.encode(userName, forKey: .userName)
        try container.encode(dob, forKey: .dob)
        try container.encode(age, forKey: .age)

        // MARK: - Physical Stats
        try container.encode(gender, forKey: .gender)
        try container.encode(avgSteps, forKey: .avgSteps)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encode(goal, forKey: .goal)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fats, forKey: .fats)
        try container.encode(proteins, forKey: .proteins)
        try container.encode(heightFeet, forKey: .heightFeet)
        try container.encode(heightInches, forKey: .heightInches)
        try container.encode(currentMeasurements, forKey: .currentMeasurements)
        try container.encode(pastMeasurements, forKey: .pastMeasurements)

        // MARK: - Workout Preferences
        try container.encodeIfPresent(customSets, forKey: .customSets)
        try container.encodeIfPresent(customRepsRange, forKey: .customRepsRange)
        try container.encodeIfPresent(customWorkoutDays, forKey: .customWorkoutDays)
        try container.encodeIfPresent(customWorkoutSplit, forKey: .customWorkoutSplit)
        try container.encode(keepCurrentExercises, forKey: .keepCurrentExercises)
        try container.encode(exerciseType, forKey: .exerciseType)
        try container.encodeIfPresent(customRestPeriod, forKey: .customRestPeriod)
        try container.encode(setStructure, forKey: .setStructure)
        try container.encode(workoutDaysPerWeek, forKey: .workoutDaysPerWeek)
        
        // MARK: - Setup State
        try container.encode(setupState, forKey: .setupState)
        try container.encode(isEquipmentSelected, forKey: .isEquipmentSelected)
        try container.encode(questionAnswers, forKey: .questionAnswers)
        try container.encode(questionsAnswered, forKey: .questionsAnswered)
        try container.encode(infoCollected, forKey: .infoCollected)
        try container.encode(maxRepsEntered, forKey: .maxRepsEntered)
        try container.encode(oneRepMaxesEntered, forKey: .oneRepMaxesEntered)

        // MARK: - App Settings
        try container.encode(restTimerEnabled, forKey: .restTimerEnabled)
        try container.encode(allowedNotifications, forKey: .allowedNotifications)
        try container.encode(allowedCredentials, forKey: .allowedCredentials)
        try container.encode(progressiveOverload, forKey: .progressiveOverload)
        try container.encode(userLanguage, forKey: .userLanguage)
        try container.encode(selectedTheme, forKey: .selectedTheme)
        try container.encode(measurementUnit, forKey: .measurementUnit)
        try container.encode(roundingPreference, forKey: .roundingPreference)
        try container.encode(stagnationPeriod, forKey: .stagnationPeriod)
        try container.encode(progressiveOverloadPeriod, forKey: .progressiveOverloadPeriod)
        try container.encode(progressiveOverloadStyle, forKey: .progressiveOverloadStyle)
        try container.encode(muscleRestDuration, forKey: .muscleRestDuration)
        try container.encode(useDateOnly, forKey: .useDateOnly)
        try container.encode(notifyBeforePlannedTime, forKey: .notifyBeforePlannedTime)
        try container.encode(notificationTimes, forKey: .notificationTimes)
        try container.encodeIfPresent(defaultWorkoutTime, forKey: .defaultWorkoutTime)

        // MARK: - Evaluation / Fitness Level
        try container.encode(fitnessScore, forKey: .fitnessScore)
        try container.encode(strengthLevel, forKey: .strengthLevel)
        try container.encodeIfPresent(determineStrengthLevelDate, forKey: .determineStrengthLevelDate)
        try container.encode(strengthPercentile, forKey: .strengthPercentile)
        try container.encode(isFamiliarWithGym, forKey: .isFamiliarWithGym)
        try container.encodeIfPresent(strengths, forKey: .strengths)
        try container.encodeIfPresent(weaknesses, forKey: .weaknesses)

        // MARK: - Workout History / Session Tracking
        try container.encode(equipmentSelected, forKey: .equipmentSelected)
        try container.encode(favoriteExercises, forKey: .favoriteExercises)
        try container.encode(dislikedExercises, forKey: .dislikedExercises)
        try container.encode(totalNumWorkouts, forKey: .totalNumWorkouts)
        try container.encode(workoutStreak, forKey: .workoutStreak)
        try container.encode(longestWorkoutStreak, forKey: .longestWorkoutStreak)
        try container.encode(selectedView, forKey: .selectedView)
        try container.encode(selectedExercise, forKey: .selectedExercise)
        try container.encode(selectedMeasurement, forKey: .selectedMeasurement)
        try container.encodeIfPresent(activeWorkout, forKey: .activeWorkout)
        try container.encode(exerciseSortOption, forKey: .exerciseSortOption)

        // MARK: - Workout Plans
        try container.encode(userTemplates, forKey: .userTemplates)
        try container.encode(trainerTemplates, forKey: .trainerTemplates)
        try container.encodeIfPresent(workoutsCreationDate, forKey: .workoutsCreationDate)
        try container.encodeIfPresent(workoutsStartDate, forKey: .workoutsStartDate)
        try container.encode(generatedWeeksWorkout, forKey: .generatedWeeksWorkout)
        try container.encode(completedWorkouts, forKey: .completedWorkouts)
    }
    
    struct AnyEncodable: Encodable {
        private let encodeFunc: (Encoder) throws -> Void
        init<T: Encodable>(_ wrapped: T) { self.encodeFunc = wrapped.encode }
        func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
    }
    
    /// Save a single stored property (debounced).
    func saveSingleVariableToFile<T: Encodable>(_ keyPath: KeyPath<UserData, T>, for key: CodingKeys, delay: TimeInterval = 0.4) {
        let value = self[keyPath: keyPath]
        debouncedSingleSave(value: value, for: key, delay: delay)
    }

    /// Call this when you really need *everything* persisted (debounced).
    func saveToFile(delay: TimeInterval = 0.8) {
        debouncedFullSave(delay: delay)
    }

    /// Immediate flush – bypasses debounce. Call sparingly.
    func saveToFileImmediate() {
        saveQueue.async { [weak self] in
            guard let self else { return }
            do {
                let data = try JSONEncoder().encode(self)
                let url = try FileManager.default
                    .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserData.json")
                try data.write(to: url, options: .atomicWrite)
                print("✅ Full save successful")
            } catch {
                print("❌ Full save failed: \(error)")
            }
        }
    }

    // MARK: - Debounced implementations ----------------------------------------
    private func debouncedSingleSave<T: Encodable>(value: T, for key: CodingKeys, delay: TimeInterval) {
        // 1) cancel any outstanding request for this key
        pendingSingleSaves[key]?.cancel()
        
        // 2) create a new work‑item
        let work = DispatchWorkItem { [weak self] in
            self?.saveSingleVariableToFileInternal(value: value, for: key)
            self?.pendingSingleSaves[key] = nil               // cleanup
        }
        pendingSingleSaves[key] = work
        
        // 3) schedule on debounceQueue
        debounceQueue.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func debouncedFullSave(delay: TimeInterval) {
        // cancel previous full‑object save if waiting
        pendingFullSave?.cancel()
        
        let work = DispatchWorkItem { [weak self] in
            self?.saveToFileImmediate()
            self?.pendingFullSave = nil
        }
        pendingFullSave = work
        debounceQueue.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // MARK: - Low‑level single‑field save (unchanged)
    private func saveSingleVariableToFileInternal(value: Encodable, for key: CodingKeys) {
        saveQueue.async {
            do {
                let fm  = FileManager.default
                let url = try fm.url(for: .documentDirectory, in: .userDomainMask,appropriateFor: nil, create: false).appendingPathComponent("UserData.json")
                
                // read existing JSON (if any)
                var jsonObject: [String: Any] = [:]
                if fm.fileExists(atPath: url.path),
                   let data = try? Data(contentsOf: url),
                   let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    jsonObject = existing
                }
                
                // encode new key/value into tiny blob
                let encoded   = try JSONEncoder().encode([key.stringValue: AnyEncodable(value)])
                if let partial = try JSONSerialization.jsonObject(with: encoded) as? [String: Any],
                   let updated = partial[key.stringValue] {
                    jsonObject[key.stringValue] = updated
                }
                
                // write full object back
                let updatedData = try JSONSerialization.data(withJSONObject: jsonObject,
                                                             options: [.prettyPrinted])
                try updatedData.write(to: url, options: .atomicWrite)
                print("✅ Saved '\(key.stringValue)' to file.")
            } catch {
                print("❌ Failed to save '\(key.stringValue)': \(error)")
            }
        }
    }
    
    // Method to load the user data from a file
    static func loadFromFile() -> UserData? {
        do {
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserData.json")
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let userData = try decoder.decode(UserData.self, from: data)
            return userData
        } catch {
            print("Failed to load user data: \(error)")
       
            return nil
        }
    }

    func resetExercisesInTemplate(for template: WorkoutTemplate, shouldRemoveNotifications: Bool = false) {
        activeWorkout = nil                  // reset the active workout property
        saveSingleVariableToFile(\.activeWorkout, for: .activeWorkout)

        var updatedTemplate = template         // Create a mutable copy of the template
        
        // Loop through each exercise in the template and reset its state
        for exerciseIndex in updatedTemplate.exercises.indices {
            updatedTemplate.exercises[exerciseIndex].currentSet = 1
            updatedTemplate.exercises[exerciseIndex].timeSpent = 0
            updatedTemplate.exercises[exerciseIndex].isCompleted = false
            
            // Reset repsCompleted for each setDetail in the exercise
            for setIndex in updatedTemplate.exercises[exerciseIndex].setDetails.indices {
                updatedTemplate.exercises[exerciseIndex].setDetails[setIndex].repsCompleted = nil
            }
            
            // Reset repsCompleted for each warmup set in the exercise
            for setIndex in updatedTemplate.exercises[exerciseIndex].warmUpDetails.indices {
                updatedTemplate.exercises[exerciseIndex].warmUpDetails[setIndex].repsCompleted = nil
            }
        }
        saveTemplate(template: updatedTemplate, shouldRemoveNotifications: shouldRemoveNotifications)
    }
    
    func deleteTrainerTemplate(at offsets: IndexSet) {
        func getTrainerTemplate(for index: Int) -> WorkoutTemplate? {
            // Check if the index belongs to userTemplates
            if index < trainerTemplates.count {
                return trainerTemplates[index]
            } else {
                return nil // Return nil if index is out of bounds
            }
        }
        for index in offsets {
            // Get the template using the helper function
            if let workoutTemplate = getTrainerTemplate(for: index) {
                // Remove notifications associated with the template
                removeNotifications(for: workoutTemplate)
                trainerTemplates.remove(at: index)
                saveSingleVariableToFile(\.trainerTemplates, for: .trainerTemplates)
                return
            }
        }
    }
    
    func deleteUserTemplate(at offsets: IndexSet) {
        func getUserTemplate(for index: Int) -> WorkoutTemplate? {
            // Check if the index belongs to userTemplates
            if index < userTemplates.count {
                return userTemplates[index]
            } else {
                return nil // Return nil if index is out of bounds
            }
        }
        for index in offsets {
            // Get the template using the helper function
            if let workoutTemplate = getUserTemplate(for: index) {
                // Remove notifications associated with the template
                removeNotifications(for: workoutTemplate)
                userTemplates.remove(at: index)
                saveSingleVariableToFile(\.trainerTemplates, for: .userTemplates)
                return
            }
        }
    }
    
    func saveTemplate(template: WorkoutTemplate, shouldRemoveNotifications: Bool = false) {
        if !userTemplates.isEmpty {
            for index in userTemplates.indices {
                if userTemplates[index].id == template.id {
                    userTemplates[index] = template
                    if shouldRemoveNotifications {
                        removeNotifications(for: userTemplates[index])
                        userTemplates[index].date = nil
                    }
                    print("saved \(template.name) to file")
                    saveSingleVariableToFile(\.userTemplates, for: .userTemplates)
                    print("Template found")
                    return
                }
            }
        }
        if !trainerTemplates.isEmpty {
            for index in trainerTemplates.indices {
                if trainerTemplates[index].id == template.id {
                    trainerTemplates[index] = template
                    if shouldRemoveNotifications {
                        removeNotifications(for: trainerTemplates[index])
                        trainerTemplates[index].date = nil
                    }
                    print("saved \(template.name) to file")
                    saveSingleVariableToFile(\.trainerTemplates, for: .trainerTemplates)
                    print("Template found")
                    return
                }
            }
        }
        // only save if template is found
        print("Template not found")
    }
    
    func incrementWorkoutStreak(shouldSave: Bool = true) {
        print("Before Incrementing Workout Streak: \(workoutStreak)")
        workoutStreak += 1
        totalNumWorkouts += 1
        if workoutStreak > longestWorkoutStreak {
            longestWorkoutStreak = workoutStreak
        }
        print("After Incrementing Workout Streak: \(workoutStreak)")
        if shouldSave {
            saveToFile()
        }
    }
    
    func getValidMeasurements() -> [MeasurementType] {
        var measurements: [MeasurementType] = []
        
        for measurement in MeasurementType.allCases {
            if currentMeasurements[measurement] != nil {
                measurements.append(measurement)
            }
        }
        return measurements
    }
    
    func updateMeasurementValue(for type: MeasurementType, with newValue: Double, shouldSave: Bool) {
        let currentDate = Date()
        
        if let currentMeasurement = currentMeasurements[type] {
            if pastMeasurements[type] == nil {
                pastMeasurements[type] = []
            }
            pastMeasurements[type]?.append(currentMeasurement)
            if shouldSave {
                saveSingleVariableToFile(\.pastMeasurements, for: .pastMeasurements)
            }
        }
        currentMeasurements[type] = Measurement(type: type, value: newValue, date: currentDate)
        if shouldSave {
            saveSingleVariableToFile(\.currentMeasurements, for: .currentMeasurements)
        }
    }
    
    func currentMeasurementValue(for type: MeasurementType) -> Double {
        return currentMeasurements[type]?.value ?? 0.0
    }
    
    func getWorkoutDates() -> [Date] {
        var dates: [Date] = []
        
        if !completedWorkouts.isEmpty {
            for workout in completedWorkouts {
                dates.append(workout.date)
            }
        }
        return dates
    }
    
    func getPlannedWorkoutDates() -> [Date] {
        var plannedDates: [Date] = []
        
        if !trainerTemplates.isEmpty {
            for template in trainerTemplates {
                if let templateDate = template.date {
                    plannedDates.append(templateDate)
                }
            }
        }
        if !userTemplates.isEmpty {
            for template in userTemplates {
                if let templateDate = template.date {
                    plannedDates.append(templateDate)
                }
            }
        }
        return plannedDates
    }
    // even dates from templates with date == nil
    func getAllPlannedWorkoutDates() -> [Date] {
        var plannedDates: [Date] = []
        
        if !trainerTemplates.isEmpty {
            for template in trainerTemplates {
                if let templateDate = template.date {
                    plannedDates.append(templateDate)
                } else {
                    if let completedTemplateDate = completedWorkouts.first(where: { $0.template.id == template.id })?.template.date {
                        plannedDates.append(completedTemplateDate)
                    }
                }
            }
        }
        if !userTemplates.isEmpty {
            for template in userTemplates {
                if let templateDate = template.date {
                    plannedDates.append(templateDate)
                } else {
                    if let completedTemplateDate = completedWorkouts.first(where: { $0.template.id == template.id })?.template.date {
                        plannedDates.append(completedTemplateDate)
                    }
                }
            }
        }
        return plannedDates
    }
    
    func removePlannedWorkoutDate(template: WorkoutTemplate, date: Date) -> Bool {
        var removedDate = false
        let calendar = Calendar.current
        
        // Check trainerTemplates
        if !trainerTemplates.isEmpty {
            for index in trainerTemplates.indices {
                if template.id == trainerTemplates[index].id {
                    if let templateDate = trainerTemplates[index].date {
                        if calendar.isDate(templateDate, inSameDayAs: date) {
                            trainerTemplates[index].date = nil
                            removedDate = true
                            removeNotifications(for: trainerTemplates[index])
                        }
                        else if templateDate < date {
                            trainerTemplates[index].date = nil
                            removedDate = true
                        }
                        if removedDate {
                            saveSingleVariableToFile(\.trainerTemplates, for: .trainerTemplates)
                            return removedDate
                        }
                    }
                }
            }
        }
        // Check userTemplates
        if !userTemplates.isEmpty {
            for index in userTemplates.indices {
                if template.id == userTemplates[index].id {
                    if let templateDate = userTemplates[index].date {
                        if calendar.isDate(templateDate, inSameDayAs: date) {
                            userTemplates[index].date = nil
                            removedDate = true
                            removeNotifications(for: userTemplates[index])
                        }
                        else if templateDate < date {
                            userTemplates[index].date = nil
                            removedDate = true
                        }
                        if removedDate {
                            saveSingleVariableToFile(\.userTemplates, for: .userTemplates)
                            return removedDate
                        }
                    }
                }
            }
        }
        // Return if a date was removed
        return removedDate
    }
    
    func manageOldTemplates() -> [[Exercise]] {
        var savedExercises: [[Exercise]] = []
        if keepCurrentExercises {
            savedExercises = trainerTemplates.map { $0.exercises }
        }
        for template in trainerTemplates {
            removeNotifications(for: template) // Remove associated notifications
        }
        trainerTemplates.removeAll()

        return savedExercises
    }
    
    func generateWorkoutPlan(exerciseData: ExerciseData, equipmentData: EquipmentData, csvLoader: CSVLoader, keepCurrentExercises: Bool, selectedExerciseType: ExerciseType, nextWeek: Bool, shouldSave: Bool = true) {
        //print("CustomWorkoutSplit: \(customWorkoutSplit ?? WorkoutWeek.createSplit(forDays: workoutDaysPerWeek))")
        print("Starting to generate workout plan...")
        
        let savedExercises = manageOldTemplates()
        let exercisesPerWorkout = WorkoutTemplate.determineExercisesPerWorkout(basedOn: age, frequency: workoutDaysPerWeek, strengthLevel: strengthLevel)
        let repsAndSets = RepsAndSets.determineRepsAndSets(customRestPeriod: customRestPeriod, goal: goal, customRepsRange: customRepsRange, customSets: customSets)
        let workoutDayIndexes = daysOfWeek.calculateWorkoutDayIndexes(customWorkoutDays: customWorkoutDays, workoutDaysPerWeek: workoutDaysPerWeek)
        let workoutDays = workoutDayIndexes.map { daysOfWeek.orderedDays[$0].rawValue }
        let workoutWeek = customWorkoutSplit ?? WorkoutWeek.createSplit(forDays: workoutDaysPerWeek)
        
        // Map workout day indexes to the correct categories
        let targetedCategories = workoutDayIndexes.enumerated().map { (index, dayIndex) in
            return workoutWeek.categoryForDay(index: index)
        }
        
        if workoutDays.isEmpty {
            print("Issue: No workout days were determined. Check the 'workoutDaysPerWeek' value and 'getWorkoutDays' method logic.")
            return // Early return to prevent further processing
        }
        
        // Determine start date, adjust if the last date of the week is in the past
        var startDate = Date()
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Sets Monday as the first day of the week (1 is Sunday)
        var datesOfWeek = startDate.datesOfWeek(using: calendar)
        
        // Find the last relevant workout date from the user's workout days within the week
        let lastWorkoutDate = workoutDayIndexes.compactMap { index in
            datesOfWeek[index]
        }.last
        
        if let lastWorkoutDate = lastWorkoutDate {
            if calendar.isDate(lastWorkoutDate, inSameDayAs: Date()) {
                // If the last workout day is today, keep the current week
                print("Last relevant workout date is today. Generating workouts for the current week.")
                // No changes to `startDate` or `datesOfWeek`
            } else if lastWorkoutDate < Date() {
                // If the last workout date is in the past, generate workouts for the next week
                print("Last relevant workout date is in the past. Generating workouts for the next week.")
                startDate = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
                datesOfWeek = startDate.datesOfWeek(using: calendar)
            }
        }
        
        workoutsStartDate = startDate
        
        // Step 1: Generate initial workout plan with selected exercises or saved exercises
        for (index, dayIndex) in workoutDayIndexes.enumerated() {
            var workoutDate = datesOfWeek[dayIndex]
            if !useDateOnly {
                if let defaultTime = defaultWorkoutTime {
                    // Set workoutDate to defaultWorkoutTime if it is not nil
                    workoutDate = defaultTime
                }
                else {
                    // Set the time of the workoutDate to 11:00 AM directly
                    if let adjustedDate = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: workoutDate) {
                        workoutDate = adjustedDate
                    }
                }
            }
            
            let day = daysOfWeek.orderedDays[dayIndex].rawValue
            let categoriesForDay = targetedCategories[index]
            
            // Use saved exercises if keeping current exercises, otherwise select new exercises
            let dayExercises: [Exercise]
            if keepCurrentExercises && index < savedExercises.count {
                dayExercises = savedExercises[index]
            } else {
                dayExercises = selectExercisesForDay(dayIndex: index, totalExercises: exercisesPerWorkout, workoutFrequency: workoutDaysPerWeek, availableEquipment: equipmentSelected, exerciseData: exerciseData, workoutWeek: workoutWeek, selectedExerciseType: selectedExerciseType)
            }
            
            if dayExercises.isEmpty {
                print("No exercises were selected for \(day). Check the selection criteria and available exercises.")
            } else {
                
                // → ADD THIS ↓ only when keepCurrentExercises is false
                /*var similarity: Double? = nil
                if !keepCurrentExercises, index < savedExercises.count {
                    let savedNames     = Set(savedExercises[index].map(\.name))
                    let selectedNames  = Set(dayExercises.map(\.name))
                    let overlapCount   = savedNames.intersection(selectedNames).count
                    let maxCount       = max(savedNames.count, selectedNames.count)
                    // avoid divide by zero
                    if maxCount > 0 {
                        similarity = Double(overlapCount) / Double(maxCount) * 100.0
                    }
                }
                if let sim = similarity {
                    print("Day \(day) template similarity: \(String(format: "%.0f%%", sim))")
                }*/
                
                var workoutTemplate = WorkoutTemplate(name: "\(day) Workout", exercises: dayExercises, categories: categoriesForDay, dayIndex: index, date: workoutDate)
                // Schedule notifications and get the IDs
                let notificationIDs = scheduleNotification(for: workoutTemplate)
                // Store the notification IDs in the workoutTemplate
                workoutTemplate.notificationIDs.append(contentsOf: notificationIDs)
                // apend workoutTemplate to trainerTemplates
                trainerTemplates.append(workoutTemplate)
                print("\(workoutTemplate.name) notification IDs: \(workoutTemplate.notificationIDs)")
            }
        }
        
        // Step 2: Calculate and assign 1RM values
        calculateAndAssign1RMForTrainerTemplates(exerciseData: exerciseData, csvLoader: csvLoader)
        
        // Step 3: Recalculate detailed exercises with updated 1RM values
        for i in 0..<trainerTemplates.count {
            var workoutTemplate = trainerTemplates[i]
            for j in 0..<workoutTemplate.exercises.count {
                let exercise = workoutTemplate.exercises[j]
                let detailedExercise = calculateDetailedExercise(exercise: exercise, repsAndSets: repsAndSets, exerciseData: exerciseData, csvLoader: csvLoader, equipmentData: equipmentData, nextWeek: nextWeek)
                workoutTemplate.exercises[j] = detailedExercise
            }
            // Estimate completion time once after all exercises are updated
            workoutTemplate.estimatedCompletionTime = WorkoutTemplate.estimateCompletionTime(for: workoutTemplate, completedWorkouts: completedWorkouts)
            // Save the updated template back
            trainerTemplates[i] = workoutTemplate
        }
        exerciseData.savePerformanceData()
        workoutsCreationDate = Date()
        if shouldSave {
            saveToFile()
        }
    }
    
    func fillTemplate(template: WorkoutTemplate, exerciseData: ExerciseData, equipmentData: EquipmentData, csvLoader: CSVLoader) -> WorkoutTemplate {
        var updatedTemplate = template
        let repsAndSets = RepsAndSets.determineRepsAndSets(customRestPeriod: customRestPeriod, goal: goal, customRepsRange: customRepsRange, customSets: customSets)
        
        for i in 0..<updatedTemplate.exercises.count {
            let exercise = updatedTemplate.exercises[i]
            let detailedExercise = calculateDetailedExercise(exercise: exercise, repsAndSets: repsAndSets, exerciseData: exerciseData, csvLoader: csvLoader, equipmentData: equipmentData, nextWeek: false)
            updatedTemplate.exercises[i] = detailedExercise
        }
        
        exerciseData.savePerformanceData()
        updatedTemplate.estimatedCompletionTime = WorkoutTemplate.estimateCompletionTime(for: updatedTemplate, completedWorkouts: completedWorkouts)
        
        return updatedTemplate
    }
    
    /*func createWarmUpDetails(baselineSet: SetDetail) -> [SetDetail] {
        var warmUpDetails: [SetDetail] = []
        var totalWarmUpSets: Int
        var weightReductionSteps: [Double]
        var repsIncreaseSteps: [Int]
     
        switch setStructure {
            case .pyramid:
                totalWarmUpSets = 2
                weightReductionSteps = [0.5, 0.65] // Percentages of the baseline weight for pyramid
                repsIncreaseSteps = [12, 10]      // Reps for pyramid warm-up sets
            case .reversePyramid:
                totalWarmUpSets = 3
                weightReductionSteps = [0.5, 0.65, 0.8] // Percentages of the baseline weight for reverse pyramid
                repsIncreaseSteps = [10, 8, 6]          // Reps for reverse pyramid warm-up sets
            default:
                totalWarmUpSets = 0
                weightReductionSteps = []
                repsIncreaseSteps = []
            }
     
        for i in 0..<totalWarmUpSets {
            let weight = baselineSet.weight * weightReductionSteps[i]
            let reps = repsIncreaseSteps[i]
            warmUpDetails.append(SetDetail(setNumber: i + 1, weight: weight, reps: reps))
        }
        
     return warmUpDetails
    }*/
    
    func calculateDetailedExercise(exercise: Exercise, repsAndSets: RepsAndSets, exerciseData: ExerciseData, csvLoader: CSVLoader, equipmentData: EquipmentData, nextWeek: Bool) -> Exercise {
        var detailedExercise = exercise
        var progress = detailedExercise.overloadProgress
        //detailedExercise.sets = repsAndSets.sets
        
        //print("Starting calculation for exercise: \(exercise.name)")
        //print("Initial state: usesWeight=\(detailedExercise.usesWeight), weeksStagnated=\(detailedExercise.weeksStagnated), overloadProgress=\(progress)")
        
        // Create setDetails based on current state
        if !detailedExercise.usesWeight {
            if let existingMaxReps = exerciseData.getMax(for: exercise.name), existingMaxReps > 0 {
                detailedExercise.maxReps = Int(existingMaxReps)
            } else {
                //print("No max reps found. Calculating max reps using CSVLoader.")
                let maxReps = csvLoader.calculateFinalReps(userData: self, exercise: exercise.url)
                detailedExercise.maxReps = maxReps
                exerciseData.updateExercisePerformance(for: exercise.name, newValue: Double(maxReps), reps: nil, weight: nil, csvEstimate: true)
                //print("New max reps calculated and updated: \(maxReps)")
            }
            detailedExercise.setDetails = createSetDetails(equipmentData: equipmentData, exercise: detailedExercise, repsAndSets: repsAndSets)
        } else {
            if let existingOneRepMax = exerciseData.getMax(for: exercise.name), existingOneRepMax > 0 {
                detailedExercise.oneRepMax = existingOneRepMax
            } else {
                //print("No one-rep max found. Calculating one-rep max using CSVLoader.")
                let oneRepMax = csvLoader.calculateFinal1RM(userData: self, exercise: exercise.url)
                detailedExercise.oneRepMax = oneRepMax
                exerciseData.updateExercisePerformance(for: exercise.name, newValue: oneRepMax, reps: nil, weight: nil, csvEstimate: true)
                //print("New one-rep max calculated and updated: \(oneRepMax)")
            }
            detailedExercise.setDetails = createSetDetails(equipmentData: equipmentData, exercise: detailedExercise, repsAndSets: repsAndSets)
        }
        
        //print("Set details created: \(detailedExercise.setDetails)")
        
        // Apply progressive overload if nextWeek is true
        if nextWeek {
            // determine if overloading is in progress
            if detailedExercise.weeksStagnated >= stagnationPeriod {
                
                //print("Exercise stagnated for \(detailedExercise.weeksStagnated) weeks. Applying progressive overload.")
                detailedExercise.manualOverloading = true
                progress += 1
                detailedExercise.overloadProgress = progress
                detailedExercise.setDetails = ProgressiveOverloadStyle.applyProgressiveOverload(exercise: detailedExercise, period: progressiveOverloadPeriod, style: progressiveOverloadStyle, roundingPreference: roundingPreference, equipmentData: equipmentData)
                
                //print("Updated set details after overload: \(detailedExercise.setDetails)")
            } else if let maxDate = exerciseData.getDateForMax(for: exercise.name),
                      let creationDate = workoutsCreationDate, maxDate < creationDate {
                detailedExercise.weeksStagnated += 1
                //print("Incremented weeks stagnated to \(detailedExercise.weeksStagnated)")
            }
        }
        
        // Generate warm-up details
        /*if let firstSet = detailedExercise.setDetails.first {
         detailedExercise.warmUpDetails = createWarmUpDetails(baselineSet: firstSet)
         }*/
        
        // Reset or update overload progress
        if progress == progressiveOverloadPeriod {
            //print("Progressive overload period complete. Resetting overload progress and stagnation.")
            detailedExercise.manualOverloading = false
            detailedExercise.weeksStagnated = 0
            detailedExercise.overloadProgress = 0
        }
        //print("Final state for exercise: \(exercise.name)")
        //print("Overload progress: \(detailedExercise.overloadProgress), weeksStagnated: \(detailedExercise.weeksStagnated)")
        return detailedExercise
    }
    
    private func createSetDetails(equipmentData: EquipmentData, exercise: Exercise, repsAndSets: RepsAndSets) -> [SetDetail] {
        var setDetails: [SetDetail] = []
        let totalSets = repsAndSets.sets
        let repsRange = repsAndSets.repsRange
        let restPeriod = repsAndSets.restPeriod
        let setStructure = setStructure
        
        for setNumber in 1...totalSets {
            let reps: Int
            var weight: Double = 0.0
            
            if !exercise.usesWeight {
                let maxReps = exercise.maxReps ?? 0
                // For non-weighted exercises, calculate reps based on maxReps
                reps = SetDetail.calculateReps(maxReps: maxReps, setNumber: setNumber, setStructure: setStructure, numSets: totalSets)
            } else {
                let oneRepMax = exercise.oneRepMax ?? 0
                
                switch setStructure {
                case .pyramid:
                    // Start with lower weights and reps, increasing progressively
                    reps = repsRange.upperBound - (setNumber - 1) * (repsRange.upperBound - repsRange.lowerBound) / (totalSets - 1)
                    weight = SetDetail.calculateWeight(oneRepMax: oneRepMax, reps: reps)
                    
                case .reversePyramid:
                    // Start with higher weights and reps, decreasing progressively
                    reps = repsRange.lowerBound + (setNumber - 1) * (repsRange.upperBound - repsRange.lowerBound) / (totalSets - 1)
                    weight = SetDetail.calculateWeight(oneRepMax: oneRepMax, reps: reps)
                    
                case .fixed:
                    // Same reps and weight across all sets
                    reps = (repsRange.lowerBound + repsRange.upperBound) / 2
                    weight = SetDetail.calculateWeight(oneRepMax: oneRepMax, reps: reps)
                }
                // Adjust weight rounding based on equipment
                weight = equipmentData.roundWeight(weight, for: exercise.equipmentRequired, roundingPreference: roundingPreference)
            }
            // Add the set detail
            setDetails.append(SetDetail(setNumber: setNumber, weight: exercise.usesWeight ? weight : 0, reps: reps, restPeriod: restPeriod))
        }
        return setDetails
    }
    
    func calculateAndAssign1RMForTrainerTemplates(exerciseData: ExerciseData, csvLoader: CSVLoader) {
        for i in 0..<trainerTemplates.count {
            var workoutTemplate = trainerTemplates[i]
            
            for j in 0..<workoutTemplate.exercises.count {
                let exerciseName = workoutTemplate.exercises[j].name
                
                if workoutTemplate.exercises[j].usesWeight {
                    if let oneRepMax = exerciseData.getMax(for: exerciseName), oneRepMax != 0 {
                        workoutTemplate.exercises[j].oneRepMax = oneRepMax
                        //print("Exercise: \(exerciseName), Existing 1RM: \(oneRepMax), No Recalculation Needed")
                    } else {
                        // This will handle both nil and 0 cases
                        let final1RM = csvLoader.calculateFinal1RM(userData: self, exercise: workoutTemplate.exercises[j].url)
                        workoutTemplate.exercises[j].oneRepMax = final1RM
                        exerciseData.updateExercisePerformance(for: exerciseName, newValue: final1RM, reps: nil, weight: nil, csvEstimate: true)
                        //print("Exercise: \(exerciseName), New 1RM Calculated: \(final1RM)")
                    }
                } else {
                    if let maxReps = exerciseData.getMax(for: exerciseName), maxReps != 0 {
                        workoutTemplate.exercises[j].maxReps = Int(maxReps)
                        //print("Exercise: \(exerciseName), Existing Max Reps: \(maxReps), No Recalculation Needed")
                    } else {
                        let finalReps = csvLoader.calculateFinalReps(userData: self, exercise: workoutTemplate.exercises[j].url)
                        workoutTemplate.exercises[j].maxReps = finalReps
                        exerciseData.updateExercisePerformance(for: exerciseName, newValue: Double(finalReps), reps: nil, weight: nil, csvEstimate: true)
                        //print("Exercise: \(exerciseName), New Max Reps Calculated: \(finalReps)")
                    }
                }
                //workoutTemplate.exercises[j].sets = workoutTemplate.exercises[j].setDetails.count
            }
            trainerTemplates[i] = workoutTemplate // Ensure the updated template is saved back
        }
    }
    
    // fix this. ensure all split categories for that day are represented
    private func selectExercisesForDay(dayIndex: Int, totalExercises: Int, workoutFrequency: Int, availableEquipment: [GymEquipment], exerciseData: ExerciseData, workoutWeek: WorkoutWeek, selectedExerciseType: ExerciseType) -> [Exercise] {
        let availableEquipmentNames = availableEquipment.compactMap { EquipmentName(rawValue: $0.name.rawValue) }
        
        // Expand targeted categories
        var targetedCategories = workoutWeek.categoryForDay(index: dayIndex)
        let expandedCategories = targetedCategories.flatMap { category -> [SplitCategory] in
            if let subCategories = SplitCategory.muscles[category] {
                return subCategories.map { SplitCategory(rawValue: $0.rawValue) ?? category }
            }
            return [category]
        }
        targetedCategories.append(contentsOf: expandedCategories)
        
        print("Targeted categories for day \(dayIndex): \(targetedCategories)")
        
        let userStrengthValue = strengthLevel.strengthValue
        
        // Helper to determine if an exercise matches the bodyweight preference based on the selectedExerciseType.
        func matchesBodyweight(for exercise: Exercise) -> Bool {
            switch selectedExerciseType {
            case .default:
                // No filtering; all exercises are acceptable.
                return true
            case .bodyweightOnly:
                // Allow only exercises that are bodyweight (does not use weight).
                return !exercise.usesWeight
            case .excludeBodyweight:
                // Allow only exercises that require weights.
                return exercise.usesWeight
            }
        }
        
        // Filter exercises for the day based on multiple criteria.
        let exercisesForDay = exerciseData.allExercises.filter { exercise in
            // Handle optional groupCategory safely.
            let matchesCategory = targetedCategories.contains(.all) ||
                (exercise.groupCategory != nil && targetedCategories.contains(where: { $0 == exercise.groupCategory })) ||
                targetedCategories.contains(exercise.splitCategory)
            
            let equipmentAvailable = exercise.equipmentRequired.allSatisfy { equipment in
                availableEquipmentNames.contains(equipment) ||
                availableEquipment.contains { gymEquipment in
                    gymEquipment.alternativeEquipment?.contains(equipment) ?? false
                }
            }
            
            let matchesDifficulty = ExerciseDifficulty.getDifficultyValue(for: exercise.difficulty) <= userStrengthValue
            let matchesBodyweightPreference = matchesBodyweight(for: exercise)
            
            return matchesCategory &&
                   equipmentAvailable &&
                   !dislikedExercises.contains(exercise.name) &&
                   matchesDifficulty &&
                   matchesBodyweightPreference
        }
        
        print("Filtered exercises for day \(dayIndex): \(exercisesForDay.map { $0.name })")
        
        // Prioritize favorited exercises.
        let favoritedExercisesForDay = exercisesForDay.filter { favoriteExercises.contains($0.name) }
        let nonFavoritedExercisesForDay = exercisesForDay.filter { !favoriteExercises.contains($0.name) }
        
        // Separate into compound and isolation.
        let compoundExercises = favoritedExercisesForDay.filter { $0.exDistinction == .compound } +
                                nonFavoritedExercisesForDay.filter { $0.exDistinction == .compound }
        let isolationExercises = favoritedExercisesForDay.filter { $0.exDistinction == .isolation } +
                                 nonFavoritedExercisesForDay.filter { $0.exDistinction == .isolation }
        
        // Combine exercises with compound prioritized.
        var combinedExercises = compoundExercises + isolationExercises
        combinedExercises = exerciseData.distributeExercisesEvenly(combinedExercises)
        
        // Select the required number of exercises.
        var selectedExercises = Array(combinedExercises.prefix(totalExercises))
        
        // Add additional exercises if needed.
        if selectedExercises.count < totalExercises {
            let additionalExercisesNeeded = totalExercises - selectedExercises.count
            let additionalExercises = exerciseData.allExercises.filter { exercise in
                let matchesCategory = targetedCategories.contains(.all) ||
                    (exercise.groupCategory != nil && targetedCategories.contains(where: { $0 == exercise.groupCategory })) ||
                    targetedCategories.contains(exercise.splitCategory)
                
                let equipmentAvailable = exercise.equipmentRequired.allSatisfy { equipment in
                    availableEquipmentNames.contains(equipment)
                }
                
                let matchesBodyweightPreference = matchesBodyweight(for: exercise)
                
                return matchesCategory && equipmentAvailable && matchesBodyweightPreference
            }
            .filter { !selectedExercises.contains($0) }
            .prefix(additionalExercisesNeeded)
            
            selectedExercises.append(contentsOf: additionalExercises)
        }
        
        return selectedExercises
    }

    func scheduleNotification(for workoutTemplate: WorkoutTemplate) -> [String] {
        var notificationIDs: [String] = []
        let calendar = Calendar.current
        let now = Date() // Get the current date and time
        let categories: String = SplitCategory.concatenateCategories(for: workoutTemplate.categories)
        
        // Safely unwrap workoutTemplate.date
        guard let workoutDate = workoutTemplate.date else {
            print("No valid date for \(workoutTemplate.name). Notifications will not be scheduled.")
            return notificationIDs
        }
        
        // Check if notifications are allowed and if they should be scheduled before the planned time
        if !allowedNotifications || !notifyBeforePlannedTime {
            return notificationIDs
        }
        
        if useDateOnly {
            // Schedule notifications at 9 AM and 6 PM
            if let morningDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: workoutDate), morningDate > now {
                notificationIDs.append(scheduleNotificationRequest(
                    title: "You have a Workout Today!",
                    body: "You have a \(categories) workout today. Don't forget!",
                    triggerDate: morningDate,
                    workoutName: workoutTemplate.name
                ))
            }
            
            if let eveningDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: workoutDate), eveningDate > now {
                notificationIDs.append(scheduleNotificationRequest(
                    title: "Workout Incomplete",
                    body: "There's still time to complete your \(categories) workout. You got this!",
                    triggerDate: eveningDate,
                    workoutName: workoutTemplate.name
                ))
            }
        } else {
            if notificationTimes.isEmpty {
                // Default notifications (Workout time + 1 hour before)
                if workoutDate > now {
                    notificationIDs.append(scheduleNotificationRequest(
                        title: "It's Workout Time!",
                        body: "Your \(categories) workout is now!",
                        triggerDate: workoutDate,
                        workoutName: workoutTemplate.name
                    ))
                }
                
                if let oneHourBeforeDate = calendar.date(byAdding: .hour, value: -1, to: workoutDate), oneHourBeforeDate > now {
                    notificationIDs.append(scheduleNotificationRequest(
                        title: "Upcoming Workout Reminder",
                        body: "Your \(categories) workout is in one hour. Get ready!",
                        triggerDate: oneHourBeforeDate,
                        workoutName: workoutTemplate.name
                    ))
                }
            } else {
                // Schedule notifications based on user's `notificationTimes`
                for timeInterval in notificationTimes {
                    let notificationDate = workoutDate.addingTimeInterval(-timeInterval) // Subtract user-defined time
                    if notificationDate > now {
                        let formattedTime = formatTimeInterval(timeInterval) // Helper function for formatting
                        
                        notificationIDs.append(scheduleNotificationRequest(
                            title: "Upcoming Workout Reminder",
                            body: "Your \(categories) workout is in \(formattedTime). Get ready!",
                            triggerDate: notificationDate,
                            workoutName: workoutTemplate.name
                        ))
                    }
                }
            }
        }
        return notificationIDs
    }
    
    private func scheduleNotificationRequest(title: String, body: String, triggerDate: Date, workoutName: String) -> String {
        let calendar = Calendar.current
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        let requestID = UUID().uuidString
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(workoutName) at \(formatDate(triggerDate))")
            }
        }
        return requestID
    }
    
    func removeNotifications(for workoutTemplate: WorkoutTemplate) {
        print("Attempting to remove notifications with IDs: \(workoutTemplate.notificationIDs)")
        
        // Remove pending notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: workoutTemplate.notificationIDs)
        
        // Clear notification IDs in the template
        //saveTemplate(template: workoutTemplate, shouldRemoveNotifications: true)
        if let userTemplateIndex = userTemplates.firstIndex(where: { $0.id == workoutTemplate.id }) {
            userTemplates[userTemplateIndex].notificationIDs.removeAll()
            saveSingleVariableToFile(\.userTemplates, for: .userTemplates)
        } else if let trainerTemplateIndex = trainerTemplates.firstIndex(where: { $0.id == workoutTemplate.id }) {
            trainerTemplates[trainerTemplateIndex].notificationIDs.removeAll()
            saveSingleVariableToFile(\.trainerTemplates, for: .trainerTemplates)
        }

        // Fetch pending notifications to verify
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let remainingIDs = requests.map { $0.identifier }
            print("Remaining pending notifications: \(remainingIDs)")
        }
        print("Removed notifications for \(workoutTemplate.name)")
    }
    
    func checkAndUpdateAge() {
         let calendar = Calendar.current
         let currentDate = Date()
         let ageComponents = calendar.dateComponents([.year], from: dob, to: currentDate)
         let calculatedAge = ageComponents.year ?? age
         
         if calculatedAge != age {
             age = calculatedAge
         }
     }
}
