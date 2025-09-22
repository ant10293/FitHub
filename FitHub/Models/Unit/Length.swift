//
//  Length.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/22/25.
//

import Foundation
import SwiftUI

// MARK: Length
struct Length: Codable, Equatable, Hashable {
    private var cm: Double                 // canonical storage
    
    // MARK: – Inits
    init(cm: Double) { self.cm = cm }
    init(inch: Double) { self.cm = UnitSystem.INtoCM(inch) }
    
    // MARK: – Accessors
    var inCm: Double { cm }
    var inInch: Double { UnitSystem.CMtoIN(cm) }
    
    /// Returns the weight in the caller‑specified unit system.
    var displayValue: Double {
        UnitSystem.current == .imperial ? inInch : inCm
    }
    
    /// Replace the mass with a new *kg* value.
    mutating func setCm(_ cm: Double) {
        self.cm = cm
    }
    
    /// Replace the mass with a new *lb* value (auto‑converts to kg).
    mutating func setIn(_ inch: Double) {
        self.cm = UnitSystem.INtoCM(inch)
    }
    
    /// Convenience: update using the caller’s preferred unit system.
    mutating func set(_ value: Double) {
        self.cm = UnitSystem.current == .imperial ? UnitSystem.INtoCM(value) : value
    }
    
    var totalInches: Int { return Int(round(inInch)) }
    
    var heightFormatted: Text {
        if UnitSystem.current == .imperial {
            Text("\(totalInches / 12)")
            + Text(" ft ").fontWeight(.light)
            + Text("\(totalInches % 12)")
            + Text(" in").fontWeight(.light)
        } else {
            Text("\(Int(round(inCm)))")
            + Text(" cm").fontWeight(.light)
        }
    }
}
extension Binding where Value == Length {
    func asText(
        format: @escaping (Double) -> String = { Format.smartFormat($0) },
        sanitize: @escaping (_ old: String, _ new: String) -> String = { old, new in new } // or your limiter
    ) -> Binding<String> {

        Binding<String>(
            get: {
                let v = wrappedValue.displayValue
                return v == 0 ? "" : format(v)
            },
            set: { newText in
                let old = format(wrappedValue.displayValue)
                let filtered = sanitize(old, newText)
                if let v = Double(filtered) {
                    var copy = wrappedValue
                    copy.set(v)
                    wrappedValue = copy
                }
            }
        )
    }
}
