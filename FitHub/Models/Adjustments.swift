//
//  Adjustments.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI

// New enum to handle different adjustment values
enum AdjustmentValue: Codable, Equatable, Hashable {
    case integer(Int)
    case string(String)

    var displayValue: String {
        switch self {
        case .integer(let value): return "\(value)"
        case .string(let value): return value
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .integer: return .numbersAndPunctuation
        case .string:  return .default
        }
    }

    static func from(_ stringValue: String) -> AdjustmentValue {
        if let intValue = Int(stringValue) {
            return .integer(intValue)
        } else {
            return .string(stringValue)
        }
    }
}

// TODO: add units for each category (%, Int, Small, etc)
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
        var entry = AdjustmentEntry(adjustment: dummyAdjustment, value: .string(""))
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
        setValue(.string(""), for: category)
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
        guard let equipmentID = key.equipmentID else {
            // Fallback: create with a dummy UUID if equipmentID is nil (shouldn't happen in practice)
            let dummyAdjustment = EquipmentAdjustment(id: UUID(), category: key.category, image: nil)
            return AdjustmentEntry(adjustment: dummyAdjustment, value: .string(""), ignoredEquipmentLevelImage: nil)
        }

        let equipmentAdjustment = EquipmentAdjustment(id: equipmentID, category: key.category, image: nil)
        return AdjustmentEntry(adjustment: equipmentAdjustment, value: .string(""), ignoredEquipmentLevelImage: nil)
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
