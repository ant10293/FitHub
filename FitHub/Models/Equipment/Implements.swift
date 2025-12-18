//
//  Implements.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/17/25.
//

import Foundation
import SwiftUI

/*
 MARK: EXTENSIVE ISSUES
 - Implements was an enum with values, but had to make it a stuct instead (not ideal but necessary to prevent manual encoding/decoding)
 
 Resistance Bands: Handle Bands, Loop Bands, Mini Loop Bands
 - available colors only accounts for available bands. It needs to account for ALL bands.
 - is initialized with no available bands
 
 Weight Implements: Dumbbells, Kettlebells, Medicine Ball, EZ Bar, Weight Plate
 - total Range doesn't reach max. e.g. stops at 147.5 when it should go up to 150
 - is initialized with no available weights
 - availableRange is NOT supposed to be a variable for the Weight struct, its only used so that we don't have to harcode a huge amount of Weight values
 
 WE NEED a new way to set this up. In 'equipment.json' we have no clear way to encode this but adding custom encoding/decoding is just so messy.
*/

/*
struct Implements: Codable, Equatable, Hashable {
    var weights: Weights?
    var resistanceBands: ResistanceBands?
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
    
    var weight: Weight {
        switch self {
        case .extraLight:
            return Weight(lb: 7.5, kg: 3.5)
        case .light:
            return Weight(lb: 15.0, kg: 7.0)
        case .medium:
            return Weight(lb: 25.0, kg: 11.0)
        case .heavy:
            return Weight(lb: 40.0, kg: 18.0)
        case .extraHeavy:
            return Weight(lb: 65.0, kg: 30.0)
        }
    }
}

struct ResistanceBandImplement: Codable, Equatable, Hashable {
    let level: ResistanceBand
    var color: ResistanceBandColor?
    var weight: Weight?
    
    var resolvedColor: ResistanceBandColor {
        color ?? level.defaultColor
    }
    
    var resolvedWeight: Weight {
        weight ?? level.weight
    }
}

struct ResistanceBands: Codable, Equatable, Hashable {
    var bands: [ResistanceBandImplement]
    
    // Helper to find band by level
    func band(for level: ResistanceBand) -> ResistanceBandImplement? {
        bands.first { $0.level == level }
    }
    
    func isAvailable(_ level: ResistanceBand) -> Bool {
        band(for: level) != nil
    }
    
    mutating func toggle(_ level: ResistanceBand) {
        if let index = bands.firstIndex(where: { $0.level == level }) {
            bands.remove(at: index)
        } else {
            bands.append(ResistanceBandImplement(level: level, color: nil, weight: nil))
        }
    }
    
    mutating func updateColor(_ level: ResistanceBand, color: ResistanceBandColor?) {
        if let index = bands.firstIndex(where: { $0.level == level }) {
            bands[index].color = color
        } else {
            bands.append(ResistanceBandImplement(level: level, color: color, weight: nil))
        }
    }
    
    mutating func updateWeight(_ level: ResistanceBand, weight: Weight?) {
        if let index = bands.firstIndex(where: { $0.level == level }) {
            bands[index].weight = weight
        } else {
            bands.append(ResistanceBandImplement(level: level, color: nil, weight: weight))
        }
    }
    
    func bandImplement(for level: ResistanceBand) -> ResistanceBandImplement {
        if let existing = band(for: level) {
            return existing
        }
        return ResistanceBandImplement(level: level, color: nil, weight: nil)
    }
    
    func availableColors(for level: ResistanceBand) -> [ResistanceBandColor] {
        // Get colors already used by other bands (excluding current band)
        let usedColors = Set(bands
            .filter { $0.level != level }
            .compactMap { $0.color ?? $0.level.defaultColor })
        
        // Get current band's color
        let currentBand = bandImplement(for: level)
        let currentColor = currentBand.resolvedColor
        
        // Filter available colors - exclude used colors, but always include current band's color
        return ResistanceBandColor.allCases.filter { color in
            color == currentColor || !usedColors.contains(color)
        }
    }
}

struct WeightRange: Codable, Equatable, Hashable {
    var min: Weight
    var max: Weight
    var increment: Weight
}

struct Weights: Codable, Equatable, Hashable {
    var implements: [Weight]  // The actual stored array of all available weights
    var totalRange: WeightRange  // Metadata for defaults
    var availableRange: WeightRange?  // Optional range used to generate implements if not provided
    
    func isSelected(_ weight: Weight) -> Bool {
        implements.contains { $0.lb == weight.lb && $0.kg == weight.kg }
    }
    
    mutating func toggle(_ weight: Weight) {
        if let index = implements.firstIndex(where: { $0.lb == weight.lb && $0.kg == weight.kg }) {
            implements.remove(at: index)
        } else {
            implements.append(weight)
            implements.sort { $0.resolved < $1.resolved }
        }
    }
    
    func allWeights() -> [Weight] {
        var weights: [Weight] = []
        var currentLb = totalRange.min.lb
        var currentKg = totalRange.min.kg
        let maxLb = totalRange.max.lb
        let maxKg = totalRange.max.kg
        let incLb = totalRange.increment.lb
        let incKg = totalRange.increment.kg
        
        while currentLb <= maxLb && currentKg <= maxKg {
            weights.append(Weight(lb: currentLb, kg: currentKg))
            currentLb += incLb
            currentKg += incKg
        }
        
        return weights
    }
}

struct Weight: Codable, Equatable, Hashable {
    var lb: Double
    var kg: Double
    var resolved: Double {
        return UnitSystem.current == .imperial ? lb : kg
    }
    
    var displayString: String {
        let value = resolved
        let unit = UnitSystem.current.weightUnit
        return "\(Format.smartFormat(value)) \(unit)"
    }
}
*/
