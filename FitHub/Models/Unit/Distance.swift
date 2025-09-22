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
    private var km: Double                 // canonical storage
    
    // MARK: – Inits
    init(km: Double) { self.km = km }
    init(mi: Double) { self.km = UnitSystem.MItoKM(mi) }
    
    // MARK: – Accessors
    var inKm: Double { km }
    var inMi: Double { UnitSystem.KMtoMI(km) }
    
    /// Returns the weight in the caller‑specified unit system.
    var displayValue: Double {
        UnitSystem.current == .imperial ? inMi : inKm
    }
    
    var displayString: String {
        Format.smartFormat(displayValue)
    }
    
    /// Replace the mass with a new *kg* value.
    mutating func setKm(_ km: Double) {
        self.km = km
    }
    
    /// Replace the mass with a new *lb* value (auto‑converts to kg).
    mutating func setMi(_ mi: Double) {
        self.km = UnitSystem.MItoKM(mi)
    }
    
    /// Convenience: update using the caller’s preferred unit system.
    mutating func set(_ value: Double) {
        self.km = UnitSystem.current == .imperial ? UnitSystem.MItoKM(value) : value
    }
        
    var formattedText: Text {
        Text(displayString)
        + Text(UnitSystem.imperial.distanceUnit).fontWeight(.light)
    }
}
