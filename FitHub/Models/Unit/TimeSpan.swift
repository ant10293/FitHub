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

    init(seconds: Int) {
        self.seconds = seconds
    }
    
    func settingSeconds(_ s: Int) -> TimeSpan {
        var copy = self
        copy.setSec(seconds: s)   // uses your existing mutating setter
        return copy
    }
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
    
    static func fromSeconds(_ s: Int) -> TimeSpan {
        var t = TimeSpan.fromMinutes(max(0, s) / 60)
        t.setSec(seconds: max(0, s))
        return t
    }
    
    // MARK: – Convenience accessors
    var inSeconds: Int { seconds }
    var inMinutes: Int { seconds / 60 }
    var inHours:   Int { seconds / 3_600 }
    
    var displayString: String { return Format.formatDuration(seconds) }
    
    var displayStringCompact: String {
        let comp = components, h = comp.h, m = comp.m, s = comp.s
        return Format.formatDurationCompact(h: h, m: m, s: s)
    }
    
    var unitLabel: String { seconds < 60 ? "sec" : "min" }
    
    /// Breaks the stored seconds into `(h, m, s)` – handy for display.
    var components: (h: Int, m: Int, s: Int)  {
        let h = seconds / 3_600
        let m = (seconds % 3_600) / 60
        let s = seconds % 60
        return (h, m, s)
    }
    
    /// Replace the mass with a new *kg* value.
    mutating func setMin(minutes m: Int) {
        self.seconds = TimeSpan.fromMinutes(m).inSeconds
    }
    
    /// Replace the mass with a new *lb* value (auto‑converts to kg).
    mutating func setHrMin(hours h: Int, minutes m: Int) {
        self.seconds = TimeSpan.hrMinToSec(hours: h, minutes: m).inSeconds
    }
    
    /// Convenience: update using the caller’s preferred unit system.
    mutating func setSec(seconds s: Int) {
        self.seconds = s
    }
    
    /// Parse "mm:ss" or "ss" (and "h:mm:ss") into seconds.
    static func seconds(from text: String) -> Int {
        // Keep only digits and colons so we don't choke on accidental characters.
        let cleaned = text.unicodeScalars
            .filter { CharacterSet.decimalDigits.contains($0) || $0 == ":" }
            .map { Character($0) }
        let raw = String(cleaned).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return 0 }
        let parts = raw.split(separator: ":").map(String.init)
        let tail = Array(parts.suffix(3))
        let nums = tail.map { Int($0) ?? 0 }

        switch nums.count {
        case 1:
            // "ss"
            return max(0, nums.first ?? 0)

        case 2:
            // "mm:ss"
            let m = max(0, nums.first ?? 0)
            let s = max(0, nums.count > 1 ? nums[1] : 0)
            return m * 60 + s

        case 3:
            // "h:mm:ss"
            let h = max(0, nums.first ?? 0)
            let m = max(0, nums.count > 1 ? nums[1] : 0)
            let s = max(0, nums.count > 2 ? nums[2] : 0)
            return h * 3600 + m * 60 + s

        default:
            return 0
        }
    }
}
