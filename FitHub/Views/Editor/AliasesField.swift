//
//  AliasesField.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/10/25.
//

import SwiftUI

struct AliasesField: View {
    let aliases: [String]?
    let readOnly: Bool
    let onEdit: () -> Void

    var body: some View {
        let list = aliases ?? []
        return FieldEditor(
            title: "Aliases",
            valueText: list.isEmpty ? "None" : list.joined(separator: ", "),
            isEmpty: list.isEmpty,
            isReadOnly: readOnly,
            buttonLabel: "Add Alias",
            onEdit: onEdit
        )
    }
}

struct AliasesEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var aliases: [String]
    @State private var newAlias: String = ""
    @State private var isEditing: Bool = false
    @StateObject private var kbd = KeyboardManager.shared
    let onSave: ([String]) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Add") {
                    TextField("New alias", text: $newAlias)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .trailingIconButton(
                            systemName: "checkmark.circle.fill",
                            fgColor: .green,
                            disabled: !isNewValid,
                            action: addAlias
                        )
                }

                Section("Aliases") {
                    if aliases.isEmpty {
                        Text("No aliases yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(aliases.enumerated()), id: \.offset) { i, alias in
                            HStack(spacing: 8) {
                                InlineDeletion(isEditing: isEditing, delete: {
                                    deleteIndex(i)
                                })
                                TextField("", text: $aliases[i])
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                            }
                        }
                    }
                }
            }
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationBarTitle("Aliases", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                    .disabled(aliases.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        onSave(aliases)
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: aliases.count) { _, newCount in
            if newCount == 0 { isEditing = false }
        }
    }

    // MARK: - Logic
    private var trimmed: String { newAlias.trimmed }
    
    private var isNewValid: Bool {
        InputLimiter.isValidInput(trimmed)
        && !trimmed.isEmpty
        && !aliases.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    }
    
    private func addAlias() {
        kbd.dismiss()
        guard isNewValid else { return }
        aliases.append(trimmed)
        newAlias = ""
    }
    
    private func deleteIndex(_ i: Int) {
        kbd.dismiss()
        guard aliases.indices.contains(i) else { return }
        aliases.remove(at: i)
    }
}
