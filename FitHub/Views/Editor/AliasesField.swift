//
//  AliasesField.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/10/25.
//

import SwiftUI

struct AliasesField: View {
    @Binding var aliases: [String]?
    @State private var showSheet = false
    let readOnly: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            let label = aliases ?? []
            (
                Text("Aliases: ").font(.headline)
                + Text(label.isEmpty ? "None" : label.joined(separator: ", "))
                    .foregroundStyle(label.isEmpty ? .secondary : .primary)
            )

            if !readOnly {
                Button {
                    showSheet = true
                } label: {
                    Label("Add Alias", systemImage: "plus")
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showSheet) {
            AliasesEditorSheet(
                aliases: Binding(
                    get: { aliases ?? [] },
                    set: { new in aliases = new.isEmpty ? nil : new }
                )
            )
        }
    }
}

private struct AliasesEditorSheet: View {
    @Binding var aliases: [String]
    @State private var newAlias: String = ""
    @State private var isEditing: Bool = false
    @StateObject private var kbd = KeyboardManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Add") {
                    HStack {
                        TextField("New alias", text: $newAlias)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .onSubmit(addAlias)

                        Button {
                            addAlias()
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .disabled(!isNewValid)
                        .accessibilityLabel("Add alias")
                    }
                }

                Section("Aliases") {
                    if aliases.isEmpty {
                        Text("No aliases yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(aliases.enumerated()), id: \.offset) { i, alias in
                            HStack(spacing: 10) {
                                if isEditing {
                                    Button(role: .destructive) {
                                        withAnimation { deleteIndex(i) }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text(alias)
                                Spacer()
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
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: aliases.count) { _, newCount in
            if newCount == 0 { isEditing = false }
        }
    }

    // MARK: - Logic
    private var trimmed: String {
        newAlias.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isNewValid: Bool {
        InputLimiter.isValidInput(trimmed)
        && !trimmed.isEmpty
        && !aliases.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    }
    
    private func addAlias() {
        guard isNewValid else { return }
        aliases.append(trimmed)
        newAlias = ""
    }
    
    private func deleteIndex(_ i: Int) {
        guard aliases.indices.contains(i) else { return }
        aliases.remove(at: i)
    }
}
