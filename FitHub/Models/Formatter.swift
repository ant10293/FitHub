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
        // 1. keep only digits + the *first* dot
        let cleaned = raw.filter { "0123456789.".contains($0) }

        // 2. still valid?  0-4 integer digits + opt “.XX”
        let pattern = #"^(\d{0,4})(\.\d{0,2})?$"#
        guard cleaned.range(of: pattern, options: .regularExpression) != nil else {
              return old            // reject this keystroke
        }

        // 3. split   123.45  -> ["123" , "45"]
        let parts = cleaned.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        var intPart = trimLeadingZeros(String(parts[0]))

        //      an isolated “0” becomes empty (user probably deleting)
        if intPart == "0" { intPart = "" }

        // 4. rebuild with optional fractional section
        if parts.count == 2 {
            return intPart + "." + parts[1]
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
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
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
        let roundedValue = round(value * 100) / 100  // Round to two decimal places
        if roundedValue.truncatingRemainder(dividingBy: 1) == 0 {
            // It's effectively an integer
            return String(format: "%.0f", roundedValue)
        } else {
            // Keep two-decimal precision, then trim trailing zeros and punctuation
            return String(format: "%.2f", roundedValue)
                .trimmingCharacters(in: CharacterSet(charactersIn: "0").union(.punctuationCharacters))
        }
    }
    
    // MARK: - Date & Time Formatting
    static func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func weekdayLong(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
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
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    static func formatTimeComponents(_ components: DateComponents) -> String {
        let calendar = Calendar.current
        
        guard let date = calendar.date(from: components) else {
            return "--:--"
        }
        
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
        let hours   = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs    = totalSeconds % 60

        // 3️⃣  Build display parts
        var parts: [String] = []
        if hours   > 0 { parts.append("\(hours) hr") }
        if minutes > 0 { parts.append("\(minutes) min") }
        if secs    > 0 { parts.append("\(secs) sec") }

        return parts.isEmpty ? "0 sec" : parts.joined(separator: " ")
    }
}

extension String {
    func trimmingTrailingSpaces() -> String {
        guard let range = range(of: "\\s+$", options: .regularExpression) else { return self }
        return replacingCharacters(in: range, with: "")
    }
}

extension String {
    func removingCharacters(in set: CharacterSet) -> String {
        self.components(separatedBy: set).joined()
    }
}

extension String {
    /// Lower-cases and removes every scalar in `removing`.
    @inline(__always)
    func normalized(removing: CharacterSet) -> String {
        unicodeScalars
            .filter { !removing.contains($0) }
            .reduce(into: "") { $0.append(Character($1)) }
            .lowercased()
    }
}
