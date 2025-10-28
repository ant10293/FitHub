//
//  TimeSpan.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/22/25.
//

import Foundation

// MARK: TimeSpan
struct TimeSpan: Codable, Equatable, Hashable {
    /// Canonical backing-store in **seconds**.
    private var seconds: Int

    // MARK: init() {}
    init(seconds: Int) { self.seconds = seconds }
    init() { self.seconds = 0 }
    
    // MARK: – Convenience accessors
    var inSeconds: Int { seconds }
    var inMinutes: Int { seconds / 60 }
    var inHours:   Int { seconds / 3_600 }
    
    // MARK: – Display
    var displayString: String { return Format.formatDuration(seconds) }
    var displayStringCompact: String {
        let comp = components, h = comp.h, m = comp.m, s = comp.s
        return Format.formatDurationCompact(h: h, m: m, s: s)
    }
    var fieldString: String { seconds > 0 ? displayStringCompact : "" }
    var components: (h: Int, m: Int, s: Int) { Format.secondsToHMS(seconds) }
    
    // MARK: - Mutating setters
    mutating func setMin(minutes m: Int) {
        self.seconds = TimeSpan.fromMinutes(m).inSeconds
    }
    mutating func setHrMin(hours h: Int, minutes m: Int) {
        self.seconds = TimeSpan.hrMinToSec(hours: h, minutes: m).inSeconds
    }
    mutating func setSec(seconds s: Int) { self.seconds = s } /// Convenience: update using the caller’s preferred unit system.

    // MARK: – Unit
    var unit: UnitCategory { .time }
}

extension TimeSpan {
    // MARK: – Static factory helpers
    /// Creates a `Time` whose *seconds* equal **h×3 600 + m×60**.
    static func hrMinToSec(hours h: Int, minutes m: Int) -> TimeSpan {
        TimeSpan(seconds: (h * 3_600) + (m * 60))
    }

    /// Creates a `Time` whose *seconds* equal **(h×60 + m)×60** – i.e. the
    /// caller is giving you an *hour + minute duration expressed in minutes*.
    static func fromMinSec(minutes m: Int, seconds s: Int) -> TimeSpan {
        TimeSpan(seconds: (m * 60) + s)
    }
    
    static func fromMinutes(_ m: Int) -> TimeSpan { TimeSpan(seconds: m * 60) }
    
    static func fromSeconds(_ s: Int) -> TimeSpan { TimeSpan(seconds: s) }
    
    
    /// Parse "mm:ss" or "ss" (and "h:mm:ss") into seconds.
    static func seconds(from text: String) -> TimeSpan {
        // Keep only digits and colons so we don't choke on accidental characters.
        let cleaned = text.unicodeScalars
            .filter { CharacterSet.decimalDigits.contains($0) || $0 == ":" }
            .map { Character($0) }
        let raw = String(cleaned).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return TimeSpan(seconds: 0) }
        let parts = raw.split(separator: ":").map(String.init)
        let tail = Array(parts.suffix(3))
        let nums = tail.map { Int($0) ?? 0 }

        let seconds: Int
        switch nums.count {
        case 1:
            // "ss"
            seconds = max(0, nums.first ?? 0)

        case 2:
            // "mm:ss"
            let m = max(0, nums.first ?? 0)
            let s = max(0, nums.count > 1 ? nums[1] : 0)
            seconds = m * 60 + s

        case 3:
            // "h:mm:ss"
            let h = max(0, nums.first ?? 0)
            let m = max(0, nums.count > 1 ? nums[1] : 0)
            let s = max(0, nums.count > 2 ? nums[2] : 0)
            seconds = h * 3600 + m * 60 + s

        default:
            seconds = 0
        }
        
        return TimeSpan(seconds: seconds)
    }
}

extension TimeSpan {
    func isWithin(_ other: TimeSpan, tolerancePercent: Double = 0.10) -> Bool {
        let selfMin  = Double(inMinutes)
        let otherMin = Double(other.inMinutes)
        guard otherMin > 0 else { return true }
        let ratio = abs(selfMin - otherMin) / otherMin
        return ratio <= tolerancePercent
    }
}
