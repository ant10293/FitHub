//
//  Adjustments.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation

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
    let id: UUID
    var equipmentAdjustments: [AdjustmentCategory: AdjustmentValue]
    let adjustmentImage: String
}
