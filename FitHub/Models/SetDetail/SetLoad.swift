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
    case none
    
    var fieldString: String {
        switch self {
        case .weight(let m): return m.fieldString
        case .distance(let d): return d.fieldString
        case .none: return ""
        }
    }
    
    var actualValue: Double {
        switch self {
        case .weight(let m): return m.inKg
        case .distance(let d): return d.inKm
        case .none: return 0
        }
    }
    
    var displayString: String {
        switch self {
        case .weight(let m): return m.displayString
        case .distance(let d): return d.displayString
        case .none: return ""
        }
    }
     
    var formattedText: Text {
        switch self {
        case .weight(let m): return m.formattedText()
        case .distance(let d): return d.formattedText
        case .none: return Text("Body-weight")
        }
    }
    
    var label: String {
        switch self {
        case .weight: return UnitSystem.current.weightUnit
        case .distance: return UnitSystem.current.distanceUnit
        case .none: return ""
        }
    }
    
    var unit: UnitCategory? {
        switch self {
        case .weight: return .weight
        case .distance: return .distance
        case .none: return nil
        }
    }
}

extension SetLoad {
    var weight: Mass? {
        if case .weight(let m) = self { return m }
        return nil
    }
    
    var distance: Distance? {
        if case .distance(let d) = self { return d }
        return nil
    }
}

extension SetLoad {
    var iconName: String {
        switch self {
        case .weight: return "scalemass"
        case .distance: return "figure.walk"
        case .none: return ""
        }
    }
}

