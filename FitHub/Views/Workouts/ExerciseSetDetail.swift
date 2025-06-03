//
//  ExerciseSetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ExerciseSetDetail: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    @EnvironmentObject var equipmentData: EquipmentData
    @EnvironmentObject var csvLoader: CSVLoader
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @Binding var template: WorkoutTemplate
    @Binding var exercise: Exercise
    @Binding var isCollapsed: Bool
    @State private var weightInputs: [String]
    @State private var repInputs: [String]
    @State private var showingAdjustmentsView: Bool = false
    @State private var selectedExercise: Exercise? // State to manage selected exercise for detail view
    @State private var isTapped: Bool = false
    @State private var refreshView = UUID()
    @State private var showDetailOptions: Bool = false
    @State private var showSupersetOptions: Bool = false // Control superset picker visibility
    @State private var replacedExercises: [String] = []
    @State private var showReplaceAlert: Bool = false
    var addSetAction: () -> Void
    var deleteSetAction: () -> Void
    var onRemoveExercise: (Exercise) -> Void
    var captureSnap: () -> Void
    
    init(template: Binding<WorkoutTemplate>, exercise: Binding<Exercise>, isCollapsed: Binding<Bool>, addSetAction: @escaping () -> Void, deleteSetAction: @escaping () -> Void, onRemoveExercise: @escaping (Exercise) -> Void, captureSnap: @escaping () -> Void) {
        _exercise = exercise
        _template = template
        _isCollapsed = isCollapsed
                
        _weightInputs = State(initialValue: exercise.wrappedValue.setDetails.map { $0.weight > 0 ? ($0.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0.weight) : String($0.weight)) : "" })
        _repInputs = State(initialValue: exercise.wrappedValue.setDetails.map { $0.reps > 0 ? String($0.reps) : "" })
        _showSupersetOptions = State(initialValue: exercise.wrappedValue.isSupersettedWith != nil)
        
        self.addSetAction = addSetAction
        self.deleteSetAction = deleteSetAction
        self.onRemoveExercise = onRemoveExercise
        self.captureSnap = captureSnap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Section {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(isTapped ? .secondary : .primary) // Change color on tap
                        .multilineTextAlignment(.center)
                        .padding(.trailing, -5)
                        .onTapGesture {
                            isTapped = true
                            selectedExercise = exercise
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isTapped = false
                            }
                        }
                    
                    Image(systemName: "info.circle")
                        .onTapGesture {
                            isTapped = true
                            selectedExercise = exercise
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isTapped = false
                            }
                        }
                }
                
                if !isCollapsed {
                    Image(systemName: showSupersetOptions ? "chevron.down" : "chevron.right")
                        .foregroundColor(.blue)
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        .onTapGesture {
                            showSupersetOptions.toggle()
                        }
                }
                
                Spacer()
                
                Section {
                    // only should be able to move by holding here
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                        .padding(.trailing)
                        .onTapGesture {
                            showDetailOptions.toggle()
                        }
                }
            }
            .padding(.vertical)
            
            // Conditionally show details if not collapsed
            if !isCollapsed {
                // Conditionally show the Superset Picker
                if showSupersetOptions  {
                    Picker("Superset With", selection: Binding(
                        get: {
                            // Ensure the selected value is valid, otherwise reset to "None"
                            if let supersetName = exercise.isSupersettedWith,
                               template.exercises.contains(where: { $0.name == supersetName && ($0.isSupersettedWith == nil || $0.isSupersettedWith == exercise.name) }) {
                                return supersetName
                            } else {
                                return "None"  // Reset to "None" if the current selection is invalid
                            }
                        },
                        set: { newValue in
                            // Call the function to handle superset logic
                            handleSupersetSelection(for: &exercise, with: newValue, in: &template)
                        }
                    )) {
                        Text("None").tag("None")
                        
                        // List exercises that are either not supersetted or supersetted with the current exercise
                        ForEach(template.exercises.filter { $0.name != exercise.name && ($0.isSupersettedWith == nil || $0.isSupersettedWith == exercise.name) }, id: \.id) { ex in
                            Text(ex.name).tag(ex.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.top, -15)
                }
                
                ForEach($exercise.setDetails.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                        Spacer()
                        
                        // ───────── Weight ───────────────────────────────────────────────
                        if exercise.usesWeight {
                            Text("lbs").bold()

                            TextField("Weight", text: Binding<String>(
                                get: { weightInputs.indices.contains(index) ? weightInputs[index] : "" },
                                set: { newValue in
                                    guard weightInputs.indices.contains(index) else { return }

                                    // keep only digits + dot
                                    let filtered = newValue.filter { "0123456789.".contains($0) }

                                    // allow up to 4 integer digits and up to 2 fractional digits
                                    let pattern = #"^(\d{0,4})(\.\d{0,2})?$"#
                                    guard filtered.range(of: pattern, options: .regularExpression) != nil else {
                                        return    // reject this keystroke
                                    }

                                    // apply it
                                    weightInputs[index] = filtered

                                    // update model
                                    if let w = Double(filtered) {
                                        exercise.setDetails[index].weight = w
                                    } else if filtered.isEmpty {
                                        exercise.setDetails[index].weight = 0
                                    }
                                }
                             ))
                             .keyboardType(.decimalPad)
                             .multilineTextAlignment(.center)
                             .textFieldStyle(RoundedBorderTextFieldStyle())
                             .frame(width: 80)
                       }

                        
                        // ───────── Reps ─────────────────────────────────────────────────
                        Text("Reps").bold()
                        
                        TextField("Reps", text: Binding<String>(
                            get: { repInputs.indices.contains(index) ? repInputs[index] : "" },
                            set: { newValue in
                                guard repInputs.indices.contains(index) else { return }
                                
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                
                                let capped = String(filtered.prefix(3))
                                repInputs[index] = capped              // UI text
                                
                                if let r = Int(filtered) {
                                    exercise.setDetails[index].reps = r
                                } else if filtered.isEmpty {
                                    exercise.setDetails[index].reps = 0
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    }
                }
                .onMove(perform: moveSet)
                .onDelete(perform: deleteSet)

                HStack {
                    Spacer()
                    Button(action: {
                        addSet()
                    }) {
                        Label("Add Set", systemImage: "plus")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button(action: {
                        deleteLastSet()
                    }) {
                        Label("Delete Set", systemImage: "minus")
                            .foregroundColor(.red)
                    }
                    .tint(.red)
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
                .padding(.top)
                
                if equipmentData.hasEquipmentAdjustments(for: exercise) {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAdjustmentsView.toggle()
                        }) {
                            Label("Equipment Adjustments", systemImage: "slider.horizontal.3")
                                .foregroundColor(.darkGreen)
                        }
                        .centerHorizontally()
                        .buttonStyle(.bordered)
                        .tint(.green)
                        
                        Spacer()
                    }
                    .padding(.top, -5)
                }
            }
        }
        .disabled(showDetailOptions)
        .overlay(
            Group {
                if showDetailOptions {
                    ZStack {
                        // Full-screen background that catches taps.
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    showDetailOptions = false
                                }
                            }
                        
                        // Container to position the overlay at top-trailing.
                        VStack {
                            HStack {
                                Spacer()  // Pushes content to the right.
                                ExerciseDetailOptions(
                                    template: $template,
                                    exercise: $exercise,
                                    roundingPreference: userData.roundingPreference,
                                    setStructure: userData.setStructure,
                                    onReplaceExercise: {
                                        self.showReplaceAlert = true
                                    },
                                    onRemoveExercise: { onRemoveExercise(exercise) },
                                    onClose: {
                                        self.showDetailOptions = false
                                    }
                                )
                                .onTapGesture { } // Consume taps.
                                .transition(.slide)
                            }
                            Spacer() // Pushes content to the top.
                        }
                       // .padding() // Optional: adjust padding as needed.
                    }
                }
            }
        )
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 2.5)
        .onChange(of: exercise.id) {
            // Reinitialize inputs when exercise changes
            reinitializeInputs()
            userData.saveTemplate(template: template) // this may be excessive
        }
        .onChange(of: exercise.isSupersettedWith) {
            if exercise.isSupersettedWith != nil {
                showSupersetOptions = true
            } else {
                showSupersetOptions = false
            }
        }
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exerciseData: exerciseData, exercise: exercise)
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(
                exerciseData: exerciseData,
                viewingDuringWorkout: true,
                exercise: exercise,
                onClose: {
                    self.selectedExercise = nil
                }
            )
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        }
        .alert(isPresented: $showReplaceAlert) {
            Alert(
                title: Text("Are you sure you want to replace this exercise?"),
                message: Text("This action can be undone via:\nEdit → Undo"),
                primaryButton: .destructive(Text("Replace"), action: {
                    replaceExercise()
                }),
                secondaryButton: .cancel()
            )
        }
        /*.onTapGesture {
            selectedExercise = nil
        }*/
    }

    func handleSupersetSelection(for exercise: inout Exercise, with newValue: String, in template: inout WorkoutTemplate) {
        captureSnap()
        // Step 1: Clear the reciprocal relationship of the previous superset, if it exists
        if let previousSupersetName = exercise.isSupersettedWith {
            if previousSupersetName != newValue {
                // Find the previous superset exercise by name and clear its relationship
                if let previousSupersetExerciseIndex = template.exercises.firstIndex(where: { $0.name == previousSupersetName }) {
                    template.exercises[previousSupersetExerciseIndex].isSupersettedWith = nil
                }
            }
        }
        if newValue == "None" {
            // Step 2: Remove the superset relationship from the current exercise
            exercise.isSupersettedWith = nil
            
            // Step 3: Find any exercise that was previously supersetted with this exercise and clear its relationship
            if let previouslySupersettedExerciseIndex = template.exercises.firstIndex(where: { $0.isSupersettedWith == exercise.name }) {
                template.exercises[previouslySupersettedExerciseIndex].isSupersettedWith = nil
            }
        } else {
            // Step 4: Set the current exercise to be supersetted with the selected exercise name
            exercise.isSupersettedWith = newValue
            
            // Step 5: Find the selected superset exercise and set its reciprocal relationship
            if let supersetExerciseIndex = template.exercises.firstIndex(where: { $0.name == newValue }) {
                template.exercises[supersetExerciseIndex].isSupersettedWith = exercise.name
            }
        }
    }

    private func cleanUpResources() {
        // Clean up any retained resources like clearing the Pasteboard
        UIPasteboard.general.items = []
        print("Pasteboard cleared")
        
        UIApplication.shared.perform(Selector(("_performMemoryWarning")))
    }
    
    private func reinitializeInputs() {
        // Reinitialize weight and rep inputs based on the new exercise data
        weightInputs = exercise.setDetails.map { $0.weight > 0 ? ($0.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0.weight) : String($0.weight)) : "" }
        repInputs = exercise.setDetails.map { $0.reps > 0 ? String($0.reps) : "" }
    }
    
    private func addSet() {
        weightInputs.append("")
        repInputs.append("")
        addSetAction()
    }
    
    private func deleteLastSet() {
        if !exercise.setDetails.isEmpty {
            weightInputs.removeLast()
            repInputs.removeLast()
            deleteSetAction()
        }
    }
    
    private func moveSet(from source: IndexSet, to destination: Int) {
        exercise.setDetails.move(fromOffsets: source, toOffset: destination)
        weightInputs.move(fromOffsets: source, toOffset: destination)
        repInputs.move(fromOffsets: source, toOffset: destination)
        userData.saveTemplate(template: template)
    }
    
    private func deleteSet(at offsets: IndexSet) {
        exercise.setDetails.remove(atOffsets: offsets)
        weightInputs.remove(atOffsets: offsets)
        repInputs.remove(atOffsets: offsets)
        userData.saveTemplate(template: template)
    }
    
    func replaceExercise() {
        if let exerciseIndex = template.exercises.firstIndex(where: { $0.name == exercise.name }) {
            let currentExercise = template.exercises[exerciseIndex]
            let similarExercises = findSimilarExercises(to: currentExercise, in: exerciseData.allExercises, userData: userData, existingExercises: template.exercises, replacedExercises: replacedExercises)
            if let newExercise = similarExercises.first, newExercise.name != currentExercise.name {
                let repsAndSets = RepsAndSets.determineRepsAndSets(customRestPeriod: userData.customRestPeriod, goal: userData.goal, customRepsRange: userData.customRepsRange, customSets: userData.customSets)
                
                let detailedExercise = userData.calculateDetailedExercise(exercise: newExercise, repsAndSets: repsAndSets, exerciseData: exerciseData, csvLoader: csvLoader, equipmentData: equipmentData, nextWeek: false)
                
                template.exercises[exerciseIndex] = detailedExercise
                replacedExercises.append(currentExercise.name) // Add replaced exercise to the list
                print("Appended \(currentExercise.name) to replacedExercises: \(replacedExercises)")
                print("Updated replacedExercises array: \(replacedExercises)")
                userData.saveTemplate(template: template)
                //alertMessage = "Replaced '\(currentExercise.name)' with '\(newExercise.name)' in \(template.name)."
            } else {
                //alertMessage = "No similar exercise found to replace '\(currentExercise.name)'"
            }
        }
    }
}

