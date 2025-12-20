//
//  SetLoad.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//

import Foundation
import SwiftUI

enum SetLoad: Codable, Equatable, Hashable {
    case weight(Mass)
    case distance(Distance)
    case band(ResistanceBandImplement)
    case none

    var fieldString: String {
        switch self {
        case .weight(let m): return m.fieldString
        case .distance(let d): return d.fieldString
        case .band(let b): return b.level.shortName
        case .none: return ""
        }
    }

    var actualValue: Double {
        switch self {
        case .weight(let m): return m.inKg
        case .distance(let d): return d.inKm
        case .band(let b): return b.weight.resolvedMass.inKg
        case .none: return 0
        }
    }

    var displayString: String {
        switch self {
        case .weight(let m): return m.displayString
        case .distance(let d): return d.displayString
        case .band(let b): return b.level.shortName
        case .none: return ""
        }
    }

    var formattedText: Text {
        switch self {
        case .weight(let m): return m.formattedText()
        case .distance(let d): return d.formattedText
        case .band(let b): return Text(b.level.shortName)
        case .none: return Text("Body-weight")
        }
    }

    var label: String {
        switch self {
        case .weight: return UnitSystem.current.weightUnit
        case .distance: return UnitSystem.current.distanceUnit
        case .band: return "Band"
        case .none: return ""
        }
    }

    var unit: UnitCategory? {
        switch self {
        case .weight: return .weight
        case .distance: return .distance
        case .band: return nil
        case .none: return nil
        }
    }
}

extension SetLoad {
    var weight: Mass? {
        if case .weight(let m) = self { return m }
        if case .band(let b) = self { return b.weight.resolvedMass }
        return nil
    }

    var distance: Distance? {
        if case .distance(let d) = self { return d }
        return nil
    }
    
    var bandImplement: ResistanceBandImplement? {
        if case .band(let b) = self { return b }
        return nil
    }
}

extension SetLoad {
    var iconName: String {
        switch self {
        case .weight: return "scalemass"
        case .distance: return "figure.walk"
        case .band: return "band"
        case .none: return ""
        }
    }
}
