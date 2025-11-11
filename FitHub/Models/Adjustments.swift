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

struct ExerciseEquipmentAdjustments: Codable, Identifiable, Equatable, Hashable {
    let id: Exercise.ID
    var equipmentAdjustments: [EquipmentAdjustment]
    
    init(
        id: Exercise.ID,
        equipmentAdjustments: [EquipmentAdjustment],
        sorted: Bool = false
    ) {
        self.id = id
        self.equipmentAdjustments = equipmentAdjustments
        if sorted { setSorted() }
    }

    /// All categories represented in this adjustment list.
    var categories: Set<AdjustmentCategory> {
        Set(equipmentAdjustments.map(\.category))
    }
    
    func textValue(for category: AdjustmentCategory) -> String {
        adjustment(for: category)?.value.displayValue ?? ""
    }

    func adjustment(for category: AdjustmentCategory) -> EquipmentAdjustment? {
        equipmentAdjustments.first { $0.category == category }
    }

    static func sorted(_ adjustments: [EquipmentAdjustment]) -> [EquipmentAdjustment] {
        adjustments.sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    mutating func setSorted() {
        let sorted = ExerciseEquipmentAdjustments.sorted(equipmentAdjustments)
        equipmentAdjustments = sorted
    }

    mutating func withAdjustment(
        for category: AdjustmentCategory,
        createIfNeeded: Bool = true,
        update: (inout EquipmentAdjustment) -> Void
    ) {
        if let index = equipmentAdjustments.firstIndex(where: { $0.category == category }) {
            update(&equipmentAdjustments[index])
            return
        }

        guard createIfNeeded else { return }

        var entry = EquipmentAdjustment(category: category, value: .string(""), image: nil)
        update(&entry)
        equipmentAdjustments.append(entry)
    }

    mutating func addCategory(_ category: AdjustmentCategory) {
        withAdjustment(for: category) { _ in }
    }

    mutating func removeCategory(_ category: AdjustmentCategory) {
        equipmentAdjustments.removeAll { $0.category == category }
    }

    mutating func setValue(_ value: AdjustmentValue, for category: AdjustmentCategory) {
        withAdjustment(for: category) { adjustment in
            adjustment.value = value
        }
    }

    mutating func clearValue(for category: AdjustmentCategory) {
        setValue(.string(""), for: category)
    }

    mutating func setImage(_ image: String?, for category: AdjustmentCategory) {
        withAdjustment(for: category) { adjustment in
            adjustment.image = image
        }
    }

    mutating func normalize() {
        var merged: [AdjustmentCategory: EquipmentAdjustment] = [:]
        for entry in equipmentAdjustments {
            merged[entry.category] = entry
        }
        equipmentAdjustments = ExerciseEquipmentAdjustments.sorted(Array(merged.values))
    }

    func normalized() -> ExerciseEquipmentAdjustments {
        var copy = self
        copy.normalize()
        return copy
    }
}

struct EquipmentAdjustment: Codable, Equatable, Hashable {
    let category: AdjustmentCategory
    var value: AdjustmentValue
    /// Optional custom image stored on disk. Falls back to `category.image` when nil or empty.
    var image: String?
    
    var resolvedImage: String {
        guard let image, !image.isEmpty else { return category.image }
        return image
    }
    
    var hasCustomImage: Bool { image?.isEmpty == false }
}
