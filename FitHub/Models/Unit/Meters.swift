//
//  Meters.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/9/25.
//

import Foundation
import SwiftUI

// MARK: Meters
struct Meters: Codable, Equatable, Hashable {
    /// Canonical backing-store in **meters**.
    private var meters: Double

    // MARK: – Inits
    init(meters: Double) { self.meters = meters }
    init() { self.meters = 0 }

    // MARK: – Accessors
    var inM: Double { meters }
    var inKm: Double { meters / 1000.0 }

    // MARK: – Display
    var displayValue: Double { meters }
    var displayString: String { Format.smartFormat(displayValue) }
    var fieldString: String { meters > 0 ? displayString : "" }

    // MARK: - Mutating setters
    mutating func set(_ value: Double) { self.meters = value }

    // MARK: – Unit
    var unit: UnitCategory { .distance }
}

extension Meters {
    var formattedText: Text {
        Text(displayString)
        + Text(" ")
        + Text("m").fontWeight(.light)
    }
}
