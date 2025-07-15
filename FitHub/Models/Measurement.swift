//
//  Measurement.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


struct Measurement: Codable, Identifiable {
    var id: UUID = UUID()
    let type: MeasurementType
    let value: Double
    let date: Date
}

enum MeasurementType: String, Codable, CaseIterable, Identifiable, Hashable, Equatable {
    case weight = "Weight"
    case bodyFatPercentage = "Body Fat Percentage"
    case caloricIntake = "Caloric Intake"
    case bmi = "BMI"
    case neck = "Neck"
    case shoulders = "Shoulders"
    case chest = "Chest"
    case leftBicep = "Left Bicep"
    case rightBicep = "Right Bicep"
    case leftForearm = "Left Forearm"
    case rightForearm = "Right Forearm"
    case upperAbs = "Upper Abs"
    case waist = "Waist"
    case lowerAbs = "Lower Abs"
    case hips = "Hips"
    case leftThigh = "Left Thigh"
    case rightThigh = "Right Thigh"
    case leftCalf = "Left Calf"
    case rightCalf = "Right Calf"
    
    var id: String { rawValue }
    
    static let coreMeasurements: [MeasurementType] = [
        .weight, .bodyFatPercentage, .caloricIntake, .bmi
    ]
    
    static let bodyPartMeasurements: [MeasurementType] = [
        .neck, .shoulders, .chest, .leftBicep, .rightBicep,
        .leftForearm, .rightForearm, .upperAbs, .waist,
        .lowerAbs, .hips, .leftThigh, .rightThigh, .leftCalf,
        .rightCalf
    ]
    
    var unitLabel: String? {
        switch self {
        case .weight:
            return "lb"
        case .bodyFatPercentage:
            return "%"
        case .caloricIntake:
            return "kcal"
        case .bmi:
            return nil
        default:
            return "in"
        }
    }
    
    /*var shortName: String {
        switch self {
        case .bodyFatPercentage:
            return "Body Fat %"
        case .caloricIntake:
            return "Calories"
        case .leftBicep:
            return "L Bicep"
        case .rightBicep:
            return "R Bicep"
        case .leftForearm:
            return "L Forearm"
        case .rightForearm:
            return "R Forearm"
        case .leftThigh:
            return "L Thigh"
        case .rightThigh:
            return "R Thigh"
        case .leftCalf:
            return "L Calf"
        case .rightCalf:
            return "R Calf"
        default:
            return rawValue
        }
    }*/
}
