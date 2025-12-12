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
    /// Canonical backing-store in **kilograms**.
    private var kg: Double

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

    // MARK: – Display
    var displayValue: Double { UnitSystem.current == .imperial ? inLb : inKg }
    var displayString: String { Format.smartFormat(displayValue) }
    var fieldString: String { kg > 0 ? displayString : "" }

    // MARK: - Mutating setters
    mutating func setKg(_ kg: Double) { self.kg = kg }
    mutating func setLb(_ lb: Double) { self.kg = UnitSystem.LBtoKG(lb) }
    mutating func set(_ value: Double) { /// Convenience: update using the caller’s preferred unit system.
        self.kg = UnitSystem.current == .imperial ? UnitSystem.LBtoKG(value) : value
    }

    // MARK: – Unit
    var unit: UnitCategory { .weight }
}

extension Mass {
    func formattedText(asInteger: Bool = false) -> Text {
        let display = asInteger ? String(Int(round(displayValue))) : Format.smartFormat(displayValue)
        return (Text("\(display) ") + Text(UnitSystem.current.weightUnit).fontWeight(.light))
    }

    var abs: Mass { Mass(kg: Swift.abs(inKg)) }
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
