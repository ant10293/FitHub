//
//  UnitCategories.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/20/25.
//

import SwiftUI

enum UnitCategory: String {
    case weight, reps, time, speed, distance, carryDistance, size, percent, calories
    
    private var label: Labeling {
        let current = UnitSystem.current
        switch self {
        case .weight: return Labeling(symbol: current.weightUnit, label: "Weight")
        case .reps: return Labeling(label: "Reps")
        case .time: return Labeling(label: "Time")
        case .speed: return Labeling(symbol: current.speedUnit, label: "Speed")
        case .distance: return Labeling(symbol: current.distanceUnit, label: "Distance")
        case .carryDistance: return Labeling(symbol: "m", label: "Carry Distance")
        case .size: return Labeling(symbol: current.sizeUnit, label: "Size")
        case .percent: return Labeling(symbol: "%", label: "Percent")
        case .calories: return Labeling(symbol: "kcal", label: "Calories")
        }
    }
    
    func label(for style: Style) -> String? {
        switch style {
        case .symbol: label.symbol
        case .label: label.label
        }
    }
    
    enum Style: String {
        case symbol /// e.g. lb, mph, mi
        case label /// e.g. Weight, Speed, Distance
    }
    
    private struct Labeling {
        let symbol: String?   // e.g. "lb", "reps", "sec", "mph", "mi"
        let label: String       // e.g. "Weight", "Reps", "Time", "Speed", "Distance"
        
        init(symbol: String? = nil, label: String) {
            self.symbol = symbol
            self.label = label
        }
    }
}
