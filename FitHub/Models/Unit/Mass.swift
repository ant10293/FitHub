//
//  Mass.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/22/25.
//

import Foundation
import SwiftUI

// MARK: Mass
struct Mass: Codable, Equatable, Hashable {
    private var kg: Double                 // canonical storage
    
    // MARK: – Inits
    init(kg: Double) { self.kg = kg }
    init(lb: Double) { self.kg = UnitSystem.LBtoKG(lb) }
    init(weight: Double) {
        self.kg = 0           // now self is fully initialized
        self.set(weight)      // safe to call mutating method
    }
    
    // MARK: – Accessors
    var inKg: Double { kg }
    var inLb: Double { UnitSystem.KGtoLB(kg) }
    
    /// Returns the weight in the caller‑specified unit system.
    var displayValue: Double {
        UnitSystem.current == .imperial ? inLb : inKg
    }
    
    var displayString: String { Format.smartFormat(displayValue) }
    
    func formattedText(asInteger: Bool = false) -> Text {
        let unitSystem = UnitSystem.current
        let display = asInteger ? String(Int(round(displayValue))) : Format.smartFormat(displayValue)
        
        return (Text("\(display) ") +
            Text(unitSystem.weightUnit).fontWeight(.light)
        )
    }
    
    var abs: Mass { Mass(kg: Swift.abs(inKg)) }
    
    /// Replace the mass with a new *kg* value.
    mutating func setKg(_ kg: Double) {
        self.kg = kg
    }
    
    /// Replace the mass with a new *lb* value (auto‑converts to kg).
    mutating func setLb(_ lb: Double) {
        self.kg = UnitSystem.LBtoKG(lb)
    }
    
    /// Convenience: update using the caller’s preferred unit system.
    mutating func set(_ value: Double) {
        self.kg = UnitSystem.current == .imperial ? UnitSystem.LBtoKG(value) : value
    }
}
extension Binding where Value == Mass {
    func asText(
        format: @escaping (Double) -> String = { Format.smartFormat($0) },
        sanitize: @escaping (_ old: String, _ new: String) -> String = { old, new in
            InputLimiter.filteredWeight(old: old, new: new)
        }
    ) -> Binding<String> {

        Binding<String>(
            get: {
                let v = wrappedValue.displayValue          // <- property you already have
                return v == 0 ? "" : format(v)
            },
            set: { newText in
                let old = format(wrappedValue.displayValue)
                let filtered = sanitize(old, newText)
                if let v = Double(filtered) {
                    var copy = wrappedValue
                    copy.set(v)                      // <- your current API (auto-uses UnitSystem.current)
                    wrappedValue = copy
                }
            }
        )
    }
}
