//
//  Adjustments.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI


enum AdjustmentValueCategory: String, Codable, CaseIterable {
    case number, letter, size, degrees
    
    var valueType: AdjustmentValue {
        switch self {
        case .number: return .number(nil)
        case .letter: return .letter(nil)
        case .size: return .size(nil)
        case .degrees: return .degrees(nil)
        }
    }
    
    var defaultValue: AdjustmentValue {
        switch self {
        case .number: return .number(0)
        case .letter: return .letter(.a)
        case .size: return .size(.xsmall)
        case .degrees: return .degrees(0)
        }
    }
}

enum AdjustmentSize: String, Codable, CaseIterable {
    case xsmall, small, medium, large, xlarge
}

enum AdjustmentLetter: String, Codable, CaseIterable {
    case a, b, c, d, e, f, g, h, i, j
}

enum AdjustmentValue: Codable, Equatable, Hashable {
    case number(Int?)
    case letter(AdjustmentLetter?)
    case size(AdjustmentSize?)
    case degrees(Int?)
    
    var displayValue: String {
        switch self {
        case .number(let n): return n.map { "\($0)" } ?? ""
        case .letter(let l): return l?.rawValue.capitalized ?? ""
        case .size(let s): return s?.rawValue ?? ""
        case .degrees(let d): return d.map { "\($0)°" } ?? ""
        }
    }
    
    var category: AdjustmentValueCategory {
        switch self {
        case .number: return .number
        case .letter: return .letter
        case .size: return .size
        case .degrees: return .degrees
        }
    }
    
    /// Converts the value to a new category, using nil if converting between incompatible types
    func converted(to category: AdjustmentValueCategory) -> AdjustmentValue {
        switch category {
        case .number:
            switch self {
            case .number(let n): return .number(n)
            default: return category.valueType
            }
        case .letter:
            switch self {
            case .letter(let l): return .letter(l)
            default: return category.valueType
            }
        case .size:
            switch self {
            case .size(let s): return .size(s)
            default: return category.valueType
            }
        case .degrees:
            switch self {
            case .degrees(let d): return .degrees(d)
            default: return category.valueType
            }
        }
    }
}

enum AdjustmentCategory: String, CaseIterable, Identifiable, Codable, Comparable, Equatable, Hashable {
    case seatHeight = "Seat Height"
    case benchAngle = "Bench Angle"

    case rackHeight = "Rack Height"
    case pulleyHeight = "Pulley Height"

    case padHeight = "Pad Height"

    case safetyBarHeight = "Safety Bar Height"

    //case seatDepth = "Seat Depth"
    case backPadDepth = "Back Pad Depth"

    case backPadAngle = "Back Pad Angle"

    case footPlateHeight = "Foot Plate Height"

    case legPadPosition = "Leg Pad Position"

    case sundialAdjustment = "Sundial Adjustment"

    case handlePosition = "Handle Position"

    case inclineGrade = "Incline Grade"


    var id: String { self.rawValue }

    var image: String {
        // Construct the image name using the raw value and base path
        let basePath = "Adjustments/"
        // Replace spaces with underscores for the image file names
        let formattedName = self.rawValue.replacingOccurrences(of: " ", with: "_")
        return basePath + formattedName
    }

    static func < (lhs: AdjustmentCategory, rhs: AdjustmentCategory) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    /// Returns the default value for this category (used when switching categories)
    var defaultValue: AdjustmentValue {
        switch self {
        case .seatHeight: return .number(0)
        case .benchAngle: return .degrees(0)
        case .rackHeight: return .number(0)
        case .pulleyHeight: return .number(0)
        case .padHeight: return .number(0)
        case .safetyBarHeight: return .number(0)
        case .backPadDepth: return .number(0)
        case .backPadAngle: return .degrees(0)
        case .footPlateHeight: return .number(0)
        case .legPadPosition: return .size(.xsmall)
        case .sundialAdjustment: return .letter(.a)
        case .handlePosition: return .number(0)
        case .inclineGrade: return .degrees(0)
        }
    }
    
    /// Returns a nil value for this category (used when creating new entries)
    var nilValue: AdjustmentValue {
        defaultValue.category.valueType
    }
}

struct ExerciseAdjustments: Codable, Identifiable, Equatable, Hashable {
    let id: Exercise.ID
    var entries: [AdjustmentEntry]

    init(
        id: Exercise.ID,
        entries: [AdjustmentEntry],
        sorted: Bool = false
    ) {
        self.id = id
        self.entries = entries
        if sorted { setSorted() }
    }

    /// All categories represented in this adjustment list.
    var categories: Set<AdjustmentCategory> {
        Set(entries.map(\.category))
    }

    mutating func setSorted() {
        let sorted = ExerciseAdjustments.sorted(entries)
        entries = sorted
    }

    mutating func withAdjustment(
        for category: AdjustmentCategory,
        createIfNeeded: Bool = true,
        update: (inout AdjustmentEntry) -> Void
    ) {
        if let index = entries.firstIndex(where: { $0.category == category }) {
            update(&entries[index])
            return
        }

        guard createIfNeeded else { return }

        // This is a fallback - in practice, entries should be created via loadAdjustments
        // which has access to equipment info. For now, create with dummy UUID.
        let dummyAdjustment = EquipmentAdjustment(id: UUID(), category: category)
        // Start with nil value to indicate no value has been set yet
        var entry = AdjustmentEntry(adjustment: dummyAdjustment, value: category.nilValue)
        update(&entry)
        entries.append(entry)
    }

    mutating func addCategory(_ category: AdjustmentCategory) {
        withAdjustment(for: category) { _ in }
    }

    mutating func removeCategory(_ category: AdjustmentCategory) {
        entries.removeAll { $0.category == category }
    }

    mutating func setValue(_ value: AdjustmentValue, for category: AdjustmentCategory) {
        withAdjustment(for: category) { adjustment in
            adjustment.value = value
        }
    }

    mutating func clearValue(for category: AdjustmentCategory) {
        // Set to nil to indicate no value has been set
        setValue(category.nilValue, for: category)
    }

    mutating func normalize() {
        var merged: [AdjustmentCategory: AdjustmentEntry] = [:]
        for entry in entries {
            merged[entry.category] = entry
        }
        entries = ExerciseAdjustments.sorted(Array(merged.values))
    }

    func normalized() -> ExerciseAdjustments {
        var copy = self
        copy.normalize()
        return copy
    }

    func textValue(for category: AdjustmentCategory) -> String {
        adjustment(for: category)?.value.displayValue ?? ""
    }

    func adjustment(for category: AdjustmentCategory) -> AdjustmentEntry? {
        entries.first { $0.category == category }
    }

    static func sorted(_ adjustments: [AdjustmentEntry]) -> [AdjustmentEntry] {
        adjustments.sorted { $0.category.rawValue < $1.category.rawValue }
    }
}

struct AdjustmentEntry: Codable, Equatable, Hashable {
    let adjustment: EquipmentAdjustment
    var value: AdjustmentValue
    /// The name of the equipment-level image that this exercise is ignoring (nil means no image is ignored)
    var ignoredEquipmentLevelImage: String? = nil

    // Computed properties for easier access
    var category: AdjustmentCategory { adjustment.category }
    var equipmentID: GymEquipment.ID { adjustment.id }
    /// Exercise-specific image override (nil means use equipment-level or default)
    var image: String? { adjustment.image }

    /// Resolves image with priority: exercise-specific → equipment-level → default
    /// Note: This only checks exercise-specific. Equipment-level resolution happens in AdjustmentsData.
    var resolvedImage: String { adjustment.resolvedImage }

    var hasCustomImage: Bool { adjustment.hasCustomImage }

    /// Creates an empty entry for the given key
    /// Note: equipment-level images are stored separately and resolved via AdjustmentsData.resolvedImage
    static func empty(for key: AdjustmentKey) -> AdjustmentEntry {
        // Start with nil value to indicate no value has been set yet
        guard let equipmentID = key.equipmentID else {
            // Fallback: create with a dummy UUID if equipmentID is nil (shouldn't happen in practice)
            let dummyAdjustment = EquipmentAdjustment(id: UUID(), category: key.category, image: nil)
            return AdjustmentEntry(adjustment: dummyAdjustment, value: key.category.nilValue, ignoredEquipmentLevelImage: nil)
        }

        let equipmentAdjustment = EquipmentAdjustment(id: equipmentID, category: key.category, image: nil)
        return AdjustmentEntry(adjustment: equipmentAdjustment, value: key.category.nilValue, ignoredEquipmentLevelImage: nil)
    }
}

struct EquipmentAdjustment: Codable, Identifiable, Equatable, Hashable {
    let id: GymEquipment.ID
    let category: AdjustmentCategory
    /// Optional custom image stored on disk. Falls back to `category.image` when nil or empty.
    var image: String?

    var resolvedImage: String {
        guard let image, !image.isEmpty else { return category.image }
        return image
    }

    var hasCustomImage: Bool { image?.isEmpty == false }
}

struct AdjustmentKey: Hashable, Codable, Equatable {
    let equipmentID: GymEquipment.ID?
    let category: AdjustmentCategory
}
