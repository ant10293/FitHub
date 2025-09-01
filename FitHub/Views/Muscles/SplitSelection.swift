import SwiftUI

struct SplitSelection: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: SplitSelectionVM
    @State private var donePressed: Bool = false
    @State private var askSave: Bool = false
    let userData: UserData

    init(userData: UserData) {
        _vm = StateObject(wrappedValue: SplitSelectionVM(userData: userData))
        self.userData = userData
    }

    var body: some View {
        NavigationStack {
            VStack {
                //  replace the whole “Muscle‑group grid + overlay” block
                MuscleSelection(
                    selectedCategories: vm.binding(for: vm.selectedDay),
                    showFront:          $vm.showFrontView,
                    gender:             userData.physical.gender,
                    displayName:        { vm.displayName(for: $0, on: vm.selectedDay) },
                    toggle:             { vm.toggle($0, on: vm.selectedDay) },
                    shouldDisable:      { vm.shouldDisable($0, on: vm.selectedDay) },
                    shouldShow:         { cat, list in vm.shouldShow(cat, in: list) }
                )
                .frame(maxHeight: .infinity)          // keeps existing layout

                // 3) Day selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(vm.workoutDays, id: \.self) { day in
                            Button(day.rawValue) {
                                vm.selectedDay = day
                            }
                            .DayButtonStyle(selected: vm.selectedDay == day)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarTitle("Customize Split", displayMode: .inline)
            .onDisappear { if !donePressed { vm.saveIfNeeded() } }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear All") { vm.clearDay(vm.selectedDay) }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if vm.hasUnsavedChanges {
                            askSave = true                  // show alert
                        } else {
                            donePressed = true
                            dismiss()
                        }
                    }
                }
            }
            .alert("Save Changes?",isPresented: $askSave, actions: {
                 Button("Discard", role: .destructive) {
                     vm.revertChanges()
                     donePressed = true
                     dismiss()
                 }
                 Button("Save") {
                     vm.saveIfNeeded()
                     donePressed = true
                     dismiss()
                 }
             },
             message: { Text("Do you want to save your changes or discard them?") })
        }
    }
}


extension View {
    /// Applies the “pill” look you’ve been using for muscle-group buttons.
    func DayButtonStyle(selected: Bool) -> some View {
        self
            .padding()
            .frame(minWidth: 80)
            .background(selected ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


