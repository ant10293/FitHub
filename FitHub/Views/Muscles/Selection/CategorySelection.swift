import SwiftUI


struct CategorySelection: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: SplitSelectionVM
    @State private var donePressed: Bool = false // tracks explicit ‘Done’
    @State private var askSave: Bool = false // controls alert
    let newTemplate: Bool
    let onSave: ([SplitCategory]) -> Void

    init(initial: [SplitCategory], newTemplate: Bool = false, onSave: @escaping ([SplitCategory]) -> Void) {
        _vm    = StateObject(wrappedValue: SplitSelectionVM(initialCategories: initial))
        self.newTemplate = newTemplate
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack {
                //  replace the whole “Muscle‑group grid + overlay” block
                MuscleSelection(
                    selectedCategories: vm.binding(for: vm.selectedDay),
                    showFront:          $vm.showFrontView,
                    displayName:        { vm.displayName(for: $0, on: vm.selectedDay) },
                    // convert (SplitCategory, DaysOfWeek?) → (SplitCategory) on the fly
                    toggle: { category in
                        vm.toggle(category, on: vm.selectedDay)     // still runs on MainActor
                    },
                    shouldDisable:      { vm.shouldDisable($0, on: vm.selectedDay) },
                    shouldShow:         { cat, list in vm.shouldShow(cat, in: list) }
                )

                Spacer()
            }
            .padding()
            .onDisappear {
                if !donePressed {
                    vm.saveIfNeeded(singleSave: onSave)
                }
            }
            .navigationBarTitle("Customize Split", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { vm.clearDay() }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        if newTemplate {
                            saveExitAction()
                        } else {
                            if vm.hasUnsavedChanges {
                                askSave = true           // trigger alert
                            } else {
                                donePressed = true
                                dismiss()
                            }
                        }
                    }
                }
            }
            .alert("Save Changes?", isPresented: $askSave) {
                Button("Discard", role: .destructive) {
                    vm.revertChanges()
                    donePressed = true
                    dismiss()
                }
                Button("Save") {
                    saveExitAction()
                }
            } message: {
                Text("Do you want to save your changes or discard them?")
            }
        }
    }
    
    private func saveExitAction() {
        vm.saveIfNeeded(singleSave: onSave)
        donePressed = true
        dismiss()
    }
}

extension View {
    /// Applies the “pill” look you’ve been using for muscle-group buttons.
    func muscleButtonStyle(selected: Bool, disabled: Bool) -> some View {
        self
            .padding(5)
            .frame(minWidth: 50, minHeight: 35)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .background(disabled
                        ? Color.gray
                        : (selected ? Color.blue : Color.secondary.opacity(0.8)))
            .foregroundStyle(disabled
                             ? Color.white.opacity(0.5)
                             : Color.white)
            .disabled(disabled)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(disabled ? 0.6 : 1.0)
    }
}

