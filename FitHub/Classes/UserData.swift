

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
    private let saveQueue = DispatchQueue(label: "com.FitHubApp.UserData.save")
    
    /// Queue used for **scheduling** (not for the actual work)
    private let debounceQueue = DispatchQueue(label: "com.FitHubApp.UserData.debounce")

    /// One pending task per‑key; when you ask to save the same key twice in quick
    /// succession the first task is cancelled and replaced.
    private var pendingSingleSaves: [CodingKeys: DispatchWorkItem] = [:]

    /// One pending task for the “save the whole object” call
    private var pendingFullSave: DispatchWorkItem?
    
    @Published var profile          = Profile()          
    @Published var physical         = PhysicalStats()
    @Published var workoutPrefs     = WorkoutPreferences()
    @Published var setup            = Setup()
    @Published var settings         = Settings()
    @Published var evaluation       = Evaluation()
    @Published var sessionTracking  = SessionTracking()
    @Published var workoutPlans     = WorkoutPlans()
    @Published var isWorkingOut: Bool = false

    enum CodingKeys: CodingKey {
        case profile, physical, workoutPrefs, setup, settings,
             evaluation, sessionTracking, workoutPlans
    }
    
    init(){ }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile         = try c.decode(Profile.self,            forKey: .profile)
        physical        = try c.decode(PhysicalStats.self,       forKey: .physical)
        workoutPrefs    = try c.decode(WorkoutPreferences.self,  forKey: .workoutPrefs)
        setup           = try c.decode(Setup.self,               forKey: .setup)
        settings        = try c.decode(Settings.self,            forKey: .settings)
        evaluation      = try c.decode(Evaluation.self,          forKey: .evaluation)
        sessionTracking = try c.decode(SessionTracking.self,     forKey: .sessionTracking)
        workoutPlans    = try c.decode(WorkoutPlans.self,        forKey: .workoutPlans)
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
    
    struct AnyEncodable: Encodable {
        private let encodeFunc: (Encoder) throws -> Void
        init<T: Encodable>(_ wrapped: T) { self.encodeFunc = wrapped.encode }
        func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
    }
    
    /// Save a single stored struct (debounced).
    func saveSingleStructToFile<T: Encodable>(_ keyPath: KeyPath<UserData, T>, for key: CodingKeys, delay: TimeInterval = 0.4) {
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

    func uniqueTemplateName(initialName: String, from templates: [WorkoutTemplate]) -> String {
        let existing = Set(templates.map { $0.name })

        // 1️⃣  If the candidate is free, keep it
        guard existing.contains(initialName) else { return initialName }

        // 2️⃣  Split off an optional trailing integer
        let parts = initialName.split(separator: " ")
        var base  = initialName
        var start = 2                                    // default suffix

        if let last = parts.last, let n = Int(last) {
            // “New Template 2”  -> base = “New Template”, start = 3
            base  = parts.dropLast().joined(separator: " ")
            start = n + 1
        }

        // 3️⃣  Bump until we hit a free slot
        var i = start
        while true {
            let candidate = "\(base) \(i)"
            if !existing.contains(candidate) { return candidate }
            i += 1
        }
    }
    
    func resetExercisesInTemplate(for template: WorkoutTemplate, shouldRemoveDate: Bool = false, shouldSave: Bool = true) {
        sessionTracking.activeWorkout = nil                  // reset the active workout property
        saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)

        var updatedTemplate = template         // Create a mutable copy of the template
        
        // Loop through each exercise in the template and reset its state
        for exerciseIndex in updatedTemplate.exercises.indices {
            updatedTemplate.exercises[exerciseIndex].currentSet = 1
            updatedTemplate.exercises[exerciseIndex].timeSpent = 0
            updatedTemplate.exercises[exerciseIndex].isCompleted = false
            
            // Reset repsCompleted & rpe for each setDetail in the exercise
            for setIndex in updatedTemplate.exercises[exerciseIndex].setDetails.indices {
                updatedTemplate.exercises[exerciseIndex].setDetails[setIndex].repsCompleted = nil
                updatedTemplate.exercises[exerciseIndex].setDetails[setIndex].rpe = nil
            }
            
            // Reset repsCompleted & rpe for each warmup set in the exercise
            for setIndex in updatedTemplate.exercises[exerciseIndex].warmUpDetails.indices {
                updatedTemplate.exercises[exerciseIndex].warmUpDetails[setIndex].repsCompleted = nil
                //updatedTemplate.exercises[exerciseIndex].warmUpDetails[setIndex].rpe = nil
            }
        }
        _ = updateTemplate(template: updatedTemplate, shouldRemoveDate: shouldRemoveDate, shouldSave: shouldSave)
    }
    
    func deleteTrainerTemplate(at offsets: IndexSet) {
        guard let idx = offsets.first, workoutPlans.trainerTemplates.indices.contains(idx) else { return }
        deleteTrainerTemplate(at: idx)
    }
    
    func deleteTrainerTemplate(at idx: Int) {
        _ = removeTemplateNotifications(for: workoutPlans.trainerTemplates[idx])
        workoutPlans.trainerTemplates.remove(at: idx)
        saveSingleStructToFile(\.workoutPlans, for: .workoutPlans)
    }
    
    func deleteUserTemplate(at offsets: IndexSet) {
        guard let idx = offsets.first, workoutPlans.userTemplates.indices.contains(idx) else { return }
        deleteUserTemplate(at: idx)
    }
    
    func deleteUserTemplate(at idx: Int) {
        _ = removeTemplateNotifications(for: workoutPlans.userTemplates[idx])
        workoutPlans.userTemplates.remove(at: idx)
        saveSingleStructToFile(\.workoutPlans, for: .workoutPlans)
    }
    
    func addUserTemplate(template: WorkoutTemplate, shouldSave: Bool = true) {
        var newTemplate = template

        if template.date != nil {
            // Schedule notifications and get the IDs
            let notificationIDs = scheduleNotification(for: template)
            newTemplate.notificationIDs.append(contentsOf: notificationIDs) // Append notification IDs
        }
        workoutPlans.userTemplates.append(newTemplate)
        if shouldSave { saveSingleStructToFile(\.workoutPlans, for: .workoutPlans) }
    }
    
    func updateTemplate(template: WorkoutTemplate, shouldRemoveNotifications: Bool = false, shouldRemoveDate: Bool = false, shouldSave: Bool = true) -> WorkoutTemplate {
        // 1️⃣  Try to update an existing entry in workoutPlans.userTemplates
        if let idx = workoutPlans.userTemplates.firstIndex(where: { $0.id == template.id }) {
            var tmpl = template                     // make a local copy we can mutate
            if shouldRemoveNotifications { tmpl.notificationIDs.removeAll() }
            if shouldRemoveDate { tmpl.date = nil }
            workoutPlans.userTemplates[idx] = tmpl
            if shouldSave { saveSingleStructToFile(\.workoutPlans, for: .workoutPlans) }
            
            return workoutPlans.userTemplates[idx]
        }
        
        // 2️⃣  Try workoutPlans.trainerTemplates next
        if let idx = workoutPlans.trainerTemplates.firstIndex(where: { $0.id == template.id }) {
            var tmpl = template                     // make a local copy we can mutate
            if shouldRemoveNotifications { tmpl.notificationIDs.removeAll() }
            if shouldRemoveDate { tmpl.date = nil }
            workoutPlans.trainerTemplates[idx] = tmpl
            if shouldSave { saveSingleStructToFile(\.workoutPlans, for: .workoutPlans) }
            return workoutPlans.trainerTemplates[idx]
        }
        
        return template
    }
    
    /// Returns `true` if *every* piece of required equipment can be satisfied
    /// either directly or via a declared alternative.
    func canPerformExercise(_ exercise: Exercise, equipmentData: EquipmentData) -> Bool {
        // 1️⃣  Gear the user explicitly owns
        let owned: Set<String> = Set(evaluation.equipmentSelected.map { normalize($0.name) })
        
        // 2️⃣  Alternatives provided BY the gear the user owns
        let altFromOwned: Set<String> = Set(
            evaluation.equipmentSelected
                .compactMap(\.alternativeEquipment)     // [[String]] or [String]?
                .flatMap { $0 }
                .map(normalize)
        )
        
        let allowed = owned.union(altFromOwned)
        
        // 3️⃣  Build lookup of each *required* item → its own alternatives
        let neededGear = equipmentData.equipmentForExercise(exercise)     // [GymEquipment]
        let altForRequired: [String: Set<String>] = neededGear.reduce(into: [:]) { dict, gear in
            dict[normalize(gear.name)] = Set((gear.alternativeEquipment ?? []).map(normalize))
        }
        
        // 4️⃣  Check every requirement
        for raw in exercise.equipmentRequired {          // [String]
            let req = normalize(raw)
            
            // Own the exact item?
            if allowed.contains(req) { continue }
            
            // Own an acceptable alternative?
            if let altSet = altForRequired[req], !owned.isDisjoint(with: altSet) { continue }
            
            // Missing both required item and its alternatives
            return false
        }
        
        return true
    }
    
    func incrementWorkoutStreak(shouldSave: Bool = true) {
        print("Before Incrementing Workout Streak: \(sessionTracking.workoutStreak)")
        sessionTracking.workoutStreak += 1
        sessionTracking.totalNumWorkouts += 1
        if sessionTracking.workoutStreak > sessionTracking.longestWorkoutStreak {
            sessionTracking.longestWorkoutStreak = sessionTracking.workoutStreak
        }
        print("After Incrementing Workout Streak: \(sessionTracking.workoutStreak)")
        if shouldSave { saveToFile() }
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
        let currentDate = Date()
        
        if let currentMeasurement = physical.currentMeasurements[type] {
            if physical.pastMeasurements[type] == nil {
                physical.pastMeasurements[type] = []
            }
            physical.pastMeasurements[type]?.append(currentMeasurement)
            if shouldSave { saveSingleStructToFile(\.physical, for: .physical) }
        }
        physical.currentMeasurements[type] = Measurement(type: type, value: newValue, date: currentDate)
        if shouldSave { saveSingleStructToFile(\.physical, for: .physical) }
    }
    
    func currentMeasurementValue(for type: MeasurementType) -> Double { return physical.currentMeasurements[type]?.value ?? 0.0 }
    
    func getWorkoutDates() -> [Date] { workoutPlans.completedWorkouts.map(\.date) }

    func getPlannedWorkoutDates() -> [Date] { (workoutPlans.trainerTemplates + workoutPlans.userTemplates).compactMap(\.date) }

    func getAllPlannedWorkoutDates() -> [Date] { datesForTemplates(workoutPlans.trainerTemplates + workoutPlans.userTemplates) }

    private func datesForTemplates(_ templates: [WorkoutTemplate]) -> [Date] {
        var unique = Set<Date>()          // avoids double-marking the same day

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
    
    func removePlannedWorkoutDate(template: WorkoutTemplate, removeNotifications: Bool, removeDate: Bool, date: Date) -> (Bool, WorkoutTemplate?) {
        let cal = Calendar.current

        if let templateDate = template.date,
           cal.isDate(templateDate, inSameDayAs: date) || templateDate < date {
            let template = removeTemplateNotifications(for: template, removeNotifications: removeNotifications, removeDate: removeDate, shouldSave: false)
            return (true, template)
        }

        // ── 3.  Nothing matched ───────────────────────────────────────────
        return (false, nil)
    }
    
    func calculateDetailedExercise(exerciseData: ExerciseData, equipmentData: EquipmentData, exercise: Exercise, repsAndSets: RepsAndSets, nextWeek: Bool) -> Exercise {
        // The generator only needs `user` (self) plus the same arguments
        return WorkoutGenerator().calculateDetailedExercise(
            input: WorkoutGenerator.Input(user: self, exerciseData: exerciseData, equipmentData: equipmentData, keepCurrentExercises: false, nextWeek: nextWeek),
            exercise: exercise,
            repsAndSets: repsAndSets,
            maxUpdated: {
                exerciseData.savePerformanceData()
            }
        )
    }
    
    func applyProgressiveOverload(exercise: Exercise, equipmentData: EquipmentData) -> [SetDetail] {
        return WorkoutGenerator().applyProgressiveOverload(
            equipmentData: equipmentData,
            exercise: exercise,
            period: settings.progressiveOverloadPeriod,
            style: settings.progressiveOverloadStyle,
            roundingPreference: settings.roundingPreference
        )
    }
    
    func generateWorkoutPlan(exerciseData: ExerciseData, equipmentData: EquipmentData, keepCurrentExercises: Bool, nextWeek: Bool, shouldSave: Bool = true) {
        let generator = WorkoutGenerator()
        let output = generator.generate(from: .init(
            user: self,
            exerciseData: exerciseData,
            equipmentData: equipmentData,
            keepCurrentExercises: keepCurrentExercises,
            nextWeek: nextWeek)
        )
        
        // mutate *only* the pieces that belong on UserData
        workoutPlans.trainerTemplates = output.trainerTemplates
        workoutPlans.workoutsStartDate = output.workoutsStartDate
        workoutPlans.workoutsCreationDate = output.workoutsCreationDate
        
        if let name = workoutPlans.logFileName {
           _ = Logger.deleteLog(named: name) 
        }
        workoutPlans.logFileName = output.logFileName
        // Persist performance data + user file if required
        if output.updatedMax { exerciseData.savePerformanceData() }
        if shouldSave { saveToFile() }
    }
    
    func scheduleNotification(for workoutTemplate: WorkoutTemplate) -> [String] {
        let notiIDs = NotificationManager.scheduleNotification(for: workoutTemplate, user: self)
        return notiIDs
    }

    func removeTemplateNotifications(for template: WorkoutTemplate, removeNotifications: Bool = true, removeDate: Bool = true, shouldSave: Bool = true) -> WorkoutTemplate {
        NotificationManager.remove(ids: template.notificationIDs)
        let updatedTemplate = updateTemplate(template: template, shouldRemoveNotifications: removeNotifications, shouldRemoveDate: removeDate, shouldSave: shouldSave)

        // Fetch pending notifications to verify
        NotificationManager.printAllPendingNotifications()
        
        return updatedTemplate
    }

    func checkAndUpdateAge() {
        let calendar = Calendar.current
        let calculatedAge = calendar.dateComponents([.year], from: profile.dob, to: Date()).year ?? profile.age
        if calculatedAge != profile.age { profile.age = calculatedAge }
    }
}




