//
//  ExerciseData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

final class ExerciseData: ObservableObject {
    private static let bundledExercisesFileName: String = "exercises.json"
    private static let userExercisesFileName: String = "user_exercises.json"
    private static let performanceFileName: String = "performance.json"
    
    private let bundledExercises: [Exercise]          // read-only
    @Published private(set) var userExercises: [Exercise]  // can mutate & save
   
    // MARK: - Public unified view
    var allExercises: [Exercise] { bundledExercises + userExercises }
       
    @Published var allExercisePerformance: [UUID: ExercisePerformance] = [:]
    
    var exercisesWithData: [Exercise] {
        allExercises.compactMap { ex in
            hasPerformanceData(exercise: ex)
        }
    }
    
    init() {
        bundledExercises = ExerciseData.loadBundledExercises()
        userExercises = ExerciseData.loadUserExercises(from: ExerciseData.userExercisesFileName)
        loadPerformanceData(from: ExerciseData.performanceFileName)
    }
    
    // MARK: – Persistence Logic
    private static func loadBundledExercises() -> [Exercise] {
        do {
            let seed: [InitExercise] = try Bundle.main.decode(ExerciseData.bundledExercisesFileName)
            let mapping = seed.map { Exercise(from: $0) }
            print("✅ Successfully loaded \(mapping.count) exercises from \(ExerciseData.bundledExercisesFileName)")
            return mapping
        } catch {
            print("❌ Standard decoding from exercises.json failed. Falling back to manual parsing...")
            return JSONFileManager.loadBundledData(
                filename: "exercises",
                itemType: "exercise",
                decoder: { jsonDict in
                    let exerciseData = try JSONSerialization.data(withJSONObject: jsonDict)
                    let initExercise = try JSONDecoder().decode(InitExercise.self, from: exerciseData)
                    return Exercise(from: initExercise)
                },
                validator: { exercise in
                    !exercise.name.isEmpty && !exercise.image.isEmpty
                }
            )
        }
    }
    
    private static func loadUserExercises(from file: String) -> [Exercise] {
        return JSONFileManager.shared.loadUserExercises(from: file) ?? []
    }
    
    private func loadPerformanceData(from fileName: String) {
        allExercisePerformance = JSONFileManager.shared.loadPerformanceData(from: fileName) ?? [:]
    }
    
    // MARK: saving logic
    func savePerformanceData() {
        JSONFileManager.shared.save(Array(allExercisePerformance.values), to: ExerciseData.performanceFileName, dateEncoding: true)
    }
    
    private func persistUserExercises() {
        let snapshot = userExercises                 // value copy, thread-safe
        JSONFileManager.shared.save(snapshot, to: ExerciseData.userExercisesFileName)
    }
}

extension ExerciseData {
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
    
    func isUserExercise(_ exercise: Exercise) -> Bool {
        return userExercises.contains(where: { $0.id == exercise.id })
    }
}

extension ExerciseData {
    func seedEstimatedMaxes(userData: UserData) {
        for ex in allExercises {
            if peakMetric(for: ex.id).valid != nil { continue }
            if estimatedPeakMetric(for: ex.id).valid == nil {
                seedEstimatedMaxValue(exercise: ex, userData: userData)
            }
        }
        savePerformanceData()
    }

    func seedEstimatedMaxes(skipped: Set<Exercise.ID>, userData: UserData) {
        guard !skipped.isEmpty else { return }
        // Only exercises we actually know about & have CSV URLs for
        let lookup = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })

        for id in skipped {
            guard let ex = lookup[id], ex.url != nil else { continue }
            // Don’t overwrite if user already has any max saved (peak or estimate)
            if estimatedPeakMetric(for: id).valid == nil {
                seedEstimatedMaxValue(exercise: ex, userData: userData)
            }
        }
        savePerformanceData()
    }

    private func seedEstimatedMaxValue(exercise: Exercise, userData: UserData) {
        let peak = CSVLoader.calculateMaxValue(for: exercise, userData: userData).valid
        guard let max = peak else { return }
        updateExercisePerformance(for: exercise.id, newValue: max, csvEstimate: true)
    }
    
    
    func testCSVs(userData: UserData) {
        var skipped: [Exercise] = []
        for exercise in allExercises {
            let peak = CSVLoader.calculateMaxValue(for: exercise, userData: userData).valid
            guard let max = peak else {
                skipped.append(exercise)
                continue
            }
            print("\(exercise.name) max: \(max.displayValue)")
        }
        
        if !skipped.isEmpty {
            var oneRms: Set<Exercise> = []
            var maxReps: Set<Exercise> = []
            var maxHolds: Set<Exercise> = []
            var hold30sLoads: Set<Exercise> = []
            
            print("------------------ total: \(skipped.count)/\(allExercises.count) ------------------")
            for exercise in skipped {
                switch exercise.getPeakMetric(metricValue: 0) {
                case .oneRepMax: oneRms.insert(exercise)
                case .maxReps: maxReps.insert(exercise)
                case .maxHold: maxHolds.insert(exercise)
                case .hold30sLoad: hold30sLoads.insert(exercise)
                case .none: break
                }
            }
            
            if !oneRms.isEmpty {
                print("------------------ One Rep Maxes ------------------")
                for ex in oneRms {
                    print("\(ex.name) has no CSV data")
                }
            }
            
            if !maxReps.isEmpty {
                print("------------------ Max Reps ------------------")
                for ex in maxReps {
                    print("\(ex.name) has no CSV data")
                }
            }
            
            if !maxHolds.isEmpty {
                print("------------------ Max Holds ------------------")
                for ex in maxHolds {
                    print("\(ex.name) has no CSV data")
                }
            }
            
            if !hold30sLoads.isEmpty {
                print("------------------ Max Load 30s ------------------")
                for ex in hold30sLoads {
                    print("\(ex.name) has no CSV data")
                }
            }
        }
    }
}

extension ExerciseData {
    private func hasPerformanceData(exercise: Exercise) -> Exercise? {
        let best = peakMetric(for: exercise.id).valid ?? estimatedPeakMetric(for: exercise.id).valid
           
        guard let max = best else { return nil }
        var ex = exercise
        ex.draftMax = max
        return ex
    }
    
    func updateExercisePerformance(
         for exerciseId: UUID,
         newValue: PeakMetric,
         loadXmetric: LoadXMetric? = nil,
         csvEstimate: Bool = false
     ) {
         if let exercise = exercise(for: exerciseId) {
             updateExercisePerformance(
                for: exercise,
                newValue: newValue,
                loadXmetric: loadXmetric,
                csvEstimate: csvEstimate
             )
         }
    }
    
    func updateExercisePerformance(
        for exercise: Exercise,
        newValue: PeakMetric,
        loadXmetric: LoadXMetric? = nil,
        csvEstimate: Bool = false
    ) {
        let roundedDate = CalendarUtility.shared.startOfDay(for: Date())

        // Pull or create a performance record (struct – value copy)
        var perf = allExercisePerformance[exercise.id] ?? ExercisePerformance(exerciseId: exercise.id)

        // ────────────────────────────────────────────────────────────────
        // 1) Helpers
        // ────────────────────────────────────────────────────────────────

        func makeRecord() -> MaxRecord {
            MaxRecord(
                value: newValue,
                loadXmetric: loadXmetric,
                date: roundedDate
            )
        }

        func archive(_ record: MaxRecord) {
            perf.pastMaxes = (perf.pastMaxes ?? []) + [record]
        }

        // ────────────────────────────────────────────────────────────────
        // 2) CSV estimate?  → seed only `estimatedValue` and bail out
        // ────────────────────────────────────────────────────────────────
        if csvEstimate {
            perf.estimatedValue = newValue
            allExercisePerformance[exercise.id] = perf
            print("Seeded CSV estimate for \(exercise.name): \(newValue).")
            return
        }

        // ────────────────────────────────────────────────────────────────
        // 3) User‑entered true performance
        // ────────────────────────────────────────────────────────────────
        if var current = perf.currentMax {
            let sameDay = CalendarUtility.shared.isDate(current.date, inSameDayAs: roundedDate)

            if sameDay {
                // Same calendar day → treat as correction / improvement
                if newValue.actualValue >= current.value.actualValue {
                    current.value        = newValue
                    current.loadXmetric  = loadXmetric
                    current.date         = roundedDate      // stays "today"
                    perf.currentMax      = current
                    print("Updated today's max for \(exercise.name) → \(current.value.actualValue).")
                } // else ignore accidental lower entry on same day
            }
            else {
                // Different day
                if newValue.actualValue > current.value.actualValue {
                    // New all‑time PR
                    archive(current)                     // move old PR to history
                    perf.currentMax = makeRecord()       // promote new PR
                    print("🎉 New all‑time max for \(exercise.name): \(newValue).")
                } else {
                    // Sub‑max attempt → just archive
                    archive(makeRecord())
                    print("Logged sub‑max attempt \(newValue) for \(exercise.name).")
                }
            }

        } else {
            // First ever PR for this exercise
            perf.currentMax = makeRecord()
            print("Initial max for \(exercise.name): \(newValue).")
        }

        // Any real PR removes a stale CSV estimate
        perf.estimatedValue = nil

        // Persist in the dictionary
        allExercisePerformance[exercise.id] = perf
        print("Performance data for \(exercise.name) saved.")
    }
    
    func applyPerformanceUpdates(updates: [PerformanceUpdate]?, csvEstimate: Bool) {
        if let updates = updates, !updates.isEmpty {
            for update in updates {
                applyPerformanceUpdate(update: update, csvEstimate: csvEstimate, shouldSave: false)
            }
            savePerformanceData()
        }
    }
    
    func applyPerformanceUpdate(update: PerformanceUpdate, csvEstimate: Bool, shouldSave: Bool) {
        updateExercisePerformance(
            for: update.exerciseId,
            newValue: update.value,
            loadXmetric: update.loadXmetric,
            csvEstimate: csvEstimate
        )
        if shouldSave { savePerformanceData() }
    }
    
    // Delete a record by id. If it's the current max, promote the best remaining past record.
    // If nothing remains, remove the performance entry entirely.
    func deleteEntry(id: MaxRecord.ID, exercise: Exercise) {
        guard var perf = allExercisePerformance[exercise.id] else { return }

        var past = perf.pastMaxes ?? []

        if let current = perf.currentMax, current.id == id {
            // Delete the current max
            // (Just in case it also exists in past, remove it there too)
            past.removeAll { $0.id == id }

            // Promote the best remaining past record (highest actualValue)
            if let next = past.max(by: { $0.value.actualValue < $1.value.actualValue }) {
                perf.currentMax = next
                past.removeAll { $0.id == next.id }
            } else {
                perf.currentMax = nil
            }

            perf.pastMaxes = past.isEmpty ? nil : past
        } else {
            // Delete from history
            let before = past.count
            past.removeAll { $0.id == id }
            if past.count != before {
                perf.pastMaxes = past.isEmpty ? nil : past
            } else {
                // ID not found; nothing to do
                return
            }
        }

        // If everything is gone (and no estimate), drop the entry from the map
        if perf.currentMax == nil, (perf.pastMaxes?.isEmpty ?? true), perf.estimatedValue == nil {
            allExercisePerformance.removeValue(forKey: exercise.id)
        } else {
            allExercisePerformance[exercise.id] = perf
        }
        
        savePerformanceData()
    }

    // Promote a historical record to be the current max by id.
    // Demotes the existing current into history. No value checks — this is a user override.
    func setAsCurrentMax(id: MaxRecord.ID, exercise: Exercise) {
        guard var perf = allExercisePerformance[exercise.id] else { return }

        // If it's already current, nothing to do
        if let current = perf.currentMax, current.id == id { return }

        var past = perf.pastMaxes ?? []

        // Find the target in history
        guard let idx = past.firstIndex(where: { $0.id == id }) else { return }
        let chosen = past.remove(at: idx)

        // Demote existing current (if any) into history
        if let current = perf.currentMax {
            past.append(current)
        }

        perf.currentMax = chosen
        perf.pastMaxes = past.isEmpty ? nil : past

        // Optional: clearing an old CSV estimate if you treat a manual promote as authoritative
        perf.estimatedValue = nil

        allExercisePerformance[exercise.id] = perf
        savePerformanceData()
    }
    
    func estimatedPeakMetric(for exerciseId: UUID) -> PeakMetric? { allExercisePerformance[exerciseId]?.estimatedValue }
    
    func getMax(for exerciseId: UUID) -> MaxRecord? { allExercisePerformance[exerciseId]?.currentMax }
    
    func peakMetric(for exerciseId: UUID) -> PeakMetric? { getMax(for: exerciseId)?.value }
            
    func getPastMaxes(for exerciseId: UUID) -> [MaxRecord] { allExercisePerformance[exerciseId]?.pastMaxes ?? [] }
    
    func getDateForMax(for exerciseId: UUID) -> Date? { getMax(for: exerciseId)?.date }
    
    func exercise(named name: String) -> Exercise? { allExercises.first { $0.name == name } }
    
    func exercise(for id: UUID) -> Exercise? { allExercises.first { $0.id == id } }
}

extension ExerciseData {
    // MARK: - Shared search helpers (single source of truth)
    private func normalizedSearch(_ raw: String) -> String {
        let removing = TextFormatter.searchStripSet
        return raw.normalized(removing: removing)
    }
    
    private func matchesQuery(_ ex: Exercise, normalizedQuery: String) -> Bool {
        guard !normalizedQuery.isEmpty else { return true }
        let removing = TextFormatter.searchStripSet
        let nameNorm = ex.name.normalized(removing: removing)
        let aliasHit = ex.aliases?.contains {
            $0.normalized(removing: removing).contains(normalizedQuery)
        } ?? false
        return nameNorm.contains(normalizedQuery) || aliasHit
    }
    
    private func sortByPrefix(_ items: inout [Exercise], normalizedQuery: String) {
        guard !normalizedQuery.isEmpty else {
            items.sort { $0.name < $1.name }
            return
        }
        let removing = TextFormatter.searchStripSet
        items.sort { a, b in
            let na = a.name.normalized(removing: removing)
            let nb = b.name.normalized(removing: removing)
            let aStarts = na.hasPrefix(normalizedQuery)
            let bStarts = nb.hasPrefix(normalizedQuery)
            if aStarts != bStarts { return aStarts } // true first
            return na < nb
        }
    }
    
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
        let q = normalizedSearch(searchText)  // <— shared
        let favoriteSet = userData.evaluation.favoriteExercises
        let dislikedSet = userData.evaluation.dislikedExercises
        
        let hideUnequipped = userData.settings.hideUnequippedExercises
        let hideDisliked   = userData.settings.hideDislikedExercises
        let hideDifficult  = userData.settings.hideDifficultExercises
        let maxStrength    = userData.evaluation.strengthLevel.strengthValue
        
        // ── Category matcher (pulled out of the hot loop) ─────────────────────
        func matchesCategory(_ ex: Exercise) -> Bool {
            switch selectedCategory {
                
                // -------- Split selections ---------------------------------------
            case .split(let splitCat):
                let cat = ex.splitCategory ?? ex.groupCategory ?? .all
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
                return ex.resistanceOK(type)
                
            case .effortType(let type):
                return ex.effort == type
                
            case .limbMovement(let type):
                return ex.limbMovementType == type
            }
        }
        
        // ── 1. Filter pass ───────────────────────────────────────────────────
        var results: [Exercise] = []
        results.reserveCapacity(allExercises.count)
        
        for ex in allExercises {
            // a) Fav / disliked quick gates
            let isFavorite = favoriteSet.contains(ex.id)
            let isDisliked = dislikedSet.contains(ex.id)
            if favoritesOnly && !isFavorite { continue }
            
            // Keep only disliked when dislikedOnly == true.
            // Otherwise (normal mode), optionally hide disliked if hideDisliked == true.
            if dislikedOnly {
                if !isDisliked { continue }
            } else if hideDisliked && isDisliked {
                continue
            }
            
            // b) Equipment / difficulty gates
            if hideUnequipped &&
                !ex.canPerform(
                    equipmentData: equipmentData,
                    equipmentSelected: userData.evaluation.equipmentSelected
                ) { continue }
            if hideDifficult && !ex.difficultyOK(maxStrength) { continue }
            
            // c) Category gate
            guard matchesCategory(ex) else { continue }
            
            // d) Search-text gate
            guard matchesQuery(ex, normalizedQuery: q) else { continue }
            
            // Passed all gates → keep it
            results.append(ex)
        }
        
        // ── 2. Sort (items that *start* with query bubble to top) ─────────────
        sortByPrefix(&results, normalizedQuery: q)
        
        return results
    }
    
    func similarExercises(
        to exercise: Exercise,
        equipmentData: EquipmentData,
        availableEquipmentIDs: [UUID],
        existing: [Exercise],
        replaced: Set<String> = [],
        searchText: String = ""
    ) -> [Exercise] {
        
        let q = normalizedSearch(searchText)  // <— shared
        let existingNames = Set(existing.map(\.name))
        
        // Common pool: not the current exercise, not already present
        let basePool = allExercises.filter {
            $0.id != exercise.id && !existingNames.contains($0.name)
        }
        
        // --- Search mode: global, not constrained by similarity buckets ---
        if !q.isEmpty {
            var results = basePool.filter {
                $0.canPerform(equipmentData: equipmentData, equipmentSelected: availableEquipmentIDs)
            }.filter { ex in
                matchesQuery(ex, normalizedQuery: q) // <— shared
            }
            
            sortByPrefix(&results, normalizedQuery: q) // <— shared
            return results
        }
        
        // --- No search: your original similarity tiers ---
        let targetPrimSet    = Set(exercise.primaryMuscles)
        let targetEffort     = exercise.effort
        let targetUsesWeight = exercise.usesWeight
        
        var strict:    [Exercise] = []; strict.reserveCapacity(8)
        var relaxed:   [Exercise] = []; relaxed.reserveCapacity(8)
        var strictFB:  [Exercise] = []; strictFB.reserveCapacity(8)
        var relaxedFB: [Exercise] = []; relaxedFB.reserveCapacity(8)
        
        for cand in basePool {
            if hasPerformanceData(exercise: cand) == nil { continue }
            
            let candSet = Set(cand.primaryMuscles)
            let isStrictMuscle  = (candSet == targetPrimSet) && (cand.effort == targetEffort)
            let isRelaxedMuscle = !isStrictMuscle && !candSet.isDisjoint(with: targetPrimSet)
            if !(isStrictMuscle || isRelaxedMuscle) { continue }
            
            let goesToRelaxed = isRelaxedMuscle || (cand.usesWeight != targetUsesWeight)
            
            guard cand.canPerform(
                equipmentData: equipmentData,
                equipmentSelected: availableEquipmentIDs
            ) else { continue }
            
            let wasReplaced = replaced.contains(cand.name)
            
            switch (goesToRelaxed, wasReplaced) {
            case (true,  true):  relaxedFB.append(cand)
            case (true,  false): relaxed.append(cand)
            case (false, true):  strictFB.append(cand)
            case (false, false): strict.append(cand)
            }
        }
        
        if !strict.isEmpty   { return strict }
        if !relaxed.isEmpty  { return relaxed }
        if !strictFB.isEmpty { return strictFB }
        return relaxedFB
    }
}
