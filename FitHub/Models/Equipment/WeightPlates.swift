//
//  WeightPlates.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/17/25.
//

import Foundation
import SwiftUI

// should impact RoundingPreference
// TODO: Add sorting here
struct WeightPlates: Hashable, Codable {
    // default options (lb, kg)
    var lb: [Mass] = .init(WeightPlates.defaultLbPlates)
    var kg: [Mass] = .init(WeightPlates.defaultKgPlates)

    var resolvedPlates: [Mass] {
        switch UnitSystem.current {
        case .imperial: return lb
        case .metric: return kg
        }
    }

    mutating func setPlates(_ plates: [Mass]) {
        switch UnitSystem.current {
        case .imperial: self.lb = plates
        case .metric: self.kg = plates
        }
    }
}
extension WeightPlates {
    /// Fixed color palette by index (shared across lb + kg)
    private static let plateColors: [Color] = [
        .gray,    // index 0 (2.5 lb / 1.25 kg)
        .orange,   // index 1 (5 lb / 2.5 kg)
        .purple,   // index 2 (10 lb / 5 kg)
        .green,   // index 3 (25 lb / 10 kg)
        .yellow,  // index 4 (35 lb / 15 kg)
        .blue,    // index 5 (45 lb / 20 kg)
        .red      // index 6 (100 lb / 25 kg)
    ]
     /// Get the fixed color for a given plate
    static func color(for mass: Mass, in plates: [Mass]) -> Color {
        let sorted = sortedPlates(plates, ascending: true)
        if let idx = sorted.firstIndex(of: mass), idx < plateColors.count {
            return plateColors[idx]
        }
        return .secondary
    }

    static func sortedPlates(_ plates: [Mass], ascending: Bool) -> [Mass] {
        return plates
            .map { Mass(kg: $0.inKg) }
            .sorted { ascending ? $0.inKg < $1.inKg : $0.inKg > $1.inKg }
    }
}
extension WeightPlates {
    static func defaultOptions() -> [Mass] {
        UnitSystem.current == .imperial ? defaultLbPlates : defaultKgPlates
    }

    private static let defaultLbPlates: [Mass] = [
        Mass(lb: 2.5), Mass(lb: 5), Mass(lb: 10), Mass(lb: 25), Mass(lb: 45)
    ]

    private static let defaultKgPlates: [Mass] = [
        Mass(kg: 1.25), Mass(kg: 2.5), Mass(kg: 5), Mass(kg: 10), Mass(kg: 15), Mass(kg: 20), Mass(kg: 25)
    ]
}
extension WeightPlates {
    static func allOptions() -> [Mass] {
        UnitSystem.current == .imperial ? allLbPlates : allKgPlates
    }

    private static let allLbPlates: [Mass] = [
        Mass(lb: 2.5), Mass(lb: 5), Mass(lb: 10), Mass(lb: 25), Mass(lb: 35), Mass(lb: 45), Mass(lb: 100)
    ]

    private static let allKgPlates: [Mass] = [
        Mass(kg: 1.25), Mass(kg: 2.5), Mass(kg: 5), Mass(kg: 10), Mass(kg: 15), Mass(kg: 20), Mass(kg: 25)
    ]
}
