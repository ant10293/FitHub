//
//  Workout.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


struct SelectedTemplate: Identifiable, Equatable {
    var id: UUID = UUID() // not template id. changes on every selection to ensure onChange(of) is recognized
    var template: WorkoutTemplate
    var location: TemplateLocation
    var mode: NavigationMode
}

enum TemplateLocation: String, CaseIterable {
    case user, trainer, archived
    
    var label: String {
        switch self {
        case .user: return "Your Templates"
        case .trainer: return "Trainer Templates"
        case .archived: return "Archived Templates"
        }
    }
}

struct WorkoutTemplate: Identifiable, Hashable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var exercises: [Exercise] // Define Exercise as per your app's needs
    var categories: [SplitCategory]
    var dayIndex: Int?
    var date: Date?
    var notificationIDs: [String] = [] // Store notification identifiers for removal
    var estimatedCompletionTime: TimeSpan?
}

extension WorkoutTemplate {
    private func estimateCompletionTime(rest: RestPeriods) -> Int {
        let secondsPerRep = SetDetail.secPerRep
        let avgSetup = SetDetail.secPerSetup
        let extraPerDifficulty = SetDetail.extraSecPerDiff

        var total = 0

        for ex in exercises {
            let sets = ex.setDetails

            // movement time: reps → reps*sec/rep; hold → seconds directly
            var movement = 0
            for set in sets {
                let metric = set.planned       // or: set.completed ?? set.planned
                switch metric {
                case .reps(let r): movement += max(0, r) * secondsPerRep
                case .hold(let span): movement += max(0, span.inSeconds)
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

    mutating func setEstimatedCompletionTime(rest: RestPeriods) {
        estimatedCompletionTime = .init(seconds: estimateCompletionTime(rest: rest))
    }
    
    mutating func resetState() {
        for exerciseIndex in exercises.indices { exercises[exerciseIndex].resetState() }
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
    
    var shouldDisableTemplate: Bool {
        exercises.isEmpty || exercises.contains { $0.setDetails.isEmpty }
    }
    
    // List of names of exercises already in the template for quick lookup
    var exerciseNames: Set<String> { Set(exercises.map { $0.name }) }
    
    var numExercises: Int { exercises.count }
}

struct CompletedWorkout: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var template: WorkoutTemplate
    var updatedMax: [PerformanceUpdate]
    var duration: Int
    var date: Date
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
    let restTimerEnabled: Bool
    let restPeriods: RestPeriods
}

struct WorkoutSummaryData {
    let totalVolume: Mass
    let totalReps: Int
    let totalTime: TimeSpan
    let exercisePRs: [UUID]
    let weightByExercise: [UUID: Double]
}
