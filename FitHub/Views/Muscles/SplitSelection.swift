import SwiftUI

struct SplitSelection: View {
    @Environment(\.presentationMode) var dismiss
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
                // 1) Muscle-group grid
                ForEach(0..<3) { col in
                    HStack(spacing: 3) {
                        ForEach(SplitCategory.columnGroups[col], id: \.self) { cat in
                            let list = vm.binding(for: vm.selectedDay).wrappedValue
                            let selected = list.contains(cat)
                            let disabled = vm.shouldDisable(cat, on: vm.selectedDay)
                            
                            if vm.shouldShow(cat, in: list) {
                                Button(vm.displayName(for: cat, on: vm.selectedDay)) {
                                    vm.toggle(cat, on: vm.selectedDay)
                                }
                                .muscleButtonStyle(selected: selected, disabled: disabled)
                            }
                        }
                    }
                    .padding(.horizontal, -10)
                }

                // 2) Body overlay
                if let day = vm.selectedDay {
                    ZStack {
                        SimpleMuscleGroupsView(showFront: $vm.showFrontView, gender: userData.physical.gender, selectedSplit: vm.binding(for: day).wrappedValue)
                            .frame(height: 450)
                        
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
                }

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") { vm.clearDay(vm.selectedDay) }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if vm.hasUnsavedChanges {
                            askSave = true                  // show alert
                        } else {
                            donePressed = true
                            dismiss.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .alert("Save Changes?",isPresented: $askSave, actions: {
                 Button("Discard", role: .destructive) {
                     vm.revertChanges()
                     donePressed = true
                     dismiss.wrappedValue.dismiss()
                 }
                 Button("Save") {
                     vm.saveIfNeeded()
                     donePressed = true
                     dismiss.wrappedValue.dismiss()
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
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


