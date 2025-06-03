import SwiftUI

struct SplitSelection: View {
    @ObservedObject var userData: UserData
    @State private var selectedDay: daysOfWeek?
    @State private var muscleGroupSelections: [daysOfWeek: [SplitCategory]] = [:]
    @State private var originalSelections: [daysOfWeek: [SplitCategory]] = [:]
    @State private var donePressed: Bool = false
    @State private var showFrontView: Bool = true
    @State private var showSaveChangesAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var workoutDays: [daysOfWeek] {
        userData.customWorkoutDays ?? daysOfWeek.defaultDays(for: userData.workoutDaysPerWeek)
    }
    
    var workoutSplit: WorkoutWeek {
        userData.customWorkoutSplit ?? WorkoutWeek.createSplit(forDays: userData.workoutDaysPerWeek)
    }
    
    init(userData: UserData) {
        self.userData = userData
        _selectedDay = State(initialValue: workoutDays.first)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 3) {
                    
                    ForEach(0..<3) { column in
                        HStack(spacing: 6) {
                            ForEach(SplitCategory.columnGroups[column], id: \.self) { muscleGroup in
                                MuscleGroupButton(muscleGroup: muscleGroup, selectedDay: $selectedDay, selections: $muscleGroupSelections, disabled: shouldDisable(muscleGroup))
                            }
                        }
                    }
                }
                .padding(.horizontal, -10)
                
                Text("Select Categories for Day")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let selectedDay = selectedDay, let selectedMuscleGroups = muscleGroupSelections[selectedDay] {
                    GeometryReader { geometry in
                        ZStack {
                            SimpleMuscleGroupsView(selectedSplit: selectedMuscleGroups, showFront: $showFrontView)
                                .frame(width: geometry.size.width, height: 500)
                                .padding(.top, -25)
                                .centerHorizontally()
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showFrontView.toggle()
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
                    .frame(height: 450)
                }
                Spacer()
                
                Divider()
                
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack {
                        ForEach(workoutDays, id: \.self) { day in
                            Button(day.rawValue) {
                                withAnimation {
                                    selectedDay = day
                                }
                            }
                            .padding()
                            .frame(minWidth: 80)
                            .background(day == selectedDay ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Customize Split")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSelections()
            }
            .onDisappear {
                if !donePressed {
                    if originalSelections != muscleGroupSelections {
                        userData.customWorkoutSplit = createWorkoutSplitFromSelections()
                        userData.saveSingleVariableToFile(\.customWorkoutSplit, for: .customWorkoutSplit)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        clearSelections()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if originalSelections == muscleGroupSelections {
                            donePressed = true
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            showSaveChangesAlert = true
                        }
                    }
                }
            }
            .alert(isPresented: $showSaveChangesAlert) {
                Alert(
                    title: Text("Save Changes?"),
                    message: Text("Do you want to save your changes or discard them?"),
                    primaryButton: .destructive(Text("Discard")) {
                        muscleGroupSelections = originalSelections
                        donePressed = true
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .default(Text("Save")) {
                        userData.customWorkoutSplit = createWorkoutSplitFromSelections()
                        userData.saveSingleVariableToFile(\.customWorkoutSplit, for: .customWorkoutSplit)
                        donePressed = true
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func createWorkoutSplitFromSelections() -> WorkoutWeek {
        var categories = Array(repeating: [SplitCategory](), count: userData.workoutDaysPerWeek)
        
        for (index, day) in workoutDays.enumerated() {
            if index < userData.workoutDaysPerWeek {
                categories[index] = muscleGroupSelections[day] ?? []
            }
        }
        return WorkoutWeek(categories: categories)
    }
    
    private func loadSelections() {
        for (index, day) in workoutDays.enumerated() {
            if index < workoutSplit.categories.count {
                muscleGroupSelections[day] = workoutSplit.categories[index]
            }
        }
        // save the initial loaded selections
        originalSelections = muscleGroupSelections
    }
    
    private func clearSelections() {
        muscleGroupSelections.removeAll()
        for day in workoutDays {
            muscleGroupSelections[day] = []
        }
    }
    
    private func shouldDisable(_ category: SplitCategory) -> Bool {
        guard let day = selectedDay, let selectedCategories = muscleGroupSelections[day] else { return false }
        
        let legCategories: Set<SplitCategory> = [.quads, .glutes, .hamstrings, .calves]
        let selectedLegCategories = selectedCategories.filter { legCategories.contains($0) }
        
        if selectedCategories.contains(.all) && category != .all {
            return true
        }
        if selectedCategories.contains(.arms) && [.biceps, .triceps, .forearms].contains(category) {
            return true
        }
        // Disable all other leg categories if two are selected but allow the currently selected ones
        if selectedLegCategories.count > 1 && category.isLegCategory() && !selectedCategories.contains(category) {
            return true
        }
        
        return false
    }
    
    private func toggleSelection(for muscleGroup: SplitCategory, daySelections: Binding<[SplitCategory]>) {
        if daySelections.wrappedValue.contains(muscleGroup) {
            // When deselecting, check if it's 'Legs'
            if muscleGroup == .legs {
                // Remove all leg-related categories
                daySelections.wrappedValue.removeAll { $0.isLegCategory() }
                // Remove 'Legs'
                daySelections.wrappedValue.removeAll { $0 == muscleGroup }
            } else {
                // Remove just the specific muscle group
                daySelections.wrappedValue.removeAll { $0 == muscleGroup }
            }
        } else {
            // Adding selection logic
            daySelections.wrappedValue.append(muscleGroup)
        }
    }
    
    private func displayName(for category: SplitCategory, with selectedCategories: [SplitCategory]) -> String {
        if category == .legs {
            // Filter to identify if any specific leg categories are actively selected
            let focusCategories = selectedCategories.filter { $0.isLegCategory() }
            if focusCategories.isEmpty {
                // If no specific leg categories are selected, return "Legs"
                return "Legs"
            } else {
                // If specific leg categories are selected, show them as a focused label
                if selectedCategories.contains(.legs) {
                    return SplitCategory.concatenateCategories(for: selectedCategories)
                }
            }
        }
        return category.rawValue
    }
    
    @ViewBuilder
    private func MuscleGroupButton(muscleGroup: SplitCategory, selectedDay: Binding<daysOfWeek?>, selections: Binding<[daysOfWeek: [SplitCategory]]>, disabled: Bool) -> some View {
        if let day = selectedDay.wrappedValue {
            //var daySelections = selections.wrappedValue[day] ?? []
            let daySelections = Binding(
                get: { selections.wrappedValue[day] ?? [] },
                set: { selections.wrappedValue[day] = $0 }
            )
            let isLegFocused = daySelections.wrappedValue.contains(.legs) && muscleGroup.isLegCategory()
            let shouldShow = !(isLegFocused && daySelections.wrappedValue.contains(muscleGroup))
            
            if shouldShow {
                Button(action: {
                    toggleSelection(for: muscleGroup, daySelections: daySelections)
                }) {
                    Text(displayName(for: muscleGroup, with: daySelections.wrappedValue))
                        .padding(5)
                        .frame(minWidth: 50, minHeight: 35)
                        .minimumScaleFactor(0.5)
                        .background(disabled ? Color.gray : (daySelections.wrappedValue.contains(muscleGroup) ? Color.blue : Color.secondary))
                        .foregroundColor(disabled ? Color.white.opacity(0.5) : Color.white)
                        .cornerRadius(8)
                }
                .disabled(disabled)
            }
        }
    }
}
