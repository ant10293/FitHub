

//
//  UserData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//
import SwiftUI
import Foundation
import Combine

final class UserData: ObservableObject, Codable {
    static private let jsonKey: String = "UserData.json"
    @Published var profile          = Profile()
    @Published var physical         = PhysicalStats()
    @Published var workoutPrefs     = WorkoutPreferences()
    @Published var setup            = Setup()
    @Published var settings         = Settings()
    @Published var evaluation       = Evaluation()
    @Published var sessionTracking  = SessionTracking()
    @Published var workoutPlans     = WorkoutPlans()
    
    // MARK: – Non-persisting variables
    @Published var isWorkingOut: Bool = false
    @Published var disableTabView: Bool = false
    @Published var isGeneratingWorkout: Bool = false // set it to true before starting, and set it back to false after the background save completes
    @Published var showingChangelog: Bool = false
    @Published var currentChangelog: WorkoutChangelog?
    
    init(){}

    // MARK: – Persistence Logic
    enum CodingKeys: CodingKey {
        case profile, physical, workoutPrefs, setup, settings,
             evaluation, sessionTracking, workoutPlans
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile         = try c.decode(Profile.self,            forKey: .profile)
        physical        = try c.decode(PhysicalStats.self,      forKey: .physical)
        workoutPrefs    = try c.decode(WorkoutPreferences.self, forKey: .workoutPrefs)
        setup           = try c.decode(Setup.self,              forKey: .setup)
        settings        = try c.decode(Settings.self,           forKey: .settings)
        evaluation      = try c.decode(Evaluation.self,         forKey: .evaluation)
        sessionTracking = try c.decode(SessionTracking.self,    forKey: .sessionTracking)
        workoutPlans    = try c.decode(WorkoutPlans.self,       forKey: .workoutPlans)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(profile,         forKey: .profile)
        try c.encode(physical,        forKey: .physical)
        try c.encode(workoutPrefs,    forKey: .workoutPrefs)
        try c.encode(setup,           forKey: .setup)
        try c.encode(settings,        forKey: .settings)
        try c.encode(evaluation,      forKey: .evaluation)
        try c.encode(sessionTracking, forKey: .sessionTracking)
        try c.encode(workoutPlans,    forKey: .workoutPlans)
    }
    
    // Method to load the user data from a file
    static func loadFromFile() -> UserData? {
        return JSONFileManager.shared.loadUserData(from: UserData.jsonKey)
    }
    
    // MARK: saving logic
    /// Save a single stored struct (debounced).
    func saveSingleStructToFile<T: Encodable>(_ keyPath: KeyPath<UserData, T>, for key: CodingKeys, delay: TimeInterval = 0.4) {
        let value = self[keyPath: keyPath]
        JSONFileManager.shared.debouncedSingleFieldSave(value, for: key.stringValue, in: UserData.jsonKey, delay: delay)
    }

    /// Call this when you really need *everything* persisted (debounced).
    func saveToFile(delay: TimeInterval = 0.8) {
        JSONFileManager.shared.debouncedSave(self, to: UserData.jsonKey, delay: delay)
    }

    /// Immediate flush – bypasses debounce. Call sparingly.
    func saveToFileImmediate() {
        JSONFileManager.shared.save(self, to: UserData.jsonKey)
    }
}

extension UserData {
    // FIXME: doesnt always reset
    func resetWorkoutSession(shouldSave: Bool) {
        sessionTracking.activeWorkout = nil // reset the active workout property
        isWorkingOut = false
        //if shouldSave { saveSingleStructToFile(\.sessionTracking, for: .sessionTracking) }
    }

    func deleteArchivedTemplate(at idx: Int) {
        NotificationManager.remove(ids: workoutPlans.archivedTemplates[idx].notificationIDs)
        workoutPlans.archivedTemplates.remove(at: idx)
        //saveSingleStructToFile(\.workoutPlans, for: .workoutPlans)
    }
    
    func deleteTrainerTemplate(at offsets: IndexSet) {
        guard let idx = offsets.first, workoutPlans.trainerTemplates.indices.contains(idx) else { return }
        deleteTrainerTemplate(at: idx)
    }
    
    func deleteTrainerTemplate(at idx: Int) {
        NotificationManager.remove(ids: workoutPlans.trainerTemplates[idx].notificationIDs)
        workoutPlans.trainerTemplates.remove(at: idx)
        //saveSingleStructToFile(\.workoutPlans, for: .workoutPlans)
    }
    
    func deleteUserTemplate(at offsets: IndexSet) {
        guard let idx = offsets.first, workoutPlans.userTemplates.indices.contains(idx) else { return }
        deleteUserTemplate(at: idx)
    }
    
    func deleteUserTemplate(at idx: Int) {
        NotificationManager.remove(ids: workoutPlans.userTemplates[idx].notificationIDs)
        workoutPlans.userTemplates.remove(at: idx)
        //saveSingleStructToFile(\.workoutPlans, for: .workoutPlans)
    }
    
    func addUserTemplate(template: WorkoutTemplate, shouldSave: Bool = true) {
        var newTemplate = template

        if template.date != nil {
            let notificationIDs = scheduleNotification(for: template) // Schedule notifications and get the IDs
            newTemplate.notificationIDs.append(contentsOf: notificationIDs) // Append notification IDs
        }
        workoutPlans.userTemplates.append(newTemplate)
        //if shouldSave { saveSingleStructToFile(\.workoutPlans, for: .workoutPlans) }
    }
    
    // MARK: new func to be called in WorkoutVM to update non progression changes to template
    func updateTmplExSet(templateID: WorkoutTemplate.ID, exerciseID: Exercise.ID, setDetail: SetDetail) {
        if let (template, index, location) = getTemplate(templateID: templateID) {
            var tmpl = template
            
            if let exIdx = tmpl.exercises.firstIndex(where: { $0.id == exerciseID }) {
                var exercise = tmpl.exercises[exIdx]
                
                if let setIdx = exercise.setDetails.firstIndex(where: { $0.id == setDetail.id }) {
                    var sd = exercise.setDetails[setIdx]
                    // only save if there were changes to set load or planned
                    if sd.load != setDetail.load || sd.planned != setDetail.planned {
                        sd.load = setDetail.load
                        sd.planned = setDetail.planned
                        exercise.setDetails[setIdx] = sd
                        tmpl.exercises[exIdx] = exercise
                        let updated = updateTemplate(template: tmpl, index: index, location: location)
                        //if updated { saveSingleStructToFile(\.workoutPlans, for: .workoutPlans) }
                    }
                }
            }
        }
    }
    
    func updateTemplate(
        template: WorkoutTemplate,
        overwrite: Bool = true,
        shouldRemoveNotifications: Bool = false,
        shouldRemoveDate: Bool = false,
        shouldSave: Bool = true
    ) -> WorkoutTemplate {
        if let (foundTmpl, index, location) = getTemplate(templateID: template.id) {
            var tmpl = overwrite ? template : foundTmpl
            if shouldRemoveNotifications { tmpl.notificationIDs.removeAll() }
            if shouldRemoveDate { tmpl.date = nil }
            let updated = updateTemplate(template: tmpl, index: index, location: location)
            //if shouldSave, updated { saveSingleStructToFile(\.workoutPlans, for: .workoutPlans) }
            return tmpl
        }
        
        return template
    }
    
    private func getTemplate(templateID: WorkoutTemplate.ID) -> (WorkoutTemplate, Int, TemplateLocation)? {
        if let idx = workoutPlans.userTemplates.firstIndex(where: { $0.id == templateID }) {
            return (workoutPlans.userTemplates[idx], idx,  .user)
        }
        if let idx = workoutPlans.trainerTemplates.firstIndex(where: { $0.id == templateID }) {
            return  (workoutPlans.trainerTemplates[idx], idx, .trainer)
        }
        return nil
    }
    
    private func updateTemplate(template: WorkoutTemplate, index: Int, location: TemplateLocation) -> Bool {
        switch location {
        case .user: workoutPlans.userTemplates[index] = template; return true
        case .trainer: workoutPlans.trainerTemplates[index] = template; return true
        default: return false
        }
    }
    
    func getValidMeasurements() -> [MeasurementType] {
        var measurements: [MeasurementType] = []
        
        for measurement in MeasurementType.allCases {
            if physical.currentMeasurements[measurement] != nil {
                measurements.append(measurement)
            }
        }
        return measurements
    }
    
    func updateMeasurementValue(for type: MeasurementType, with newValue: Double, shouldSave: Bool) {
        if newValue <= 0 { return }
        let measurementValue = type.getMeasurmentValue(value: newValue)
        
        if let currentMeasurement = physical.currentMeasurements[type] {
            if physical.pastMeasurements[type] == nil {
                physical.pastMeasurements[type] = []
            }
            physical.pastMeasurements[type]?.append(currentMeasurement)
        }
        physical.currentMeasurements[type] = Measurement(type: type, entry: measurementValue, date: Date())
        //if shouldSave { saveSingleStructToFile(\.physical, for: .physical) }
    }
            
    func currentMeasurementValue(for type: MeasurementType) -> MeasurementValue { physical.currentMeasurements[type]?.entry ?? type.getMeasurmentValue(value: 0) }
    
    func getWorkoutDates() -> [Date] { workoutPlans.completedWorkouts.map(\.date) }

    func getPlannedWorkoutDates() -> [Date] { (workoutPlans.trainerTemplates + workoutPlans.userTemplates).compactMap(\.date) }

    func getAllPlannedWorkoutDates() -> [Date] { datesForTemplates(workoutPlans.trainerTemplates + workoutPlans.userTemplates) }

    private func datesForTemplates(_ templates: [WorkoutTemplate]) -> [Date] {
        var unique = Set<Date>()   // avoids double-marking the same day

        for tpl in templates {
            if let d = tpl.date {
                unique.insert(d)
            } else if
                let completed = workoutPlans.completedWorkouts
                    .filter({ $0.template.id == tpl.id })
                    .sorted(by: { $0.date > $1.date })      // most recent first
                    .first
            {
                unique.insert(completed.date)
            }
        }
        return Array(unique).sorted()     // keep ‘em in order
    }
    
    func removePlannedWorkoutDate(templateID: WorkoutTemplate.ID, removeDate: Bool, date: Date) {
        if let (foundTmpl, _, _) = getTemplate(templateID: templateID),
            let templateDate = foundTmpl.date, CalendarUtility.shared.isDate(templateDate, inSameDayAs: date) || templateDate < date
        {
            // only remove notifications if planned date is today or has already passed && only remove date if there wasn't a workout already completed today
            removeTemplateNotifications(for: foundTmpl, removeDate: removeDate, shouldSave: false)
        }
    }
    
    private func removeTemplateNotifications(for template: WorkoutTemplate, removeDate: Bool, shouldSave: Bool) {
        NotificationManager.remove(ids: template.notificationIDs)
        _ = updateTemplate(template: template, shouldRemoveNotifications: true, shouldRemoveDate: removeDate, shouldSave: shouldSave)
        NotificationManager.printAllPendingNotifications() // Fetch pending notifications to verify
    }
    
    func scheduleNotification(for workoutTemplate: WorkoutTemplate) -> [String] {
        let notiIDs = NotificationManager.scheduleNotification(for: workoutTemplate, user: self)
        return notiIDs
    }
    
    func incrementWorkoutStreak(shouldSave: Bool = true) {
        //print("Before Incrementing Workout Streak: \(sessionTracking.workoutStreak)")
        sessionTracking.workoutStreak += 1
        sessionTracking.totalNumWorkouts += 1
        if sessionTracking.workoutStreak > sessionTracking.longestWorkoutStreak {
            sessionTracking.longestWorkoutStreak = sessionTracking.workoutStreak
        }
        //print("After Incrementing Workout Streak: \(sessionTracking.workoutStreak)")
        //if shouldSave { saveToFile() }
    }

    func checkAndUpdateAge() {
        let calculatedAge = CalendarUtility.shared.age(from: profile.dob, to: Date())
        if calculatedAge != profile.age { profile.age = calculatedAge }
    }
}

extension UserData {    
    func calculateDetailedExercise(exerciseData: ExerciseData, equipmentData: EquipmentData, exercise: Exercise, nextWeek: Bool) -> Exercise {
        let rs = RepsAndSets.determineRepsAndSets(
            for: physical.goal,
            customRestPeriod: workoutPrefs.customRestPeriods,
            customRepsRange: workoutPrefs.customRepsRange,
            customSets: workoutPrefs.customSets,
            customDistribution: workoutPrefs.customDistribution
        )
        let input = WorkoutGenerator.Input(
            user: self,
            exerciseData: exerciseData,
            equipmentData: equipmentData,
            saved: [],
            keepCurrentExercises: false,
            nextWeek: nextWeek
        )
         // The generator only needs `user` (self) plus the same arguments
        return WorkoutGenerator().calculateDetailedExercise(
            input: input,
            exercise: exercise,
            repsAndSets: rs,
            overloadFactor: settings.customOverloadFactor ?? 1.0,
            maxUpdated: { update in
                exerciseData.applyPerformanceUpdate(update: update, csvEstimate: true, shouldSave: true)
            }
        )
    }
    
    // House-keep old trainerTemplates – returns exercises we might want to keep
    private func manageOldTemplates() -> [OldTemplate] {
        // Snapshot current templates into OldTemplate
        let saved: [OldTemplate] = workoutPlans.trainerTemplates.map { OldTemplate(template: $0) }

        // Remove all related notifications in one go
        let ids = workoutPlans.trainerTemplates.flatMap(\.notificationIDs)
        NotificationManager.remove(ids: ids)

        return saved
    }

    // Add this method to UserData:
    func showChangelog(_ changelog: WorkoutChangelog) {
        currentChangelog = changelog
        showingChangelog = true
    }
    
    func generateWorkoutPlan(
        exerciseData: ExerciseData,
        equipmentData: EquipmentData,
        keepCurrentExercises: Bool,
        nextWeek: Bool,
        shouldSave: Bool = true,
        onDone: @escaping () -> Void = {}
    ) {
        isGeneratingWorkout = true
        resetWorkoutSession(shouldSave: false)
        
        let saved = manageOldTemplates()
        let generator = WorkoutGenerator()
        let input = WorkoutGenerator.Input(
            user: self,
            exerciseData: exerciseData,
            equipmentData: equipmentData,
            saved: saved,
            keepCurrentExercises: keepCurrentExercises,
            nextWeek: nextWeek
        )

        DispatchQueue.global(qos: .userInitiated).async {
            let output = generator.generate(from: input)

            DispatchQueue.main.async {
                // Start from generator output
                var newTemplates = output.trainerTemplates

                // Schedule notifications and write the IDs back by index
                for i in newTemplates.indices {
                    let ids = self.scheduleNotification(for: newTemplates[i]) // @MainActor
                    newTemplates[i].notificationIDs = ids
                }
                                
                self.workoutPlans.trainerTemplates = newTemplates
                self.workoutPlans.workoutsStartDate = output.workoutsStartDate
                self.workoutPlans.workoutsCreationDate = output.workoutsCreationDate

                if let old = self.workoutPlans.logFileName { _ = Logger.deleteLog(named: old) }
                self.workoutPlans.logFileName = output.logFileName

                exerciseData.applyPerformanceUpdates(updates: output.updatedMax, csvEstimate: true)
         
                //if shouldSave { self.saveToFile() }

                self.isGeneratingWorkout = false
                
                // 🆕 SHOW CHANGELOG IF IT'S NEXT WEEK
                if nextWeek, let changelog = output.changelog {
                    self.showChangelog(changelog)
                }
                                
                onDone()
            }
        }
    }
}
