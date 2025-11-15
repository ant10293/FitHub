//
//  TimeEntryField.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/6/25.
//

import SwiftUI
import UIKit


struct TimeEntryField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "h:m:s"
    var style: TextFieldVisualStyle = .rounded  // .rounded | .plain
    var onCommit: ((String) -> Void)? = nil     // optional hook

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.placeholder = placeholder
        tf.font = UIFont.preferredFont(forTextStyle: .body)

        applyStyle(style, to: tf)

        tf.setContentHuggingPriority(.required, for: .vertical)
        tf.setContentCompressionResistancePriority(.required, for: .vertical)

        // Targets
        tf.addTarget(context.coordinator, action: #selector(Coordinator.onEditChanged(_:)), for: .editingChanged)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.onEditingEnded(_:)), for: .editingDidEnd)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.onEditingEnded(_:)), for: .editingDidEndOnExit)
        return tf
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        // 🔑 CRITICAL: point the coordinator at the *current* parent every update
        context.coordinator.parent = self

        if tf.placeholder != placeholder { tf.placeholder = placeholder }
        applyStyle(style, to: tf)

        guard !context.coordinator.isUpdatingFromSwiftUI else { return }
        if tf.text != text { tf.text = text }
    }

    // 🔧 Prevent stale callbacks from reused textfields
    static func dismantleUIView(_ tf: UITextField, coordinator: Coordinator) {
        tf.removeTarget(coordinator, action: #selector(Coordinator.onEditChanged(_:)), for: .editingChanged)
        tf.removeTarget(coordinator, action: #selector(Coordinator.onEditingEnded(_:)), for: .editingDidEnd)
        tf.removeTarget(coordinator, action: #selector(Coordinator.onEditingEnded(_:)), for: .editingDidEndOnExit)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        // NOTE: this MUST be reassigned in updateUIView to avoid stale bindings after swaps
        var parent: TimeEntryField
        var isUpdatingFromSwiftUI = false
        init(_ parent: TimeEntryField) { self.parent = parent }

        @objc func onEditChanged(_ tf: UITextField) {
            let old = tf.text ?? ""
            let formatted = Self.sanitize(old)
            if formatted != old {
                tf.text = formatted
                let end = tf.endOfDocument
                tf.selectedTextRange = tf.textRange(from: end, to: end)
            }
            isUpdatingFromSwiftUI = true
            parent.text = formatted
            isUpdatingFromSwiftUI = false
        }

        @objc func onEditingEnded(_ tf: UITextField) {
            let current = tf.text ?? ""
            let normalized = Self.sanitize(current)
            guard !normalized.isEmpty else {
                isUpdatingFromSwiftUI = true
                tf.text = ""
                parent.text = ""
                isUpdatingFromSwiftUI = false
                parent.onCommit?("")
                return
            }
            let ts = TimeSpan.seconds(from: normalized)
            let compact = ts.displayStringCompact
            if compact != tf.text {
                tf.text = compact
                let end = tf.endOfDocument
                tf.selectedTextRange = tf.textRange(from: end, to: end)
            }
            isUpdatingFromSwiftUI = true
            parent.text = compact
            isUpdatingFromSwiftUI = false
            parent.onCommit?(compact)
        }
              
        /// Keep only digits, rebuild as m:ss or h:mm:ss. If empty or all zeros, return "".
        private static func sanitize(_ raw: String) -> String {
            let digitsAll = raw.filter(\.isNumber)
            guard !digitsAll.isEmpty, digitsAll.contains(where: { $0 != "0" }) else {
                return ""
            }

            let digits = String(digitsAll.prefix(6))  // cap at HHMMSS
            let sec2 = String(digits.suffix(2)).leftPad2()

            if digits.count <= 2 {
                return "0:\(sec2)"                   // SS -> 0:SS
            }
            if digits.count <= 4 {
                let mins = String(digits.dropLast(2))
                let mStr = mins.isEmpty ? "0" : mins.trimLeadingZeros(emptyAsZero: true)
                return "\(mStr):\(sec2)"             // MMS S -> M:SS
            }

            let hours = String(digits.dropLast(4))
            let hStr  = hours.isEmpty ? "0" : hours.trimLeadingZeros(emptyAsZero: true)
            let min2  = String(digits.dropLast(2).suffix(2)).leftPad2()
            return "\(hStr):\(min2):\(sec2)"         // HHMMSS -> H:MM:SS
        }
    }

    // MARK: - Style
    private func applyStyle(_ style: TextFieldVisualStyle, to tf: UITextField) {
        switch style {
        case .rounded:
            tf.borderStyle = .roundedRect
            tf.backgroundColor = UIColor.systemBackground
            tf.layer.cornerRadius = 0
            tf.layer.masksToBounds = true
        case .plain:
            tf.borderStyle = .none
            tf.backgroundColor = .clear
            tf.layer.cornerRadius = 8
            tf.layer.borderWidth = 0
            tf.layer.masksToBounds = true
        }
    }
}

// MARK: - Helpers
private extension String {
    func leftPad2() -> String { count >= 2 ? self : String(repeating: "0", count: 2 - count) + self }
}

enum TextFieldVisualStyle { case plain, rounded }

