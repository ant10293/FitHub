//
//  Workout.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


struct SelectedTemplate: Identifiable, Equatable {
    let id: UUID // not template id. changes on every selection to ensure onChange(of) is recognized
    var template: WorkoutTemplate
    var location: TemplateLocation
    var mode: NavigationMode
    
    init(template: WorkoutTemplate, location: TemplateLocation, mode: NavigationMode) {
        self.id = UUID()
        self.template = template
        self.location = location
        self.mode = mode
    }
}

enum TemplateLocation: String, Codable, CaseIterable {
    case user, trainer, archived, active
    
    var label: String {
        switch self {
        case .user: return "Your Templates"
        case .trainer: return "Trainer Templates"
        case .archived: return "Archived Templates"
        case .active: return "Active Template"
        }
    }
}

struct WorkoutTemplate: Identifiable, Hashable, Codable, Equatable {
    let id: UUID
    var name: String
    var exercises: [Exercise] // Define Exercise as per your app's needs
    var categories: [SplitCategory]
    var dayIndex: Int?
    var date: Date?
    var notificationIDs: [String] = [] // Store notification identifiers for removal
    var estimatedCompletionTime: TimeSpan?
    
    init(
        id: UUID? = nil,
        name: String,
        exercises: [Exercise],
        categories: [SplitCategory] = [],
        dayIndex: Int? = nil,
        date: Date? = nil,
        notificationIDs: [String] = [],
        estimatedCompletionTime: TimeSpan? = nil,
        restPeriods: RestPeriods? = nil
    ) {
        self.id = id ?? UUID()
        self.name = name
        self.exercises = exercises
        self.categories = categories
        self.dayIndex = dayIndex
        self.date = date
        self.notificationIDs = notificationIDs
        self.estimatedCompletionTime = estimatedCompletionTime
        if let rest = restPeriods {
            let (ts, _) = estimateCompletionTime(rest: rest)
            self.estimatedCompletionTime = ts
        }
    }
}

extension WorkoutTemplate {
    func estimateCompletionTime(
        rest: RestPeriods
    ) -> (total: TimeSpan, perExercise: [(id: Exercise.ID, seconds: Int)]) {
        let avgSetup = SetDetail.secPerSetup

        var perExercise: [(id: Exercise.ID, seconds: Int)] = []
        var totalSeconds = 0

        for (exIdx, ex) in exercises.enumerated() {
            let warmupSets   = ex.warmUpDetails
            let workingSets  = ex.setDetails
            let limbMovement = ex.limbMovementType ?? .bilateralDependent
            let isLastExercise = (exIdx == exercises.indices.last)
            
            var movement = 0
            var restTime = 0

            func parseSets(_ sets: [SetDetail], isWarm: Bool) {
                guard !sets.isEmpty else { return }
                let restSec = ex.getRestPeriod(isWarm: isWarm, rest: rest)
                
                for set in sets {
                    switch set.planned {
                    case .reps(let r):
                        let secPerRep = SetDetail.secPerRep(for: r, isWarm: isWarm)
                        movement += (max(0, r) * secPerRep) * limbMovement.repsMultiplier
                    case .hold(let span):
                        movement += max(0, span.inSeconds)
                    case .cardio(let ts):
                        movement += max(0, ts.time.inSeconds)
                    case .carry(let m):
                        // Estimate time for carry: 1.5 seconds per meter
                        let secondsPerMeter = SetDetail.secPerMeter
                        movement += Int((m.inM * secondsPerMeter).rounded())
                    }
                    
                    let noRest = isLastExercise && set.setNumber == ex.totalSets
                    if !noRest {
                        restTime += restSec
                    }
                }
            }

            parseSets(warmupSets, isWarm: true)
            parseSets(workingSets, isWarm: false)

            let exerciseSeconds = movement + restTime + avgSetup
            perExercise.append((id: ex.id, seconds: exerciseSeconds))
            totalSeconds += exerciseSeconds
        }

        return (total: TimeSpan(seconds: totalSeconds), perExercise: perExercise)
    }
    
    mutating func setEstimatedCompletionTime(rest: RestPeriods) {
        let (total, _) = estimateCompletionTime(rest: rest)
        self.estimatedCompletionTime = total
    }
    
    private func deriveCategories() -> [SplitCategory] {
        let CAP = 4
        var ordered: [SplitCategory] = []
        var seen: Set<SplitCategory> = []
        var parentToChildren: [SplitCategory: Set<SplitCategory>] = [:]

        @inline(__always)
        func tryAppendGroup(_ gc: SplitCategory) {
            guard ordered.count < CAP, !seen.contains(gc) else { return }
            if let kids = parentToChildren[gc], !kids.isDisjoint(with: seen) {
                seen.subtract(kids)
                ordered.removeAll { kids.contains($0) }
            }
            seen.insert(gc)
            ordered.append(gc)
        }

        @inline(__always)
        func tryAppendSplit(_ sc: SplitCategory) {
            guard ordered.count < CAP, !seen.contains(sc) else { return }
            // Block if any present parent group owns this split
            let blocked = parentToChildren.contains { parent, kids in
                seen.contains(parent) && kids.contains(sc)
            }
            if !blocked {
                seen.insert(sc)
                ordered.append(sc)
            }
        }

        for ex in exercises {
            if let gc = ex.groupCategory, let sc = ex.splitCategory {
                parentToChildren[gc, default: []].insert(sc)
            }
            if let gc = ex.groupCategory { tryAppendGroup(gc) }
            if let sc = ex.splitCategory { tryAppendSplit(sc) }
            if ordered.count >= CAP { break }
        }

        return ordered
    }
    
    mutating func setCategories() {
        self.categories = deriveCategories()
    }
    
    static func uniqueTemplateName(initialName: String, from templates: [WorkoutTemplate]) -> String {
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
    
    func calculateWorkoutSummary(
        completionDuration: Int = 0,
        updates: PerformanceUpdates = .init()
    ) -> WorkoutSummaryData {
        var totalVolume: Double = 0
        var totalReps:   Int    = 0
        var weightByExercise: [UUID: Double] = [:]
        var timeByExercise: [UUID: Int] = [:]

        for exercise in exercises {
            let repsMul = exercise.limbMovementType?.repsMultiplier ?? 1
            let wtMul   = exercise.limbMovementType?.weightMultiplier ?? 1

            for set in exercise.setDetails {
                let weightKg = set.load.weight?.inKg ?? 0
                let metric   = set.completed ?? set.planned

                let (vol, reps) = metric.volumeContribution(
                    weightKg: weightKg,
                    repsMul: repsMul,
                    weightMul: wtMul
                )

                if vol != 0 {
                    totalVolume += vol
                    weightByExercise[exercise.id, default: 0] += vol
                }
                totalReps += reps
            }
            
            // Track time spent per exercise
            if exercise.timeSpent > 0 {
                timeByExercise[exercise.id] = exercise.timeSpent
            }
        }

        return WorkoutSummaryData(
            totalVolume: Mass(kg: totalVolume),
            totalReps: totalReps,
            totalTime: TimeSpan(seconds: completionDuration),
            exercisePRs: updates.prExerciseIDs,
            weightByExercise: weightByExercise,
            timeByExercise: timeByExercise
        )
    }
    
    var noSetsCompleted: Bool { exercises.allSatisfy(\.noSetsCompleted) }
    
    var shouldDisableTemplate: Bool {
        exercises.isEmpty || exercises.contains { $0.setDetails.isEmpty }
    }
    
    // List of UUID of exercises already in the template for quick lookup
    var exerciseIDs: Set<Exercise.ID> { Set(exercises.map { $0.id }) }
    
    var numExercises: Int { exercises.count }
    
    func supersetFor(exercise: Exercise) -> Exercise? {
        guard let supersettedWith = exercise.isSupersettedWith else { return nil }
        return exercises.first(where: { $0.id.uuidString == supersettedWith })
    }
}

struct CompletedWorkout: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var template: WorkoutTemplate
    var updatedMax: [PerformanceUpdate]
    var duration: Int
    var date: Date
    
    let byID: [UUID: Exercise]
    
    init(
        template: WorkoutTemplate = .init(name: "", exercises: []),
        updatedMax: [PerformanceUpdate] = [],
        duration: Int = 0,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.name = template.name
        self.template = template
        self.updatedMax = updatedMax
        self.duration = duration
        self.date = date
        self.byID = Dictionary(uniqueKeysWithValues: template.exercises.map { ($0.id, $0) })
    }
}

struct WorkoutInProgress: Codable, Equatable {
    var template: WorkoutTemplate
    var currentExerciseState: CurrentExerciseState?
    var dateStarted: Date
    var updatedMax: [PerformanceUpdate]
}

struct TemplateProgress {
    let exerciseIdx: Int
    let numExercises: Int
    let isLastExercise: Bool
}

struct UserParams {
    let restTimerEnabled: Bool
    let restPeriods: RestPeriods
    let hideRPE: Bool
    let hideCompleted: Bool
    let hideImage: Bool
}

struct WorkoutSummaryData {
    let totalVolume: Mass
    let totalReps: Int
    let totalTime: TimeSpan
    let exercisePRs: [UUID]
    let weightByExercise: [UUID: Double]
    let timeByExercise: [UUID: Int] // Time spent per exercise in seconds
}

struct OldTemplate: Identifiable {
    let id: UUID
    let exercises: [Exercise]

    init(template: WorkoutTemplate) {
        self.id = template.id
        self.exercises = template.exercises
    }
        
    /// Generic initializer + empty singleton
    init(id: UUID = UUID(), exercises: [Exercise] = []) {
        self.id = id
        self.exercises = exercises
    }
}
