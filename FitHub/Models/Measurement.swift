//
//  Measurement.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI


struct Measurement: Codable, Identifiable {
    var id: UUID = UUID()
    let type: MeasurementType
    let entry: MeasurementValue
    let date: Date
}

enum MeasurementType: String, Codable, CaseIterable, Identifiable, Hashable, Equatable {
    // kg
    case weight = "Weight"
    
    // %
    case bodyFatPercentage = "Body Fat Percentage"
    
    // kcal
    case caloricIntake = "Caloric Intake"
    
    // n/a
    case bmi = "BMI"
    
    // cm
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
}
extension MeasurementType {
    var unitLabel: String? {
        switch self {
        case .weight: return UnitSystem.current.weightUnit
        case .bodyFatPercentage: return "%"
        case .caloricIntake: return "kcal"
        case .bmi: return nil // BMI has no unit
        default: return UnitSystem.current.sizeUnit
        }
    }
    
    func valueCategory(value: Double) -> MeasurementValue {
        switch self {
        case .weight: return .weight(Mass(kg: value))
        case .bodyFatPercentage: return .percentage(value)
        case .caloricIntake: return .calories(Int(value))
        case .bmi: return .bmi(value)
        default: return .size(Length(cm: value))
        }
    }
    
    func getMeasurmentValue(value: Double) -> MeasurementValue {
        return self.valueCategory(value: value)
    }
}

enum MeasurementValue: Codable, Equatable {
    // core
    case weight(Mass)
    case percentage(Double)
    case calories(Int)
    case bmi(Double)
    
    // body part
    case size(Length)

    // MARK: - Accessors
    /// depends on selected unit (imperial/metric)
    var displayValue: Double {
        switch self {
        case .weight(let mass): return mass.displayValue
        case .percentage(let percent): return percent
        case .calories(let calories): return Double(calories)
        case .bmi(let bmi): return bmi
        case .size(let length): return length.displayValue
        }
    }
    
    /// always in metric (kg/cm)
    var actualValue: Double {
        switch self {
        case .weight(let mass): return mass.inKg
        case .size(let length): return length.inCm
        default: return self.displayValue
        }
    }
    
    var asLength: Length? {
        if case .size(let length) = self { return length }
        return nil
    }
    
    var asMass: Mass? {
        if case .weight(let mass) = self { return mass }
        return nil
    }

    /// will convert:
    /// FALSE: the selected unit is metric
    /// FALSE: the selected unit is imperial and we are working with: .percentage, .calories,  or .bmi
    /// TRUE: the selected unit is imperial and we are working with: .weight or .size
    func metricDouble(from value: Double) -> Double {
        switch self {
        case .weight:
           return UnitSystem.current == .imperial ? UnitSystem.LBtoKG(value) : value
        case .size:
           return UnitSystem.current == .imperial ? UnitSystem.INtoCM(value) : value
        case .percentage, .calories, .bmi:
           return value
        }
    }
    
    var displayValueString: String { displayValue > 0 ? Format.smartFormat(displayValue) : "" }
    
    var unitLabel: String? {
        switch self {
        case .weight: return UnitSystem.current.weightUnit
        case .size:   return UnitSystem.current.sizeUnit
        case .percentage: return "%"
        case .calories:   return "kcal"
        case .bmi:        return nil
        }
    }
    
    var formattedText: Text {
        let value = Text(displayValueString)

        if let unit = unitLabel, !unit.isEmpty {
            return value
               + Text(" ")
               + Text(unit)
                   .fontWeight(.light)
        } else {
            return value
        }
    }
}
