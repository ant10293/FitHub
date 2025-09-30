//
//  TimeEntryField.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/6/25.
//

import SwiftUI

/// A simple masked time entry field that always renders as "m:ss".
/// - The user can type only digits.
/// - The ":" is effectively non-removable (we reinsert it every time).
/// - No normalization/carry: "1:60" stays "1:60".
// TODO: should take a TimeSpan type instead of String
struct TimeEntryField: View {
    @Binding var text: String
    var placeholder: String = "h:mm:ss"
    var style: TextFieldVisualStyle = .rounded  // <- choose at callsite

    var body: some View {
        TextField(placeholder, text: Binding(
            get: { text },
            set: { newValue in
                text = Self.sanitize(newValue)
            }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .applyTextFieldStyle(style)   // <- switches style without ternary issues
    }

    /// Keep only digits, rebuild as m:ss. If no digits, return "".    
    private static func sanitize(_ raw: String) -> String {
        // Keep only digits
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }

        // Always pad seconds to 2
        let sec2 = String(digits.suffix(2)).leftPad2()

        // If we only have up to 2 digits total → "0:ss"
        if digits.count <= 2 { return "0:\(sec2)" }

        // If we have 3–4 digits total → "m:ss" (minutes = everything before the last 2)
        if digits.count <= 4 {
            let mins = String(digits.dropLast(2))
            let mStr = mins.isEmpty ? "0" : trimLeadingZeros(mins)
            return "\(mStr):\(sec2)"
        }

        // 5+ digits total → "h:mm:ss"
        // hours = everything before the last 4; minutes = the 2 digits before seconds
        let hours = String(digits.dropLast(4))
        let hStr  = hours.isEmpty ? "0" : trimLeadingZeros(hours)
        let min2  = String(digits.dropLast(2).suffix(2)).leftPad2()
        return "\(hStr):\(min2):\(sec2)"
    }

    private static func trimLeadingZeros(_ s: String) -> String {
        let result = s.drop { $0 == "0" }
        return result.isEmpty ? "0" : String(result)
    }
}

private extension String {
    func leftPad2() -> String {
        count >= 2 ? self : String(repeating: "0", count: 2 - count) + self
    }
}

enum TextFieldVisualStyle { case plain, rounded }

private extension View {
    @ViewBuilder
    func applyTextFieldStyle(_ style: TextFieldVisualStyle) -> some View {
        switch style {
        case .plain: self.textFieldStyle(.plain)
        case .rounded: self.textFieldStyle(.roundedBorder)
        }
    }
}
