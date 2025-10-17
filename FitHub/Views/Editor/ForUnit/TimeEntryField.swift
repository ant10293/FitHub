//
//  TimeEntryField.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/6/25.
//

import SwiftUI
import UIKit

/// A simple masked time entry field that always renders as "m:ss".
/// - The user can type only digits.
/// - The ":" is effectively non-removable (we reinsert it every time).
/// - No normalization/carry: "1:60" stays "1:60".
// TODO: should take a TimeSpan type instead of String
struct TimeEntryField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "h:m:s"
    var style: TextFieldVisualStyle = .rounded  // .rounded | .plain

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.placeholder = placeholder
        tf.font = UIFont.preferredFont(forTextStyle: .body)

        // ✅ Make it look like a standard TextField
        applyStyle(style, to: tf)

        // Sizing (avoid weird tall expansion)
        tf.setContentHuggingPriority(.required, for: .vertical)
        tf.setContentCompressionResistancePriority(.required, for: .vertical)

        tf.addTarget(context.coordinator, action: #selector(Coordinator.onEditChanged(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        // Keep style/placeholder up to date
        if tf.placeholder != placeholder { tf.placeholder = placeholder }
        applyStyle(style, to: tf)

        // Don’t clobber while coordinator is pushing to SwiftUI
        guard !context.coordinator.isUpdatingFromSwiftUI else { return }
        if tf.text != text {
            tf.text = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        var parent: TimeEntryField
        var isUpdatingFromSwiftUI = false

        init(_ parent: TimeEntryField) { self.parent = parent }

        @objc func onEditChanged(_ tf: UITextField) {
            let old = tf.text ?? ""
            let formatted = Self.sanitize(old)

            // ✅ IMPORTANT ORDER:
            // 1) set the new text
            // 2) then set the caret using the *new* document's end
            if formatted != old {
                tf.text = formatted
                let end = tf.endOfDocument
                tf.selectedTextRange = tf.textRange(from: end, to: end)  // caret at end
            }

            // Push to SwiftUI binding
            isUpdatingFromSwiftUI = true
            parent.text = formatted
            isUpdatingFromSwiftUI = false
        }   
        
        static func sanitize(_ raw: String) -> String {
            let digitsAll = raw.filter(\.isNumber)
            
            // empty or all zeros -> show nothing (keeps placeholder visible)
            guard !digitsAll.isEmpty, digitsAll.contains(where: { $0 != "0" }) else {
                return ""
            }
            
            let digits = String(digitsAll.prefix(6))  // freeze at 6 digits (HHMMSS)

            // normalize to total seconds
            let totalSeconds: Int = {
                switch digits.count {
                case 1...2: // SS
                    return Int(digits) ?? 0
                case 3...4: // MM SS
                    let s = Int(String(digits.suffix(2))) ?? 0
                    let m = Int(String(digits.dropLast(2))) ?? 0
                    return m * 60 + s
                default:    // 5...6 => HH MM SS
                    let s = Int(String(digits.suffix(2))) ?? 0
                    let m = Int(String(digits.dropLast(2).suffix(2))) ?? 0
                    let h = Int(String(digits.dropLast(4))) ?? 0 // 0...99 by construction
                    return h * 3600 + m * 60 + s
                }
            }()
            
            return Format.timeString(from: totalSeconds)
        }
    }

    // MARK: - Style
    private func applyStyle(_ style: TextFieldVisualStyle, to tf: UITextField) {
        switch style {
        case .rounded:
            tf.borderStyle = .roundedRect
            tf.backgroundColor = UIColor.systemBackground // not clear
            tf.layer.cornerRadius = 0 // .roundedRect already handles corners
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


