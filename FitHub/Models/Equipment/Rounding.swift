//
//  Rounding.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/17/25.
//

import Foundation

enum RoundingCategory: String, Codable, Equatable {
    case plated
    case platedIndependentPeg
    case pinLoaded
    case smallWeights
    
    var displayName: String {
        switch self {
        case .plated: "Plated"
        case .platedIndependentPeg: "Plated Independent Peg"
        case .pinLoaded: "Pin-Loaded"
        case .smallWeights: "Small Weights"
        }
    }
}

struct RoundingPreference: Codable, Equatable {
    var lb: [RoundingCategory: Mass] = [
        .plated: Mass(lb: 5),
        .platedIndependentPeg: Mass(lb: 2.5),
        .pinLoaded: Mass(lb: 2.5),
        .smallWeights: Mass(lb: 5)
    ]

    var kg: [RoundingCategory: Mass] = [
        .plated: Mass(kg: 2.5),
        .platedIndependentPeg: Mass(kg: 1.25),
        .pinLoaded: Mass(kg: 1.25),
        .smallWeights: Mass(kg: 2.5)
    ]

    var overallRange: ClosedRange<Double> {
        let values = UnitSystem.current == .imperial ? lb.values.map { $0.inLb } : kg.values.map { $0.inKg }
        guard let minValue = values.min(), let maxValue = values.max() else { return 0...0 }
        return minValue...maxValue
    }

    var summary: String {
        let unit = UnitSystem.current.weightUnit
        return "\(Format.formatRange(range: self.overallRange)) \(unit)"
    }

    func getRounding(for category: RoundingCategory) -> Double {
        if UnitSystem.current == .imperial {
            return (lb[category] ?? Mass(lb: 0)).inLb
        } else {
            return (kg[category] ?? Mass(kg: 0)).inKg
        }
    }

    mutating func setRounding(weight: Double, for category: RoundingCategory) {
        if UnitSystem.current == .imperial {
            lb[category] = Mass(lb: weight)
        } else {
            kg[category] = Mass(kg: weight)
        }
    }
}
