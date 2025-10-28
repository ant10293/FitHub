//
//  ChangesPool.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/20/25.
//

import SwiftUI

// TODO: should have a var for overall exercises with no data.
// should warn the user when the difficulty and repCap filters are relaxed
// if noData is the primary reduction, prompt the user to try again (warn that setDetails will not be autofilled)
struct PoolChanges: Equatable, Hashable {
    var reasons: [ReasoningCount]
    var relaxedFilters: [RelaxedFilter] = []
    
    init() {
        self.reasons = ReductionReason.allCases.map { ReasoningCount(reason: $0) }
    }
    
    enum RelaxedFilter: String, CaseIterable, Comparable {
        case resistance, effort, repCap, split, difficulty
        
        /// Lower number = relaxed earlier
        var order: Int {
            switch self {
            case .difficulty: return 0
            case .effort:     return 1
            case .resistance: return 2
            case .repCap:     return 3
            case .split:      return 4
            }
        }
        
        static func ordered(excluding delayed: Set<RelaxedFilter>) -> [RelaxedFilter] {
            let base = Self.defaultOrder
            // Partition so that delayed types are moved last
            let (priority, postponed) = base.partitioned { !delayed.contains($0) }
            
            return priority + postponed
        }
        
        var label: String {
            switch self {
            case .difficulty: return "Difficulty"
            case .resistance: return "Resistance"
            case .effort:     return "Effort"
            case .repCap:     return "Rep Cap"
            case .split:      return "Split"
            }
        }
        
        var correspondingReduction: ReductionReason {
            switch self {
            case .difficulty: return .tooDifficult
            case .effort: return .effort
            case .resistance: return .resistance
            case .repCap: return .repCap
            case .split: return .split
            }
        }

        /// Convenience: canonical ordered list
        static var defaultOrder: [RelaxedFilter] {
            Self.allCases.sorted { $0.order < $1.order }
        }
        
        static func < (lhs: RelaxedFilter, rhs: RelaxedFilter) -> Bool {
            lhs.order < rhs.order
        }
    }
    
    enum ReductionReason: Equatable, Hashable, CaseIterable {
        // Filtering / eligibility removals
        case cannotPerform, disliked, resistance, effort, sets, repCap, repMin, split, noData, tooDifficult
                
        var description: String {
            switch self {
            case .cannotPerform: return "Missing Required Equipment"
            case .disliked: return "Disliked"
            case .resistance: return "Incompatible Resistance Type"
            case .effort: return "Type not in Effort Distribution"
            case .sets: return "Invalid Number of Sets"
            case .repCap: return "Excessive Rep Count"
            case .repMin: return "Not enough Reps"
            case .split: return "Does not fit into split"
            case .noData: return "No Performance Data"
            case .tooDifficult: return "Difficulty exceeds current level"
            }
        }
        
        var hasAction: Bool {
            switch self {
            case .disliked, .resistance, .effort, .sets:
                return true
            case .cannotPerform, .tooDifficult, .noData, .repCap, .repMin, .split:
                return false
            }
        }
        
        /*
        var recommenedAction: String {
            switch self {
            case .cannotPerform: return "Check Available Equipment"
            case .disliked: return "Disable Disliked Filtering"
            case .resistance: return "Change Resistance Type"
            case .effort: return "Modify Effort Distribution"
            case .sets: return "Modify Set Distribution"
            case .repCap: return "Modify Rep Cap" // recommend before change resistance type
            case .split: return "Modify Split"
            case .noData: return "Allow Creation without Data"
            case .tooDifficult: return "Disable Difficulty Filtering"
            }
        }
        */
        
        var icon: String {
            switch self {
            case .cannotPerform: return "wrench.and.screwdriver"
            case .disliked:      return "hand.thumbsdown"
            case .resistance:    return "bolt.slash"
            case .effort:        return "speedometer"
            case .sets:          return "square.stack.3d.down.right"
            case .repCap:        return "number"
            case .repMin:        return "number.circle"
            case .split:         return "square.grid.2x2"
            case .noData:        return "exclamationmark.triangle"
            case .tooDifficult:  return "chart.line.uptrend.xyaxis"
            }
        }
        
        var tint: Color {
            switch self {
            case .noData:        .orange
            case .cannotPerform: .red
            case .disliked:      .pink
            case .resistance:    .purple
            case .effort:        .blue
            case .sets:          .teal
            case .repCap:        .indigo
            case .repMin:        .yellow
            case .split:         .green
            case .tooDifficult:  .cyan
            }
        }
    }
    
    struct ReasoningCount: Equatable, Hashable {
        let reason: ReductionReason
        var exerciseIDs: Set<Exercise.ID> = []
        var beforeCount: Int?
        var afterCount: Int?
        
        var removed: Int? {
            guard let beforeCount, let afterCount else { return nil }
            return beforeCount - afterCount
        }
    }
    
    // NEW: bulk record
    mutating func record(
        reason: ReasoningCount? = nil,
        relaxed: RelaxedFilter? = nil
    ) {
        if let relaxed { relaxedFilters.append(relaxed) }
        guard let reason, let idx = reasons.firstIndex(where: { $0.reason == reason.reason }) else { return }
        if !reason.exerciseIDs.isEmpty { reasons[idx].exerciseIDs.formUnion(reason.exerciseIDs) }
        if let before = reason.beforeCount { reasons[idx].beforeCount = before } // overwrite only when provided
        if let after = reason.afterCount { reasons[idx].afterCount = after }
    }
    
    // MARK: - Clear (requested)
     /// Clears the collected IDs for a reason. Optionally clears the `removed` count too.
     mutating func clear(_ reason: ReductionReason) {
         guard let idx = reasons.firstIndex(where: { $0.reason == reason }) else { return }
         reasons[idx].exerciseIDs.removeAll()
         reasons[idx].beforeCount = nil
         reasons[idx].afterCount = nil
     }

     /// Convenience: clear multiple reasons at once.
     mutating func clear(_ reasonsToClear: [ReductionReason]) {
         for r in reasonsToClear { clear(r) }
     }

    func reasoning(for reason: ReductionReason) -> ReasoningCount? {
        reasons.first(where: { $0.reason == reason })
    }
}

struct WorkoutChanges: Equatable, Hashable {
    private(set) var pool: [WorkoutTemplate.ID: PoolChanges] = [:]
    
    /// True if ANY template relaxed at least one filter
    var didRelaxFilters: Bool {
        pool.values.contains { !$0.relaxedFilters.isEmpty }
    }
    
    func pool(for id: WorkoutTemplate.ID) -> PoolChanges? {
        pool[id]
    }
    
    mutating func record(
        templateID: WorkoutTemplate.ID,
        newPool: PoolChanges
    ) {
        pool[templateID] = newPool
    }
}

struct DayChanges: Equatable, Hashable {
    private(set) var pool: [DaysOfWeek: PoolChanges] = [:]

    init(preseed days: [DaysOfWeek]) {
        var dict: [DaysOfWeek: PoolChanges] = [:]
        for d in days { dict[d] = PoolChanges() }
        self.pool = dict
    }

    func pool(for raw: DaysOfWeek.RawValue) -> PoolChanges? {
        guard let day = DaysOfWeek(rawValue: raw) else { return nil }
        return pool(for: day)
    }
    
    /// Read-only view without creating
    func pool(for day: DaysOfWeek) -> PoolChanges? {
        pool[day]
    }
    
    // MARK: - Record by enum
    mutating func record(
        day: DaysOfWeek,
        reason: PoolChanges.ReasoningCount? = nil,
        relaxed: PoolChanges.RelaxedFilter? = nil
    ) {
        var reduction = pool[day] ?? PoolChanges()
        reduction.record(reason: reason, relaxed: relaxed)
        pool[day] = reduction
    }

    // MARK: - Overload using rawValue
    mutating func record(
        dayRaw: DaysOfWeek.RawValue,
        reason: PoolChanges.ReasoningCount? = nil,
        relaxed: PoolChanges.RelaxedFilter? = nil
    ) {
        guard let day = DaysOfWeek(rawValue: dayRaw) else { return }
        record(day: day, reason: reason, relaxed: relaxed)
    }

    /// Clear multiple reasons for a day.
    mutating func clear(day: DaysOfWeek, reasons: [PoolChanges.ReductionReason]) {
        var reduction = pool[day] ?? PoolChanges()
        reduction.clear(reasons)
        pool[day] = reduction
    }
    
    mutating func clear(dayRaw: DaysOfWeek.RawValue, reasons: [PoolChanges.ReductionReason]) {
        guard let day = DaysOfWeek(rawValue: dayRaw) else { return }
        clear(day: day, reasons: reasons)
    }
}

