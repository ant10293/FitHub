import SwiftUI


struct CategorySelection: View {
    @Environment(\.presentationMode) var dismiss
    @StateObject private var vm: SplitSelectionVM
    @State private var donePressed: Bool = false // tracks explicit ‘Done’
    @State private var askSave: Bool = false // controls alert
    let newTemplate: Bool
    var gender: Gender
    let onSave: ([SplitCategory]) -> Void

    init(initial: [SplitCategory], newTemplate: Bool = false, gender: Gender, onSave: @escaping ([SplitCategory]) -> Void) {
        _vm    = StateObject(wrappedValue: SplitSelectionVM(initialCategories: initial))
        self.newTemplate = newTemplate
        self.gender = gender
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Muscle-group grid (no day selector)
                ForEach(0..<3) { col in
                    HStack(spacing: 3) {
                        ForEach(SplitCategory.columnGroups[col], id: \.self) { cat in
                            let list = vm.binding().wrappedValue
                            let selected = list.contains(cat)
                            let disabled = vm.shouldDisable(cat)
                            
                            if vm.shouldShow(cat, in: list) {
                                Button(vm.displayName(for: cat)) {
                                    vm.toggle(cat)
                                }
                                .muscleButtonStyle(selected: selected, disabled: disabled)
                            }
                        }
                    }
                    .padding(.horizontal, -10)
                }
                
                ZStack {
                    SimpleMuscleGroupsView(showFront: $vm.showFrontView, gender: gender, selectedSplit: vm.binding().wrappedValue)
                        .frame(height: 550)
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                vm.showFrontView.toggle()
                            }) {
                                Image(systemName: "arrow.2.circlepath")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 20)
                            .padding(.top, -100)
                        }
                    }
                }

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") { vm.clearDay() }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if newTemplate {
                            saveExitAction()
                        } else {
                            if vm.hasUnsavedChanges {
                                askSave = true           // trigger alert
                            } else {
                                donePressed = true
                                dismiss.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .alert("Save Changes?", isPresented: $askSave) {
                Button("Discard", role: .destructive) {
                    vm.revertChanges()
                    donePressed = true
                    dismiss.wrappedValue.dismiss()
                }
                Button("Save") {
                    saveExitAction()
                }
            } message: {
                Text("Do you want to save your changes or discard them?")
            }
        }
    }
    
    func saveExitAction() {
        vm.saveIfNeeded(singleSave: onSave)
        donePressed = true
        dismiss.wrappedValue.dismiss()
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
            .foregroundColor(disabled
                             ? Color.white.opacity(0.5)
                             : Color.white)
            .disabled(disabled)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(disabled ? 0.6 : 1.0)
    }
}

