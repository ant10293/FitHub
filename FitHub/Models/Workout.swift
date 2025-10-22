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
            let sec = estimateCompletionTime(rest: rest)
            self.estimatedCompletionTime = TimeSpan(seconds: sec)
        }
    }
}

extension WorkoutTemplate {
    private func estimateCompletionTime(rest: RestPeriods) -> Int {
        let secondsPerRep = SetDetail.secPerRep
        let avgSetup = SetDetail.secPerSetup
        let extraPerDifficulty = SetDetail.extraSecPerDiff

        var total = 0

        for ex in exercises {
            let sets = ex.setDetails
            let limbMovement = ex.limbMovementType ?? .bilateralDependent

            // movement time: reps → reps*sec/rep; hold → seconds directly
            var movement = 0
            for set in sets {
                let metric = set.planned       // or: set.completed ?? set.planned
                switch metric {
                case .reps(let r): movement += (max(0, r) * secondsPerRep) * limbMovement.repsMultiplier
                case .hold(let span): movement += max(0, span.inSeconds)
                case .cardio(let ts): movement += max(0, ts.time.inSeconds)
                }
            }

            // rest time: after each set except the last; use per-set rest if present
            let workingRest = rest.rest(for: .working)
            var rest = 0
            if sets.count > 1 {
                for i in 0..<(sets.count - 1) {
                    rest += max(0, sets[i].restPeriod ?? workingRest)
                }
            }

            let difficulty = extraPerDifficulty * ex.difficulty.strengthValue
            total += movement + rest + difficulty + avgSetup
        }

        print("Estimated seconds: \(total)")
        return total
    }
    /*
    mutating func setEstimatedCompletionTime(rest: RestPeriods) {
        estimatedCompletionTime = .init(seconds: estimateCompletionTime(rest: rest))
    }
    */
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
        }

        return WorkoutSummaryData(
            totalVolume: Mass(kg: totalVolume),
            totalReps: totalReps,
            totalTime: TimeSpan(seconds: completionDuration),
            exercisePRs: updates.prExerciseIDs,
            weightByExercise: weightByExercise
        )
    }
    
    var shouldDisableTemplate: Bool {
        exercises.isEmpty || exercises.contains { $0.setDetails.isEmpty }
    }
    
    // List of UUID of exercises already in the template for quick lookup
    var exerciseIDs: Set<Exercise.ID> { Set(exercises.map { $0.id }) }
    
    var numExercises: Int { exercises.count }
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
    let disableRPE: Bool
}

struct WorkoutSummaryData {
    let totalVolume: Mass
    let totalReps: Int
    let totalTime: TimeSpan
    let exercisePRs: [UUID]
    let weightByExercise: [UUID: Double]
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
