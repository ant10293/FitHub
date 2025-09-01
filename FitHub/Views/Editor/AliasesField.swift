//
//  AliasesField.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/10/25.
//

import SwiftUI

/// A self-contained editor for a list of alias strings.
struct AliasesField: View {
    // MARK: – External binding
    @Binding var aliases: [String]?

    // MARK: – Local state
    @State private var adding: Bool = false
    @State private var input: String = ""
    var readOnly: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // ── Label row ─────────────────────────────────────────────
            let label = aliases ?? []
            (
                Text("Aliases: ").font(.headline)
                +
                Text(label.isEmpty ? "None" : label.joined(separator: ", "))
                    .foregroundStyle(label.isEmpty ? .secondary : .primary)
            )
            .multilineTextAlignment(.leading)

            if !readOnly {
                // ── Add / edit row ───────────────────────────────────────
                if adding {
                    HStack {
                        TextField("Enter alias", text: $input, onCommit: appendIfValid)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorScheme == .dark
                                          ? .black.opacity(0.2)
                                          : Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(alignment: .trailing) {
                                Button {
                                    appendIfValid()
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(isValid ? .green : .gray)
                                }
                                .disabled(!isValid)
                                .padding(.trailing, 6)
                            }
                        
                        Button("Close") {
                            resetEditor()
                        }
                        .foregroundStyle(.red)
                    }
                } else {
                    Button {
                        adding = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add Alias")
                        }
                    }
                    .foregroundStyle(.blue)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: – Validation & helpers
    private var isValid: Bool {
        InputLimiter.isValidInput(input)
        && !input.trimmingCharacters(in: .whitespaces).isEmpty
        && !(aliases ?? []).contains {
            $0.caseInsensitiveCompare(input.trimmingCharacters(in: .whitespaces)) == .orderedSame
        }
    }

    private func appendIfValid() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValid else { return }
        if aliases == nil { aliases = [] }
        if aliases?.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) == true { return }
        aliases?.append(trimmed)
        input = ""
        adding = false
    }

    private func resetEditor() {
        input = ""
        adding = false
    }
}
