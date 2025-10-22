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
    /// Canonical backing-store in **centimeters**.
    private var cm: Double
    
    // MARK: – Inits
    init(cm: Double) { self.cm = cm }
    init(inch: Double) { self.cm = UnitSystem.INtoCM(inch) }
    init(length: Double) {
        self.cm = 0
        self.set(length)
    }
    
    // MARK: – Accessors
    var inCm: Double { cm }
    var inInch: Double { UnitSystem.CMtoIN(cm) }
    
    // MARK: – Display
    var displayValue: Double { UnitSystem.current == .imperial ? inInch : inCm }
    var displayString: String { Format.smartFormat(displayValue) }
    var fieldString: String { cm > 0 ? displayString : "" }
    
    // MARK: - Mutating setters
    mutating func setCm(_ cm: Double) { self.cm = cm }
    mutating func setIn(_ inch: Double) { self.cm = UnitSystem.INtoCM(inch) }
    mutating func set(_ value: Double) { /// Convenience: update using the caller’s preferred unit system.
        self.cm = UnitSystem.current == .imperial ? UnitSystem.INtoCM(value) : value
    }
    
    // MARK: – Unit
    var unit: UnitCategory { .size }
}

extension Length {
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
