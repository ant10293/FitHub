//
//  Implements.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/17/25.
//

import Foundation
import SwiftUI

struct Implements: Codable, Equatable, Hashable {
    var weights: Weights?
    var resistanceBands: ResistanceBands?
    
    var subtitle: String? {
        if let w = weights, !w.sortedImplements.isEmpty {
            return w.sortedImplements.map { String($0.resolvedMass.displayValue) }.joined(separator: ", ")
        } else if let rb = resistanceBands, !rb.sortedBands.isEmpty {
            return rb.sortedBands.map { $0.level.displayName }.joined(separator: ", ")
        }
        return nil
    }
    
    /// Apply defaults and drop temporary fields after decoding.
    mutating func applyDefaults() {
        if var w = weights {
            w.applyDefaults()
            weights = w
        }
        
        if var rb = resistanceBands {
            rb.applyDefaults()
            resistanceBands = rb
        }
    }
}

enum ResistanceBandColor: String, Codable, CaseIterable, Equatable, Hashable {
    case yellow
    case green
    case red
    case blue
    case darkGray
    case orange
    case purple
    case pink
    case teal
    case indigo
    case lightBlue
    case lime
    case amber
    case cyan
    case brown
    
    var color: Color {
        switch self {
        case .yellow: return .yellow
        case .green: return .green
        case .red: return .red
        case .blue: return .blue
        case .darkGray: return Color(white: 0.13) // #212121
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .teal: return Color(red: 0, green: 0.59, blue: 0.53) // #009688
        case .indigo: return Color(red: 0.25, green: 0.32, blue: 0.71) // #3F51B5
        case .lightBlue: return Color(red: 0.01, green: 0.66, blue: 0.96) // #03A9F4
        case .lime: return Color(red: 0.80, green: 0.86, blue: 0.22) // #CDDC39
        case .amber: return Color(red: 1.0, green: 0.76, blue: 0.03) // #FFC107
        case .cyan: return Color(red: 0, green: 0.74, blue: 0.83) // #00BCD4
        case .brown: return Color(red: 0.47, green: 0.33, blue: 0.28) // #795548
        }
    }
    
    var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .red: return "Red"
        case .blue: return "Blue"
        case .darkGray: return "Dark Gray"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .teal: return "Teal"
        case .indigo: return "Indigo"
        case .lightBlue: return "Light Blue"
        case .lime: return "Lime"
        case .amber: return "Amber"
        case .cyan: return "Cyan"
        case .brown: return "Brown"
        }
    }
}

enum ResistanceBand: Int, Codable, CaseIterable, Equatable, Hashable {
    case extraLight = 1
    case light = 2
    case medium = 3
    case heavy = 4
    case extraHeavy = 5
    
    var level: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .extraLight: return "Extra Light"
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        case .extraHeavy: return "Extra Heavy"
        }
    }
    
    var defaultColor: ResistanceBandColor {
        switch self {
        case .extraLight: return .yellow
        case .light: return .green
        case .medium: return .red
        case .heavy: return .blue
        case .extraHeavy: return .darkGray
        }
    }
}

struct ResistanceBandImplement: Codable, Equatable, Hashable {
    let level: ResistanceBand
    var color: ResistanceBandColor?
    var weight: BaseWeight?
    
    var resolvedColor: ResistanceBandColor {
        color ?? level.defaultColor
    }
}

struct ResistanceBands: Codable, Equatable, Hashable {
    var useAllDefaults: Bool?
    var bands: [ResistanceBandImplement]? = nil
    
    /// Temporary field for manual band entry from JSON: [String: BaseWeight]
    /// Key is bandLevel as string ("1"-"5"), value is the weight for that band
    /// This will be converted to bands array in applyDefaults()
    /// In JSON, use nested structure: "resistanceBands": { "bandsDict": { "1": {...}, "2": {...} } }
    var bandsDict: [String: BaseWeight]?
    
    var sortedBands: [ResistanceBandImplement] {
        (bands ?? []).sorted { $0.level.rawValue < $1.level.rawValue }
    }
    
    // Helper to find band by level
    func band(for level: ResistanceBand) -> ResistanceBandImplement? {
        (bands ?? []).first { $0.level == level }
    }
    
    func isAvailable(_ level: ResistanceBand) -> Bool {
        band(for: level) != nil
    }
    
    mutating func toggle(_ level: ResistanceBand) {
        var arr = bands ?? []
        if let index = arr.firstIndex(where: { $0.level == level }) {
            arr.remove(at: index)
        } else {
            arr.append(ResistanceBandImplement(level: level, color: nil, weight: nil))
        }
        bands = arr
    }
    
    mutating func updateColor(_ level: ResistanceBand, color: ResistanceBandColor?) {
        var arr = bands ?? []
        if let index = arr.firstIndex(where: { $0.level == level }) {
            arr[index].color = color
        } else {
            arr.append(ResistanceBandImplement(level: level, color: color, weight: nil))
        }
        bands = arr
    }
    
    mutating func updateWeight(_ level: ResistanceBand, weight: Double) {
        var arr = bands ?? []
        if let index = arr.firstIndex(where: { $0.level == level }) {
            if var existingWeight = arr[index].weight {
                existingWeight.setWeight(weight)
                arr[index].weight = existingWeight
            } else {
                arr[index].weight = BaseWeight(weight: weight)
            }
        } else {
            arr.append(ResistanceBandImplement(level: level, color: nil, weight: BaseWeight(weight: weight)))
        }
        bands = arr
    }
    
    func bandImplement(for level: ResistanceBand) -> ResistanceBandImplement {
        if let existing = band(for: level) { return existing }
        return ResistanceBandImplement(level: level, color: nil, weight: nil)
    }
    
    func availableColors(for level: ResistanceBand) -> [ResistanceBandColor] {
        // Consider all five levels (even if not currently present) so colors stay unique across levels.
        let usedColors = Set(ResistanceBand.allCases
            .filter { $0 != level }
            .map { bandImplement(for: $0).resolvedColor })
        
        let currentColor = bandImplement(for: level).resolvedColor
        
        return ResistanceBandColor.allCases.filter { color in
            color == currentColor || !usedColors.contains(color)
        }
    }
    
    /// Populate defaults for all five levels if needed.
    mutating private func populateDefaultsIfNeeded() {
        guard bands?.isEmpty ?? true else { return }
        bands = ResistanceBand.allCases.map { level in
            ResistanceBandImplement(level: level, color: nil, weight: nil)
        }
    }
    
    /// Apply defaults and convert bandsDict to bands array if needed.
    mutating func applyDefaults() {
        // Convert manually entered bands dictionary to ResistanceBandImplement array
        if let dict = bandsDict, bands == nil || bands?.isEmpty == true {
            bands = dict.compactMap { (levelString, weight) -> ResistanceBandImplement? in
                guard let levelInt = Int(levelString),
                      let level = ResistanceBand(rawValue: levelInt) else { return nil }
                return ResistanceBandImplement(level: level, color: nil, weight: weight)
            }
            bandsDict = nil
        }
        
        if useAllDefaults == true {
            populateDefaultsIfNeeded()
        }
        useAllDefaults = nil
    }
}

struct WeightRange: Codable, Equatable, Hashable {
    var min: BaseWeight
    var max: BaseWeight
    var increment: BaseWeight
}

struct Weights: Codable, Equatable, Hashable {
    var implements: [BaseWeight]? = nil  // The actual stored array of all available weights (can be nil when omitted in JSON)
    var totalRange: WeightRange  // Metadata for defaults
    
    /// Temporary field decoded from JSON to generate implements; should be discarded after generation.
    var availableRange: WeightRange?
    
    var sortedImplements: [BaseWeight] {
        (implements ?? []).sorted { $0.resolvedMass.displayValue < $1.resolvedMass.displayValue }
    }
    
    private func matches(_ a: BaseWeight, _ b: BaseWeight) -> Bool {
        abs(a.resolvedMass.displayValue - b.resolvedMass.displayValue) < 1e-6
    }
    
    func isSelected(_ weight: BaseWeight) -> Bool {
        (implements ?? []).contains { matches($0, weight) }
    }
    
    mutating func toggle(_ weight: BaseWeight) {
        var arr = implements ?? []
        if let index = arr.firstIndex(where: { matches($0, weight) }) {
            arr.remove(at: index)
        } else {
            arr.append(weight)
            arr.sort { $0.resolvedMass.displayValue < $1.resolvedMass.displayValue }
        }
        implements = arr
    }
    
    /// Shared helper to build weights from a range (inclusive of max).
    private func buildWeights(from range: WeightRange) -> [BaseWeight] {
        var weights: [BaseWeight] = []
        var currentLb = range.min.lb
        var currentKg = range.min.kg
        let maxLb = range.max.lb
        let incLb = range.increment.lb
        let incKg = range.increment.kg
        
        var safety = 0
        while currentLb <= maxLb + 1e-9 && safety < 100 {
            weights.append(BaseWeight(lb: currentLb, kg: currentKg))
            currentLb += incLb
            currentKg += incKg
            safety += 1
        }
        return weights
    }
    
    /// All weights based on totalRange (inclusive max).
    func allWeights() -> [BaseWeight] {
        buildWeights(from: totalRange)
    }
    
    /// Generate weights from a range (inclusive of max) and assign to implements.
    mutating func generateImplements(from range: WeightRange) {
        implements = buildWeights(from: range)
    }
    
    /// Apply defaults and drop temporary fields after decoding.
    mutating func applyDefaults() {
        if implements == nil || implements?.isEmpty == true {
            if let ar = availableRange {
                generateImplements(from: ar)
            } else {
                // Fallback to totalRange if no availableRange was provided
                generateImplements(from: totalRange)
            }
        }
        availableRange = nil
    }
}

