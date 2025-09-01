//
//  Notification.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/19/25.
//

import Foundation

struct Notification: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var body: String
    var triggerDate: Date
    var workoutName: String
}

struct Notifications: Codable, Hashable {
    var intervals: [TimeInterval] = []
    var times: [DateComponents] = []
    
    func contains(_ comps: DateComponents) -> Bool { times.contains(comps) }
    func contains(_ int: TimeInterval) -> Bool { intervals.contains(int) }
    
    @discardableResult
    mutating func addInterval(totalSeconds: Int) -> Bool {
        guard totalSeconds > 0 else { return false }
        let ti = TimeInterval(totalSeconds)
        guard !contains(ti) else { return false }
        intervals.append(ti)
        intervals.sort()
        return true
    }

    @discardableResult
    mutating func removeInterval(_ interval: TimeInterval) -> Bool {
        let before = intervals.count
        intervals.removeAll { $0 == interval }
        return intervals.count != before
    }

    @discardableResult
    mutating func addTime(components: DateComponents) -> Bool {
        guard !times.contains(components) else { return false }
        times.append(components)
        times.sort { ($0.hour ?? 0, $0.minute ?? 0) < ($1.hour ?? 0, $1.minute ?? 0) }
        return true
    }

    @discardableResult
    mutating func removeTime(_ comps: DateComponents) -> Bool {
        let before = times.count
        times.removeAll { $0 == comps }
        return times.count != before
    }
}
