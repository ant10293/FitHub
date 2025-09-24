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
    
    var weight: Mass? {
        if case .weight(let w) = self { return w }
        return nil
    }
    
    var distance: Distance? {
        if case .distance(let d) = self { return d }
        return nil
    }
    
    var iconName: String {
        switch self {
        case .weight: return "scalemass"
        case .distance: return "figure.walk"
        case .none: return ""
        }
    }
    
    var actualValue: Double {
        switch self {
        case .weight(let w): return w.displayValue
        case .distance(let d): return d.displayValue
        case .none: return 0
        }
    }
    
    var displayString: String {
        switch self {
        case .weight(let w): return w.displayString
        case .distance(let d): return d.displayString
        case .none: return ""
        }
    }
    
    var formattedText: Text {
        switch self {
        case .weight(let w): return w.formattedText()
        case .distance(let d): return d.formattedText
        case .none: return Text("Body-weight")
        }
    }
    
    var label: String {
        switch self {
        case .weight: return UnitSystem.current.weightUnit
        case .distance: return "Distance"
        case .none: return ""
        }
    }
}

