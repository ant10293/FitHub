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
    /// Canonical backing-store in **kilometers/hour**.
    private var kmh: Double

    // MARK: - Inits
    init(kmh: Double) { self.kmh = max(0, kmh) }
    init(mph: Double) { self.kmh = max(0, UnitSystem.MPHtoKMH(mph)) }
    init(speed: Double) {
        self.kmh = 0
        self.setDisplay(speed)
    }

    // MARK: - Accessors
    var inKmH: Double { kmh }
    var inMPH: Double { UnitSystem.KMHtoMPH(kmh) }

    // MARK: - Mutating setters
    mutating func setKmH(_ v: Double) { kmh = max(0, v) }
    mutating func setMPH(_ v: Double) { kmh = max(0, UnitSystem.MPHtoKMH(v)) }
    mutating func setDisplay(_ value: Double) {  /// Convenience: set using the current unit system (mph for imperial, km/h for metric).
        if UnitSystem.current == .imperial { setMPH(value) } else { setKmH(value) }
    }

    // MARK: – Display
    var displayValue: Double { UnitSystem.current == .imperial ? inMPH : inKmH }
    var displayString: String { Format.smartFormat(displayValue) }
    var fieldString: String { kmh > 0 ? displayString : "" }
    
    // MARK: – Unit
    var unit: UnitCategory { .speed }
}

extension Speed {
    var unitLabel: String { UnitSystem.current.speedUnit }

    var formattedText: Text {
        Text(displayString) +
        Text(" ") +
        Text(unitLabel).fontWeight(.light)
    }
}

extension Speed {
    // MARK: - Conversion Methods
    static func speedFromTime(_ time: TimeSpan, distance: Distance) -> Speed {
        guard time.inSeconds > 0 else { return Speed(kmh: 0) }
        
        // Convert distance to km and time to hours
        let distanceKm = distance.inKm
        let timeHours = Double(time.inSeconds) / 3600.0
        
        // Speed = Distance / Time
        let speedKmH = distanceKm / timeHours
        return Speed(kmh: speedKmH)
    }
    
    static func timeFromSpeed(_ speed: Speed, distance: Distance) -> TimeSpan {
        guard speed.kmh > 0 else { return TimeSpan(seconds: 0) }
        
        // Convert distance to km and speed to km/h
        let distanceKm = distance.inKm
        let speedKmH = speed.kmh
        
        // Time = Distance / Speed (in hours)
        let timeHours = distanceKm / speedKmH
        let timeSeconds = Int(timeHours * 3600.0)
        
        return TimeSpan(seconds: timeSeconds)
    }
    
}
