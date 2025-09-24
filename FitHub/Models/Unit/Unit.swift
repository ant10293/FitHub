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
    var lengthUnit: String { self == .imperial ? "ft" : "m" }
    var distanceUnit: String { self == .imperial ? "mi" : "km" }
    var speedUnit: String { self == .imperial ? "mph" : "kmh" }
    
    var displayName: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric:   return "Metric (SI)"
        }
    }
        
    var desc: String { "\(displayName) • \(weightUnit) / \(sizeUnit) • \(lengthUnit) / \(distanceUnit)" }
    
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
    private static let cmPerIn: Double = 2.54
    private static let inPerCm: Double = 1 / cmPerIn // ≈ 0.3937007874
    
    private static let kgPerLb: Double = 0.45359237
    private static let lbPerKg: Double = 1 / kgPerLb // ≈ 2.20462262185
    
    private static let kmPerMi: Double = 1.609344
    private static let miPerKm: Double = 1 / kmPerMi // ≈ 0.62137119223

    // MARK: - Weight Conversions
    static func LBtoKG(_ pounds: Double) -> Double { pounds * kgPerLb }
    static func KGtoLB(_ kilograms: Double) -> Double { kilograms * lbPerKg }

    // MARK: - Length Conversions
    static func CMtoIN(_ centimeters: Double) -> Double { centimeters * inPerCm }
    static func INtoCM(_ inches: Double) -> Double { inches * cmPerIn }
    
    // MARK: - Distance Conversions
    static func MItoKM(_ miles: Double) -> Double { miles * kmPerMi }
    static func KMtoMI(_ kilometers: Double) -> Double { kilometers * miPerKm }
    
    // MARK: - Speed Conversions
    static func MPHtoKMH(_ mph: Double) -> Double { mph * kmPerMi }
    static func KMHtoMPH(_ kmh: Double) -> Double { kmh * miPerKm }
}

struct Incline: Codable, Error, Equatable, Hashable {
    
}

//typealias Count = Int   // reps, sets, etc.
//typealias Ratio = Double // % values


//enum UnitCategory { case weightUnit, sizeUnit, none }
