//
//  Distance.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/22/25.
//

import Foundation
import SwiftUI

// MARK: Distance
struct Distance: Codable, Equatable, Hashable {
    /// Canonical backing-store in **kilometers**.
    private var km: Double

    // MARK: – Inits
    init(km: Double) { self.km = km }
    init(mi: Double) { self.km = UnitSystem.MItoKM(mi) }
    init(distance: Double) {
        self.km = 0
        self.set(distance)
    }

    // MARK: – Accessors
    var inKm: Double { km }
    var inMi: Double { UnitSystem.KMtoMI(km) }

    // MARK: – Display
    var displayValue: Double { UnitSystem.current == .imperial ? inMi : inKm }
    var displayString: String { Format.smartFormat(displayValue) }
    var fieldString: String { km > 0 ? displayString : "" }

    // MARK: - Mutating setters
    mutating func setKm(_ km: Double) { self.km = km }
    mutating func setMi(_ mi: Double) { self.km = UnitSystem.MItoKM(mi) }
    mutating func set(_ value: Double) {  /// Convenience: update using the caller’s preferred unit system.
        self.km = UnitSystem.current == .imperial ? UnitSystem.MItoKM(value) : value
    }

    // MARK: – Unit
    var unit: UnitCategory { .distance }
}

extension Distance {
    var formattedText: Text {
        Text(displayString)
        + Text(" ")
        + Text(UnitSystem.imperial.distanceUnit).fontWeight(.light)
    }
}
