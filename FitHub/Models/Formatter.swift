//
//  Formatter.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


enum InputLimiter {
    static func trimmed(_ text: String) -> String {
        return text.trimmingTrailingSpaces()
    }
    /// removes all leading “0” chars (except when the entire string *is* “0”)
    private static func trimLeadingZeros(_ text: String) -> String {
        var s = text
        while s.hasPrefix("0") && s.count > 1 { s.removeFirst() }
        return s
    }
    /// digits-only, max: (4 chars before decimal, 2 chars after decimal) **no leading zeros**
    static func filteredWeight(old: String, new raw: String) -> String {
        // 1) keep digits + at most one dot (regex will reject extra dots anyway)
        let cleaned = raw.filter { "0123456789.".contains($0) }

        // 2) Valid shape?  0–4 integer digits + optional ".XX"
        let pattern = #"^(\d{0,4})(\.\d{0,2})?$"#
        guard cleaned.range(of: pattern, options: .regularExpression) != nil else {
            return old // reject this keystroke
        }

        // 3) split into integer / fraction
        let parts = cleaned.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let rawInt = parts.isEmpty ? "" : String(parts.first ?? "")

        // 3a) normalize integer: collapse leading zeros, but keep a single "0"
        let intPart = trimLeadingZeros(rawInt)

        // 4) rebuild with optional fractional section (already <= 2 digits via regex)
        if parts.count == 2 {
            // If user typed ".xx" first, you can choose to show ".xx" or "0.xx".
            // To keep behavior close to your original, preserve empty before dot:
            let frac = String(parts[1])
            // If you'd rather always show a leading zero, use:
            // let lhs = intPart.isEmpty ? "0" : intPart
            let lhs = intPart
            return lhs + "." + frac
        } else {
            return intPart
        }
    }
      /// digits-only, max 3 chars, **no leading zeros**
    static func filteredReps(_ raw: String) -> String {
        let digits = raw.filter { "0123456789".contains($0) }
        let trimmed = trimLeadingZeros(digits)
        return String(trimmed.prefix(3))
    }
    
    static func isValidInput(_ input: String) -> Bool {
        // first trim trailing whitespaces
        // Check if the name is empty or contains only whitespace
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        // Define a character set of valid characters (letters, numbers, spaces)
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- ")
        
        // Check if the name contains only allowed characters
        return input.rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }
}

enum Format {
    // MARK: - Number Formatting
    
    /// Formats a `Double` by rounding to two decimal places and dropping trailing zeros.
    /// - Parameter value: The value to format.
    /// - Returns: A string with no decimal if integer, or up to two decimal places.
    static func smartFormat(_ value: Double) -> String {
        // Handle non-finite values explicitly
        guard value.isFinite else { return "\(value)" }

        // Round to 2 decimals in a stable way
        let rounded = (value * 100).rounded() / 100

        // Avoid "-0"
        if abs(rounded) < 0.0005 { return "0" }

        // Start with 2-dp string using "." as decimal separator
        var s = String(format: "%.2f", rounded)

        // Trim ONLY trailing zeros, then an optional trailing "."
        while s.last == "0" { s.removeLast() }
        if s.last == "." { s.removeLast() }

        return s
    }
    
    // MARK: - Date & Time Formatting
    static func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    static func shortDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    static func fullDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
     
    static func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    static func monthName(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: date)
    }
    
    /// Formats a `Date` into a localized string (e.g., “Jun 3, 2025 at 2:30 PM”).
    /// - Parameters:
    ///   - date: The date to format.
    ///   - dateStyle: The desired date style (default: `.medium`).
    ///   - timeStyle: The desired time style (default: `.short`).
    ///   - timeZone: The time zone to use (default: `.current`).
    /// - Returns: A formatted date/time string.
    static func formatDate(
        _ date: Date,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .short,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
    
    /// Converts a total number of seconds into an “HH:mm:ss” or “mm:ss” string.
    /// - Parameter totalSeconds: Total seconds to format.
    /// - Returns: A string like “1:05:30” or “05:30” if under an hour.
    static func timeString(from totalSeconds: Int) -> String {
        let (h, m, s) = secondsToHMS(totalSeconds)
        return formatDurationCompact(h: h, m: m, s: s)
    }
    
    static func secondsToHMS(_ seconds: Int) -> (h: Int, m: Int, s: Int) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secondsPart = seconds % 60
        return (h: hours, m: minutes, s: secondsPart)
    }
    
    static func formatTimeComponents(_ components: DateComponents) -> String {
        guard let date = CalendarUtility.shared.date(from: components) else { return "--:--" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Force 12-hour format

        return formatter.string(from: date)
    }
    
    static func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        return formatDuration(totalSeconds, roundSeconds: true)
    }
    
    static func formatDuration(_ seconds: Int, roundSeconds: Bool = false) -> String {
        // 1️⃣  Decide the base value to format
        let totalSeconds: Int = { guard roundSeconds else { return seconds }
            // ⚠️ Only round if we have at least 1 full minute
            guard seconds >= 60 else { return seconds }

            // - nearest minute  (use `ceil` for “round up”)
            return Int((Double(seconds) / 60.0).rounded()) * 60
        }()

        // 2️⃣  Break into h-m-s
        let (h, m, s) = secondsToHMS(totalSeconds)

        // 3️⃣  Build display parts
        var parts: [String] = []
        if h > 0 { parts.append("\(h) hr") }
        if m > 0 { parts.append("\(m) min") }
        if s > 0 { parts.append("\(s) sec") }

        return parts.isEmpty ? "0 sec" : parts.joined(separator: " ")
    }
    
    static func formatDurationCompact(h: Int, m: Int, s: Int, roundSeconds: Bool = false) -> String {
        let hh = max(0, h), mm = max(0, m), ss = max(0, s)
        var totalSeconds = hh * 3_600 + mm * 60 + ss

        // nearest minute
        if roundSeconds { totalSeconds = ((totalSeconds + 30) / 60) * 60 }

        let (h, m, s) = secondsToHMS(totalSeconds)

        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
    
    static func formatRange(range: ClosedRange<Int>) -> String {
        if range.lowerBound == range.upperBound {
            "\(range.lowerBound)"
        } else {
            "\(range.lowerBound)-\(range.upperBound)"
        }
    }
    
    /// Returns "N exercise(s)" with optional capitalization of the leading "e".
    static func countText(_ count: Int, base: String = "exercise", capitalize: Bool = false) -> String {
        let base = "\(count) \(base)" + (count == 1 ? "" : "s")
        return capitalize ? base.capitalizeFirstLetter() : base
    }
}

enum TextFormatter {
    /// Characters to strip for search keys (spaces, newlines, punctuation)
    static let searchStripSet: CharacterSet = {
        CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
    }()
}

