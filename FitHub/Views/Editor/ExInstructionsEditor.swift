//
//  ExInstructionsEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/12/25.
//

import SwiftUI


// FIXME: potential error - Publishing changes from within view updates is not allowed, this will cause undefined behavior.
struct ExInstructionsEditor: View {
    @Binding var instructions: ExerciseInstructions
    @FocusState private var focusedIndex: Int?
    @StateObject private var kbd = KeyboardManager.shared
    @State private var isEditing: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<instructions.count, id: \.self) { i in
                    HStack(spacing: 8) {
                        Text("\(i + 1).").foregroundStyle(.secondary)
                        TextField("Step \(i + 1)", text: binding(for: i))
                            .textInputAutocapitalization(.sentences)
                            .focused($focusedIndex, equals: i)
                    }
                }
                .onDelete(perform: delete)
                .onMove(perform: move)

                Button {
                    addStep()
                } label: {
                    Label("Add Step", systemImage: "plus")
                }
            }
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationBarTitle("Instructions", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                    .disabled(instructions.count == 0)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        // ✅ If list becomes empty while editing, exit edit mode
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

    private func addStep() {
        let newIndex = instructions.count
        instructions.add("")
        focusedIndex = newIndex
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets.sorted(by: >) { instructions.remove(at: i) }
    }

    private func move(from source: IndexSet, to destination: Int) {
        for s in source.sorted() {
            let dest = destination > s ? destination - 1 : destination
            instructions.move(from: s, to: dest)
        }
    }
}
