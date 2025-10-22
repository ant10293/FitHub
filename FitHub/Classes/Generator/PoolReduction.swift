//
//  ReductionPool.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/20/25.
//

import SwiftUI

// TODO: should have a var for overall exercises with no data.
// should warn the user when the difficulty and repCap filters are relaxed
// if noData is the primary reduction, prompt the user to try again (warn that setDetails will not be autofilled)
struct PoolReduction: Codable, Equatable, Hashable {
    var reasons: [ReasoningCount]
    
    init() {
        self.reasons = Reason.allCases.map { ReasoningCount(reason: $0) }
    }
    
    enum Reason: Codable, Equatable, Hashable, CaseIterable {
        case cannotPerform, disliked, resistance, effort, sets, repCap, split, noData, tooDifficult
        
        var description: String {
            switch self {
            case .cannotPerform: return "Missing Required Equipment"
            case .disliked: return "Disliked"
            case .resistance: return "Incompatible Resistance Type"
            case .effort: return "Type not in Effort Distribution"
            case .sets: return "Invalid Number of Sets"
            case .repCap: return "Excessive Rep Count"
            case .split: return "Does not fit into split"
            case .noData: return "No Performance Data"
            case .tooDifficult: return "Difficulty exceeds current level"
            }
        }
        
        var icon: String {
            switch self {
            case .cannotPerform: return "wrench.and.screwdriver"
            case .disliked:      return "hand.thumbsdown"
            case .resistance:    return "bolt.slash"
            case .effort:        return "speedometer"
            case .sets:          return "square.stack.3d.down.right"
            case .repCap:        return "number"
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
            case .split:         .green
            case .tooDifficult:  .cyan  
            }
        }
    }
    
    struct ReasoningCount: Codable, Equatable, Hashable {
        let reason: Reason
        var exerciseIDs: Set<Exercise.ID> = []
        var removed: Int?
        var remaining: Int?
    }
    
    // NEW: bulk record
    mutating func record(
        reason: Reason,
        ids: Set<Exercise.ID> = [], /// filtered out ids
        removed: Int? = nil,
        remaining: Int? = nil
    ) {
        guard let idx = reasons.firstIndex(where: { $0.reason == reason }) else { return }
        if !ids.isEmpty { reasons[idx].exerciseIDs.formUnion(ids) }
        if let removed { reasons[idx].removed = removed } // overwrite only when provided
        if let remaining { reasons[idx].remaining = remaining }
    }
    
    // MARK: - Clear (requested)
     /// Clears the collected IDs for a reason. Optionally clears the `removed` count too.
     mutating func clear(_ reason: Reason) {
         guard let idx = reasons.firstIndex(where: { $0.reason == reason }) else { return }
         reasons[idx].exerciseIDs.removeAll()
         reasons[idx].removed = nil
     }

     /// Convenience: clear multiple reasons at once.
     mutating func clear(_ reasonsToClear: [Reason]) {
         for r in reasonsToClear { clear(r) }
     }

    func reasoning(for reason: Reason) -> ReasoningCount? {
        reasons.first(where: { $0.reason == reason })
    }
}

struct WorkoutReductions: Codable, Equatable, Hashable {
    private(set) var pool: [WorkoutTemplate.ID: PoolReduction] = [:]
    
    func pool(for id: WorkoutTemplate.ID) -> PoolReduction? {
        pool[id]
    }
    
    mutating func record(
        templateID: WorkoutTemplate.ID,
        newPool: PoolReduction
    ) {
        pool[templateID] = newPool
    }
}

struct DayReductions: Codable, Equatable, Hashable {
    private(set) var pool: [DaysOfWeek: PoolReduction] = [:]

    init(preseed days: [DaysOfWeek]) {
        var dict: [DaysOfWeek: PoolReduction] = [:]
        for d in days { dict[d] = PoolReduction() }
        self.pool = dict
    }

    func pool(for raw: DaysOfWeek.RawValue) -> PoolReduction? {
        guard let day = DaysOfWeek(rawValue: raw) else { return nil }
        return pool(for: day)
    }
    
    /// Read-only view without creating
    func pool(for day: DaysOfWeek) -> PoolReduction? {
        pool[day]
    }
    
    // MARK: - Record by enum
    mutating func record(
        day: DaysOfWeek,
        reason: PoolReduction.Reason,
        ids: Set<Exercise.ID> = [],
        removed: Int? = nil,
        remaining: Int? = nil
    ) {
        var reduction = pool[day] ?? PoolReduction()
        reduction.record(reason: reason, ids: ids, removed: removed, remaining: remaining)
        pool[day] = reduction
    }

    // MARK: - Overload using rawValue
    mutating func record(
        dayRaw: DaysOfWeek.RawValue,
        reason: PoolReduction.Reason,
        ids: Set<Exercise.ID> = [],
        removed: Int? = nil,
        remaining: Int? = nil
    ) {
        guard let day = DaysOfWeek(rawValue: dayRaw) else { return }
        record(day: day, reason: reason, ids: ids, removed: removed, remaining: remaining)
    }
    
    // Clear (mirror PoolReduction.clear)
    mutating func clear(day: DaysOfWeek, reason: PoolReduction.Reason) {
        var reduction = pool[day] ?? PoolReduction()
        reduction.clear(reason)
        pool[day] = reduction
    }

    /// Clear multiple reasons for a day.
    mutating func clear(day: DaysOfWeek, reasons: [PoolReduction.Reason]) {
        var reduction = pool[day] ?? PoolReduction()
        reduction.clear(reasons)
        pool[day] = reduction
    }
    
    mutating func clear(dayRaw: DaysOfWeek.RawValue, reason: PoolReduction.Reason) {
        guard let day = DaysOfWeek(rawValue: dayRaw) else { return }
        clear(day: day, reason: reason)
    }
    
    mutating func clear(dayRaw: DaysOfWeek.RawValue, reasons: [PoolReduction.Reason]) {
        guard let day = DaysOfWeek(rawValue: dayRaw) else { return }
        clear(day: day, reasons: reasons)
    }
}

