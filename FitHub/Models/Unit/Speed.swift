//
//  Speed.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/22/25.
//

import Foundation
import SwiftUI

// MARK: Speed
struct Speed: Codable, Equatable, Hashable {
    // Canonical storage in km/h
    private var kmh: Double

    // MARK: - Inits
    init(kmh: Double) { self.kmh = max(0, kmh) }
    init(mph: Double) { self.kmh = max(0, mph * Self.kmPerMile) }

    // MARK: - Accessors
    var inKmH: Double { kmh }
    var inMPH: Double { kmh / Self.kmPerMile }

    // MARK: - Mutating setters
    mutating func setKmH(_ v: Double) { kmh = max(0, v) }
    mutating func setMPH(_ v: Double) { kmh = max(0, v * Self.kmPerMile) }

    /// Convenience: set using the current unit system (mph for imperial, km/h for metric).
    mutating func setDisplay(_ value: Double) {
        if UnitSystem.current == .imperial { setMPH(value) } else { setKmH(value) }
    }

    // MARK: - Display helpers
    var displayValue: Double {
        UnitSystem.current == .imperial ? inMPH : inKmH
    }

    var unitLabel: String {
        UnitSystem.current == .imperial ? "mph" : "km/h"
    }

    var formattedText: Text {
        Text(Format.smartFormat(displayValue)) +
        Text(" ") +
        Text(unitLabel).fontWeight(.light)
    }

    // MARK: - Constants
    private static let kmPerMile: Double = 1.609_344
}
