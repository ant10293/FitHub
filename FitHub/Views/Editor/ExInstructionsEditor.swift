//
//  ExInstructionsEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/12/25.
//

import SwiftUI

struct ExInstructionsEditor: View {
    @State private var isEditing: Bool = false
    @Binding var instructions: ExerciseInstructions
    @FocusState private var focusedIndex: Int?
    @StateObject private var kbd = KeyboardManager.shared
    @State private var newStep: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Add Step") {
                    HStack {
                        HStack(spacing: 8) {
                            Text("\(instructions.newStepNumber).")
                                .foregroundStyle(.secondary)

                            TextField(
                                "Step #\(instructions.newStepNumber) Instructions",
                                text: $newStep,
                                axis: .vertical
                            )
                            .textInputAutocapitalization(.sentences)
                            .disableAutocorrection(true)
                        }
                        .trailingIconButton(
                            systemName: "checkmark.circle.fill",
                            fgColor: .green,
                            disabled: !isNewValid,
                            action: addStep
                        )
                    }
                }

                Section("Existing Steps") {
                    if instructions.steps.isEmpty {
                        Text("No steps added yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(0..<instructions.count, id: \.self) { i in
                            HStack(spacing: 8) {
                                InlineDeletion(isEditing: isEditing, delete: {
                                    deleteIndex(i)
                                })
                                Text("\(i + 1).")
                                    .foregroundStyle(.secondary)
                                
                                TextField(
                                    "Step #\(instructions.newStepNumber) Instructions",
                                    text: binding(for: i),
                                    axis: .vertical
                                )
                                .textInputAutocapitalization(.sentences)
                                .disableAutocorrection(true)
                                .focused($focusedIndex, equals: i)
                                .trailingIconButton(systemName: "line.horizontal.3")
                            }
                        }
                        .onMove(perform: move)
                    }
                }
            }
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationBarTitle("Instructions", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                    .disabled(instructions.steps.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: instructions.count) { _, newCount in
            if newCount == 0 { isEditing = false }
        }
    }

    // MARK: - Helpers
    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { instructions.step(at: index) ?? "" },
            set: { instructions.update($0, at: index) }
        )
    }

    private var trimmed: String { newStep.trimmed }
    
    private var isNewValid: Bool {
        InputLimiter.isValidInput(trimmed)
        && !trimmed.isEmpty
    }
    
    private func addStep() {
        kbd.dismiss()
        guard isNewValid else { return }
        instructions.add(trimmed)
        newStep = ""
    }
    
    private func deleteIndex(_ i: Int) {
        kbd.dismiss()
        instructions.remove(at: i)
    }

    private func move(from source: IndexSet, to destination: Int) {
        kbd.dismiss()
        for s in source.sorted() {
            let dest = destination > s ? destination - 1 : destination
            instructions.move(from: s, to: dest)
        }
    }
}
