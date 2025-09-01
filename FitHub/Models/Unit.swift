//
//  Unit.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/22/25.
//

import Foundation
import SwiftUI

enum UnitSystem: String, Codable, CaseIterable {
    case imperial = "Imperial"
    case metric = "Metric"
    
    static let storageKey = "unitSystem"

    static var current: UnitSystem {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? UnitSystem.metric.rawValue
        return UnitSystem(rawValue: raw) ?? .metric
    }
    
    var weightUnit: String { self == .imperial ? "lb" : "kg" }
    var sizeUnit:   String { self == .imperial ? "in" : "cm" }
    var distanceUnit: String { self == .imperial ? "ft" : "m" }
    
    var displayName: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric:   return "Metric (SI)"
        }
    }
        
    var desc: String { "\(displayName) • \(weightUnit) / \(sizeUnit) • \(distanceUnit)" }
    
    @inline(__always)
    static func preferredUnitSystem(locale: Locale = .current) -> UnitSystem {
        if #available(iOS 16.0, *) {                       // modern API
            return locale.measurementSystem == .metric ? .metric : .imperial
        } else {
            // iOS 15‑:  `measurementSystem` unavailable — infer from region
            let imperialRegions: Set<String> = ["US", "LR", "MM"]          // USA, Liberia, Myanmar
            let region = locale.regionCode ?? "US"
            return imperialRegions.contains(region) ? .imperial : .metric
        }
    }
    
    // MARK: - Conversion Constants
    private static let cmPerInch: Double = 2.54
    private static let kgPerLb: Double = 0.45359237
    private static let lbPerKg: Double = 1 / kgPerLb  // ≈ 2.20462262185

    // MARK: - Weight Conversions
    static func LBtoKG(_ pounds: Double) -> Double { return pounds * kgPerLb }

    static func KGtoLB(_ kilograms: Double) -> Double { return kilograms * lbPerKg }

    // MARK: - Length Conversions
    static func CMtoIN(_ centimeters: Double) -> Double { return centimeters / cmPerInch }

    static func INtoCM(_ inches: Double) -> Double { return inches * cmPerInch }
}

// MARK: Mass
struct Mass: Codable, Equatable, Hashable {
    private var kg: Double                 // canonical storage
    
    // MARK: – Inits
    init(kg: Double) { self.kg = kg }
    init(lb: Double) { self.kg = UnitSystem.LBtoKG(lb) }
    
    // MARK: – Accessors
    var inKg: Double { kg }
    var inLb: Double { UnitSystem.KGtoLB(kg) }
    
    /// Returns the weight in the caller‑specified unit system.
    var displayValue: Double {
        UnitSystem.current == .imperial ? inLb : inKg
    }
    
    var displayString: String { Format.smartFormat(displayValue) }
    
    func formattedText(asInteger: Bool = false) -> Text {
        let unitSystem = UnitSystem.current
        let display = asInteger ? String(Int(round(displayValue))) : Format.smartFormat(displayValue)
        
        return (Text("\(display) ") +
            Text(unitSystem.weightUnit).fontWeight(.light)
        )
    }
    
    var abs: Mass { Mass(kg: Swift.abs(inKg)) }
    
    /// Replace the mass with a new *kg* value.
    mutating func setKg(_ kg: Double) {
        self.kg = kg
    }
    
    /// Replace the mass with a new *lb* value (auto‑converts to kg).
    mutating func setLb(_ lb: Double) {
        self.kg = UnitSystem.LBtoKG(lb)
    }
    
    /// Convenience: update using the caller’s preferred unit system.
    mutating func set(_ value: Double) {
        self.kg = UnitSystem.current == .imperial ? UnitSystem.LBtoKG(value) : value
    }
}
extension Binding where Value == Mass {
    func asText(
        format: @escaping (Double) -> String = { Format.smartFormat($0) },
        sanitize: @escaping (_ old: String, _ new: String) -> String = { old, new in
            InputLimiter.filteredWeight(old: old, new: new)
        }
    ) -> Binding<String> {

        Binding<String>(
            get: {
                let v = wrappedValue.displayValue          // <- property you already have
                return v == 0 ? "" : format(v)
            },
            set: { newText in
                let old = format(wrappedValue.displayValue)
                let filtered = sanitize(old, newText)
                if let v = Double(filtered) {
                    var copy = wrappedValue
                    copy.set(v)                      // <- your current API (auto-uses UnitSystem.current)
                    wrappedValue = copy
                }
            }
        )
    }
}

// MARK: Length
struct Length: Codable, Equatable, Hashable {
    private var cm: Double                 // canonical storage
    
    // MARK: – Inits
    init(cm: Double) { self.cm = cm }
    init(inch: Double) { self.cm = UnitSystem.INtoCM(inch) }
    
    // MARK: – Accessors
    var inCm: Double { cm }
    var inInch: Double { UnitSystem.CMtoIN(cm) }
    
    /// Returns the weight in the caller‑specified unit system.
    var displayValue: Double {
        UnitSystem.current == .imperial ? inInch : inCm
    }
    
    /// Replace the mass with a new *kg* value.
    mutating func setCm(_ cm: Double) {
        self.cm = cm
    }
    
    /// Replace the mass with a new *lb* value (auto‑converts to kg).
    mutating func setIn(_ inch: Double) {
        self.cm = UnitSystem.INtoCM(inch)
    }
    
    /// Convenience: update using the caller’s preferred unit system.
    mutating func set(_ value: Double) {
        self.cm = UnitSystem.current == .imperial ? UnitSystem.INtoCM(value) : value
    }
    
    var totalInches: Int { return Int(round(inInch)) }
    
    var heightFormatted: Text {
        if UnitSystem.current == .imperial {
            Text("\(totalInches / 12)")
            + Text(" ft ").fontWeight(.light)
            + Text("\(totalInches % 12)")
            + Text(" in").fontWeight(.light)
        } else {
            Text("\(Int(round(inCm)))")
            + Text(" cm").fontWeight(.light)
        }
    }
}
extension Binding where Value == Length {
    func asText(
        format: @escaping (Double) -> String = { Format.smartFormat($0) },
        sanitize: @escaping (_ old: String, _ new: String) -> String = { old, new in new } // or your limiter
    ) -> Binding<String> {

        Binding<String>(
            get: {
                let v = wrappedValue.displayValue
                return v == 0 ? "" : format(v)
            },
            set: { newText in
                let old = format(wrappedValue.displayValue)
                let filtered = sanitize(old, newText)
                if let v = Double(filtered) {
                    var copy = wrappedValue
                    copy.set(v)
                    wrappedValue = copy
                }
            }
        )
    }
}

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

// MARK: Speed
struct Speed: Codable, Equatable, Hashable {
    // Canonical storage in km/h
    private var kmh: Double

    // MARK: - Inits
    init(kmh: Double) { self.kmh = max(0, kmh) }
    init(mph: Double) { self.kmh = max(0, mph * Self.kmPerMile) }

    // MARK: - Accessors
    var inKmH: Double { kmh }
    var inMPH: Double { kmh / Self.kmPerMile }

    // MARK: - Mutating setters
    mutating func setKmH(_ v: Double) { kmh = max(0, v) }
    mutating func setMPH(_ v: Double) { kmh = max(0, v * Self.kmPerMile) }

    /// Convenience: set using the current unit system (mph for imperial, km/h for metric).
    mutating func setDisplay(_ value: Double) {
        if UnitSystem.current == .imperial { setMPH(value) } else { setKmH(value) }
    }

    // MARK: - Display helpers
    var displayValue: Double {
        UnitSystem.current == .imperial ? inMPH : inKmH
    }

    var unitLabel: String {
        UnitSystem.current == .imperial ? "mph" : "km/h"
    }

    var formattedText: Text {
        Text(Format.smartFormat(displayValue)) +
        Text(" ") +
        Text(unitLabel).fontWeight(.light)
    }

    // MARK: - Constants
    private static let kmPerMile: Double = 1.609_344
}


//typealias Count = Int   // reps, sets, etc.
//typealias Ratio = Double // % values


//enum UnitCategory { case weightUnit, sizeUnit, none }
