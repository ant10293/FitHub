//
//  ExerciseData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

final class ExerciseData: ObservableObject {
    private let saveQueue = DispatchQueue(label: "ExerciseSaveQueue")

    private let bundledExercises: [Exercise]          // read-only
    @Published private(set) var userExercises: [Exercise]  // can mutate & save
   
    // MARK: - Public unified view
    var allExercises: [Exercise] { bundledExercises + userExercises }
       
    var allExercisePerformance: [UUID: ExercisePerformance] = [:]
    
    init() {
        bundledExercises = ExerciseData.loadBundledExercises(from: "exercises.json")
        userExercises = ExerciseData.loadUserExercises(from: "user_exercises.json")
        loadPerformanceData(from: "performance.json")
    }
    
    private static func loadBundledExercises(from file: String) -> [Exercise] {
        do {
            let seed: [InitExercise] = try Bundle.main.decode(file)
            return seed.map(Exercise.init(from:))
        } catch {
            fatalError("❌ Couldn’t load bundled exercises: \(error)")
        }
    }

    private static func loadUserExercises(from file: String) -> [Exercise] {
        let url = getDocumentsDirectory().appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else { return [] }
        do { return try JSONDecoder().decode([Exercise].self, from: data) }
        catch {
            print("⚠️  Corrupt user file – starting fresh. \(error)")
            return []
        }
    }
    
    /*private func save() {
        do {
            // 2️⃣ Destination file • …/Documents/exercises.json
            let fileURL = getDocumentsDirectory().appendingPathComponent("exercises.json")


            // 3️⃣ Encode & write
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(allExercises1)

            try data.write(to: fileURL, options: .atomic)

            #if DEBUG
            print("✅ Saved \(allExercises1.count) exercises to \(fileURL.path)")
            #endif
        } catch {
            // Handle or surface the error as you prefer
            print("❌ Failed to save exercises:", error.localizedDescription)
        }
    }*/
    
    private func loadPerformanceData(from fileName: String) {
        let filename = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: filename)
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601
            let performanceData = try jsonDecoder.decode([ExercisePerformance].self, from: data)
            allExercisePerformance = Dictionary(uniqueKeysWithValues: performanceData.map { ($0.id, $0) })
        } catch {
            print("Could not load performance data: \(error.localizedDescription)")
        }
    }
    
    func savePerformanceData() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    print("Instance was deinitialized before the operation could complete.")
                }
                return
            }
            
            let filename = getDocumentsDirectory().appendingPathComponent("performance.json")
            let performanceArray = Array(self.allExercisePerformance.values)
            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.dateEncodingStrategy = .iso8601
                let data = try jsonEncoder.encode(performanceArray)
                try data.write(to: filename, options: [.atomicWrite, .completeFileProtection])
                DispatchQueue.main.async {
                    print("Successfully saved performance data to \(filename.path)")
                }
            } catch {
                DispatchQueue.main.async {
                    print("Failed to save performance data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveUserExercises() {
        saveQueue.async {
            do {
                let url = getDocumentsDirectory().appendingPathComponent("user_exercises.json")
                let data = try JSONEncoder().encode(self.userExercises)
                try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
                #if DEBUG
                print("✅ Saved \(self.userExercises.count) user exercises.")
                #endif
            } catch {
                print("❌ Failed saving user exercises:", error.localizedDescription)
            }
        }
    }
    
    // MARK: – Mutations
    func addExercise(_ newExercise: Exercise) {
        guard !allExercises.contains(where: { $0.id == newExercise.id }) else { return }
        userExercises.append(newExercise)
        persistUserExercises()
    }

    func replace(_ old: Exercise, with updated: Exercise) {
        userExercises.removeAll { $0.id == old.id }
        userExercises.append(updated)
        persistUserExercises()
    }

    func removeExercise(_ exercise: Exercise) {
        userExercises.removeAll { $0.id == exercise.id }
        persistUserExercises()
    }
    
    // MARK: – Private helper
    private func persistUserExercises() {
        let snapshot = userExercises                 // value copy, thread-safe
        saveQueue.async {
            let url = getDocumentsDirectory()
                .appendingPathComponent("user_exercises.json")
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url,
                               options: [.atomicWrite, .completeFileProtection])
                #if DEBUG
                print("✅ Saved \(snapshot.count) user exercises.")
                #endif
            } catch {
                print("❌ Failed saving user equipment:", error.localizedDescription)
            }
        }
    }
    
    func isUserExercise(_ exercise: Exercise) -> Bool {
        return userExercises.contains(where: { $0.id == exercise.id })
    }
}

extension ExerciseData {
    
    func filteredExercises(
        searchText: String,
        selectedCategory: CategorySelections,
        templateCategories: [SplitCategory]? = nil,
        templateFilter: Bool = false,
        favoritesOnly: Bool = false,
        dislikedOnly: Bool = false,
        userData: UserData,
        equipmentData: EquipmentData
    ) -> [Exercise] {
        
        // ── 0. Cached constants ───────────────────────────────────────────────
        let removingSet      = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let normalizedSearch = searchText.normalized(removing: removingSet)
        
        let favSet      = Set(userData.evaluation.favoriteExercises)
        let dislikedSet = Set(userData.evaluation.dislikedExercises)
        
        let hideUnequipped = userData.settings.hideUnequippedExercises
        let hideDisliked   = userData.settings.hideDislikedExercises
        let hideDifficult  = userData.settings.hideDifficultExercises
        let maxStrength    = userData.evaluation.strengthLevel.strengthValue
        
        // ── Category matcher (pulled out of the hot loop) ─────────────────────
        func matchesCategory(_ ex: Exercise) -> Bool {
            switch selectedCategory {
                
            // -------- Split selections ---------------------------------------
            case .split(let splitCat):
                let cat        = ex.splitCategory
                let usingTempl = templateFilter
                let templates  = templateCategories ?? []
                
                if splitCat == .all {
                    return usingTempl ? templates.contains(cat) : true
                }
                if splitCat == .arms {
                    return SplitCategory.armsFocus.contains(cat)
                }
                if splitCat == .legs {
                    return SplitCategory.lowerBody.contains(cat)
                }
                if splitCat == .back {
                    if let groupCat = ex.groupCategory {
                        return groupCat == .back
                    } else {
                        return false
                    }
                }
                
                return cat == splitCat || (usingTempl && templates.contains(cat))
                
            // -------- Muscle selections --------------------------------------
            case .muscle(let m):
                return m == .all || ex.primaryMuscles.contains(m)
                
            // -------- Upper / Lower selections -------------------------------
            case .upperLower(let ul):
                return ul == .upperBody ? ex.isUpperBody : ex.isLowerBody
                
            // -------- Push / Pull / Legs selections --------------------------
            case .pushPull(let pp):
                switch pp {
                    case .push: return ex.isPush
                    case .pull: return ex.isPull
                    case .legs: return ex.isLowerBody
                }
                
            // -------- Difficulty selections ----------------------------------
            case .difficulty(let diff):
                return ex.difficulty == diff
                
            // -------- Exercise-type selections -------------------------------
            case .resistanceType(let type):
                switch type {
                    case .bodyweight:  return !ex.type.usesWeight
                    case .weighted:    return  ex.type.usesWeight
                    case .freeWeight:  return  ex.type == .freeWeight
                    case .machine:     return  ex.type == .machine
                   // case .banded:      return ex.type == .banded
                   // case .cardio:      return ex.type == .cardio
                    case .other:       return  ex.type == .other
                    case .any:         return  true
                }
                
            case .effortType(let type):
                switch type {
                    case .compound: return ex.effort == .compound
                    case .isolation: return ex.effort == .isolation
                    case .isometric: return ex.effort == .isometric
                    case .plyometric: return ex.effort == .plyometric
                }
            }
        }
        
        // ── 1. Filter pass ───────────────────────────────────────────────────
        var results: [Exercise] = []
        results.reserveCapacity(allExercises.count)
        
        for ex in allExercises {
            // a) Fav / disliked quick gates
            let isFav       = favSet.contains(ex.id)
            let isDisliked  = dislikedSet.contains(ex.id)
            if favoritesOnly && !isFav { continue }
            if dislikedOnly  && !isDisliked { continue }
            if hideDisliked  &&  isDisliked { continue }
            
            // b) Equipment / difficulty gates
            if hideUnequipped && !userData.canPerformExercise(ex, equipmentData: equipmentData) { continue }
            if hideDifficult && ex.difficulty.strengthValue > maxStrength { continue }
            
            // c) Category gate
            guard matchesCategory(ex) else { continue }
            
            // d) Search-text gate
            if !normalizedSearch.isEmpty {
                let nameNorm   = ex.name.normalized(removing: removingSet)
                let aliasMatch = ex.aliases?.contains(where: {
                    $0.normalized(removing: removingSet).contains(normalizedSearch)
                }) ?? false
                
                guard nameNorm.contains(normalizedSearch) || aliasMatch else { continue }
            }
            
            // Passed all gates → keep it
            results.append(ex)
        }
        
        // ── 2. Sort (items that *start* with query bubble to top) ─────────────
        if !normalizedSearch.isEmpty {
            results.sort { a, b in
                let na = a.name.normalized(removing: removingSet)
                let nb = b.name.normalized(removing: removingSet)
                
                let aStarts = na.hasPrefix(normalizedSearch)
                let bStarts = nb.hasPrefix(normalizedSearch)
                if aStarts != bStarts { return aStarts }   // true first
                return na < nb
            }
        } else {
            results.sort { $0.name < $1.name }
        }
        
        return results
    }
    
    func similarExercises(to exercise: Exercise, user: UserData, equipmentData: EquipmentData, existing: [Exercise], replaced: Set<String>) -> [Exercise] {
        let allExercises        = allExercises
        let exercisePrimarySet  = Set(exercise.primaryMuscles)
        let existingNames       = Set(existing.map(\.name))

        // 1️⃣ strict filter
        var similar = allExercises.filter { candidate in
            guard candidate.name != exercise.name else { return false }

            let candidatePrimarySet = Set(candidate.primaryMuscles)
            let samePrimary   = candidatePrimarySet == exercisePrimarySet
            let equipmentOK   = user.canPerformExercise(exercise, equipmentData: equipmentData)
            let sameDist      = candidate.effort == exercise.effort
            let notExisting   = !existingNames.contains(candidate.name)
            let notReplaced   = !replaced.contains(candidate.name)

            return samePrimary && equipmentOK && sameDist && notExisting && notReplaced
        }

        // 2️⃣ relaxed fallback
        if similar.isEmpty {
            similar = allExercises.filter { candidate in
                guard candidate.name != exercise.name else { return false }

                let candidatePrimarySet = Set(candidate.primaryMuscles)
                let shareAnyPrimary = !candidatePrimarySet.isDisjoint(with: exercisePrimarySet)
                let equipmentOK   = user.canPerformExercise(exercise, equipmentData: equipmentData)
                let notExisting = !existingNames.contains(candidate.name)
                let notReplaced = !replaced.contains(candidate.name)

                return shareAnyPrimary && equipmentOK && notExisting && notReplaced
            }
        }

        return similar
    }
    
    func distributeExercisesEvenly(_ exercises: [Exercise]) -> [Exercise] {
        var distributedExercises: [Exercise] = []
        // Tracks unique combinations of primary and secondary muscle groups.
        var muscleCombinationsUsed: [(primary: Set<SubMuscles>, secondary: Set<SubMuscles>)] = []
        
        // Check if the combination of primary and secondary muscles is unique
        func isUniqueCombination(_ exercise: Exercise) -> Bool {
            let primarySet = Set(exercise.primarySubMuscles ?? [])
            let secondarySet = Set(exercise.secondarySubMuscles ?? [])
            
            for combo in muscleCombinationsUsed {
                if combo.primary == primarySet && combo.secondary == secondarySet {
                    //print("Combination already used: Primary: \(combo.primary), Secondary: \(combo.secondary)")
                    return false
                }
            }
            //print("Combination is unique")
            return true
        }
        
        // Add the combination to the tracking set
        func addCombination(_ exercise: Exercise) {
            let primarySet = Set(exercise.primarySubMuscles ?? [])
            let secondarySet = Set(exercise.secondarySubMuscles ?? [])
            
            muscleCombinationsUsed.append((primary: primarySet, secondary: secondarySet))
            //print("Added combination: Primary: \(primarySet), Secondary: \(secondarySet)")
        }
        
        // Attempt to distribute compound exercises first
        exercises.filter({ $0.effort == .compound }).forEach { exercise in
            //print("Processing compound exercise: \(exercise.name)")
            if isUniqueCombination(exercise) {
                distributedExercises.append(exercise)
                addCombination(exercise)
            }
        }
        
        // Follow with isolation exercises, ensuring no overlap in muscle combinations
        exercises.filter({ $0.effort == .isolation }).forEach { exercise in
            //print("Processing isolation exercise: \(exercise.name)")
            if isUniqueCombination(exercise) {
                distributedExercises.append(exercise)
                addCombination(exercise)
            }
        }
        
        //print("Distributed exercises: \(distributedExercises.map { $0.name })")
        return distributedExercises
    }
    
    // overload func
    func updateExercisePerformance(for exercise: Exercise, newValue: Double, reps: Int? = nil, weight: Double? = nil, csvEstimate: Bool, date: Date? = nil) {
        updateExercisePerformance(for: exercise.id, exerciseName: exercise.name, newValue: newValue, reps: reps, weight: weight, csvEstimate: csvEstimate, date: date)
    }
    
    func updateExercisePerformance(
        for exerciseId: UUID,
        exerciseName: String,
        newValue: Double,
        reps: Int? = nil,
        weight: Double? = nil,
        csvEstimate: Bool,
        date: Date? = nil
    ) {
        let now = date ?? Date()
        let calendar = Calendar.current
        let roundedDate = calendar.startOfDay(for: now)
        
        var repsXweight: RepsXWeight?
        
        if let reps = reps, let weight = weight {
            repsXweight = RepsXWeight(reps: reps, weight: weight)
        }
        
        if var existingPerformance = allExercisePerformance[exerciseId] {
            if csvEstimate {
                existingPerformance.estimatedValue = newValue
            } else {
                // only update if new max is greater than current max
                if let currentMax = existingPerformance.maxValue, newValue > currentMax,
                   let date = existingPerformance.currentMaxDate {
                    
                    let record = MaxRecord(value: currentMax, repsXweight: existingPerformance.repsXweight, date: date)
                    if existingPerformance.pastMaxes != nil {
                        existingPerformance.pastMaxes!.append(record)
                    } else {
                        existingPerformance.pastMaxes = [record]
                    }
                    print("Updated past max for \(exerciseName): \(currentMax) saved with date \(String(describing: existingPerformance.currentMaxDate))")
                }
                
                existingPerformance.maxValue = newValue
                existingPerformance.currentMaxDate = roundedDate
                if let repsWeight = repsXweight {
                    existingPerformance.repsXweight = repsWeight
                    print("New max for \(exerciseName): \(newValue) (\(repsWeight.weight) x \(repsWeight.reps))")
                } else {
                    print("New max for \(exerciseName): \(newValue)")
                }
                existingPerformance.estimatedValue = nil // no need for estimated value is true max value was added
            }
            // Save the updated performance data
            allExercisePerformance[exerciseId] = existingPerformance
            //savePerformanceData()
            print("Performance data for \(exerciseName) saved.")
            
        } else {
            // Create new performance entry if none exists
            var newPerformance = ExercisePerformance(exerciseId: exerciseId)
            if csvEstimate {
                newPerformance.estimatedValue = newValue
            } else {
                newPerformance.maxValue = newValue
                newPerformance.currentMaxDate = roundedDate
                if let repsWeight = repsXweight {
                    newPerformance.repsXweight = repsWeight
                    print("New max for \(exerciseName): \(newValue) (\(repsWeight.weight) x \(repsWeight.reps))")
                }
                newPerformance.estimatedValue = nil // no need for estimated value is true max value was added
            }
            print("New performance entry created for \(exerciseName) with date \(roundedDate)")
            
            allExercisePerformance[exerciseId] = newPerformance
            //savePerformanceData()
            print("New performance data for \(exerciseName) saved.")
        }
    }
    
    func getEstimatedMax(for exerciseId: UUID) -> Double? { allExercisePerformance[exerciseId]?.estimatedValue }
    
    func getMax(for exerciseId: UUID) -> Double? { allExercisePerformance[exerciseId]?.maxValue }
    
    func getPastMaxes(for exerciseId: UUID) -> [MaxRecord] { allExercisePerformance[exerciseId]?.pastMaxes ?? [] }
    
    func getDateForMax(for exerciseId: UUID) -> Date? { allExercisePerformance[exerciseId]?.currentMaxDate }
    
    func exercise(named name: String) -> Exercise? { allExercises.first { $0.name == name } }
    
    func exercise(for id: UUID) -> Exercise? { allExercises.first { $0.id == id } }
}

