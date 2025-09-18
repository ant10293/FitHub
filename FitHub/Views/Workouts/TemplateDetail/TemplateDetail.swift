//
//  TemplateDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct TemplateDetail: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @Binding var template: WorkoutTemplate
    @StateObject private var kbd = KeyboardManager.shared
    @State private var showingExerciseSelection: Bool = false
    @State private var showingAdjustmentsView: Bool = false
    @State private var showingDetailView: Bool = false
    @State private var pulsate: Bool = false
    @State private var isEditing: Bool = false // State to manage editing mode
    @State var isCollapsed: Bool = false // Control collapsed state
    @State private var originalTemplate: WorkoutTemplate?
    @State private var undoStack: [WorkoutTemplate] = []
    @State private var redoStack: [WorkoutTemplate] = []
    @State private var replacedExercises: [String] = []
    @State private var exercisePendingDeletion: Exercise? = nil
    @State private var activeAlert: ActiveAlert? = nil
    @State private var selectedExercise: Exercise? // State to manage selected exercise for detail view
    @State private var activeDetailID: UUID? = nil   // nil = no menu open
    @State private var isReplacing: Bool = false
    @State private var replaceMessage: String = ""
    private let modifier = ExerciseModifier()
    var isArchived: Bool = false
    var onDone: () -> Void
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all) // Ensures the background color covers the entire view
                .zIndex(0)  // Ensures the overlay is below all other content
            
            VStack {
                if isEditing { editToolBar }
                if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Template Saved Successfully!").zIndex(1) }
                
                Spacer()
                
                if isArchived {
                    Label("Editing Locked for Archived Templates", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)           // keeps icon + text red (like your original)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .symbolVariant(.fill)            // ensures filled triangle
                        .imageScale(.medium)
                }
                
                if !template.exercises.isEmpty {
                    setDetailList
                }
            }
        }
        .generatingOverlay(isReplacing, message: "Replacing Exercise...")
        .overlay(alignment: .center, content: { template.exercises.isEmpty ? emptyView() : nil })
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .overlay(!kbd.isVisible ?
             FloatingButton(
                image: "plus",
                disabled: isArchived,
                action: { showingExerciseSelection = true }
             ) : nil, alignment: .bottomTrailing
        )
        .navigationBarItems(trailing: Button(isEditing ? "Close" : "Edit") { isEditing.toggle() }.disabled(isArchived))
        .sheet(isPresented: $showingExerciseSelection) { exerciseSelectionSheet }
        .sheet(item: $selectedExercise, onDismiss: { handleSheetDismiss() }) { exercise in
            if showingDetailView {
                ExerciseDetailView(viewingDuringWorkout: true, exercise: exercise)
            } else if showingAdjustmentsView {
                AdjustmentsView(exercise: exercise)
            }
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .fill:
                return Alert(
                    title: Text("Fill Template?"),
                    message: Text("This will require closing and reopening this template."),
                    primaryButton: .destructive(Text("Fill"), action: { onDone() }),
                    secondaryButton: .cancel()
                )
            case .delete:
                return Alert(
                    title: Text("Are you sure you want to remove '\(exercisePendingDeletion?.name ?? "this exercise")'?"),
                    message: Text("The exercise and its sets can be restored via: Edit → Undo"),
                    primaryButton: .destructive(Text("Remove"), action: {
                        if let exercise = exercisePendingDeletion {
                            removeExercise(exercise)
                            exercisePendingDeletion = nil
                        }
                    }),
                    secondaryButton: .cancel({ exercisePendingDeletion = nil })
                )
            case .replace:
                return Alert(title: Text("Template Update"), message: Text(replaceMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationBarTitle(template.name, displayMode: .inline)
        .onDisappear { if !isArchived { saveTemplate() } }
    }
    
    private var setDetailList: some View {
        List {
            ForEach($template.exercises, id: \.id) { $exercise in
                ExerciseSetDetail(
                    template: $template,
                    exercise: $exercise,
                    isCollapsed: $isCollapsed,
                    isShowingOptions: Binding(
                        get: { activeDetailID == exercise.id },
                        set: { newVal in activeDetailID = newVal ? exercise.id : nil }
                    ),
                    hasEquipmentAdjustments: ctx.equipment.hasEquipmentAdjustments(for: exercise),
                    perform: { action in
                        performCallBackAction(action: action, exercise: $exercise)
                    },
                    onSuperSet: { ssIdString in
                        captureSnapshot()
                        modifier.handleSupersetSelection(for: &exercise, with: ssIdString, in: &template)
                    },
                )
                .listRowBackground(Color.clear) // Ensure list rows have a clear background
                .listRowSeparator(.hidden)
                .id(exercise.id)  // this is necessary to refresh the view smoothly when swapping exercises
                .disabled(isArchived)
            }
            .onDelete { offsets in captureSnapshot(); deleteExercise(at: offsets) }
            .onMove { source, destination in captureSnapshot(); moveExercise(from: source, to: destination) }
            
            // Spacer row at the end
            Color.clear
                .frame(height: 50)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
        .scrollIndicators(.visible)
    }
            
    private var editToolBar: some View {
        HStack {
            Button(action: { undoAction() }) {
                HStack {
                    Text("Undo").font(.caption)
                    Image(systemName: "arrow.uturn.backward").imageScale(.large)
                }
                .padding(.leading, 15)
                .padding(.trailing)
                .foregroundStyle(undoStack.isEmpty ? .gray : .blue) // Gray out if disabled
            }
            .disabled(undoStack.isEmpty)
            
            Button(action: { redoAction() }) {
                HStack {
                    Image(systemName: "arrow.uturn.forward").imageScale(.large)
                    Text("Redo").font(.caption)
                }.foregroundStyle(redoStack.isEmpty ? .gray : .blue) // Gray out if disabled
            }
            .disabled(redoStack.isEmpty)
            
            Spacer()
            Button(action: { triggerFillAlert() }) {
                HStack {
                    Image(systemName: "doc.fill.badge.plus").imageScale(.medium)
                }.foregroundStyle(template.exercises.isEmpty ? .gray : .blue) // Gray out if disabled
            }
            .disabled(template.exercises.isEmpty)
            Spacer()
            
            Button(action: { saveTemplate(displaySaveConfirm: true) }) {
                HStack {
                    Text("Save")
                    Image(systemName: "tray.and.arrow.down").imageScale(.large)
                }.padding(.trailing, 15)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var exerciseSelectionSheet: some View {
        ExerciseSelection(
            selectedExercises: template.exercises,
            templateCategories: template.categories,
            onDone: { finalSelection in
                // Step 1: Constant-time membership tables
                let currentIDs = Set(template.exercises.map(\.id))
                let finalIDs = Set(finalSelection.map(\.id))

                // Step 2: Remove anything that disappeared
                template.exercises.filter { !finalIDs.contains($0.id) }.forEach(removeExercise)

                // Step 3: Add the new ones
                finalSelection.filter { !currentIDs.contains($0.id) }.forEach(addExercise)

                // Step 4: Keep the caller’s order & persist once
                // Reorder exercises to match finalSelection order (but keep modified content)
                let orderedExercises = finalSelection.compactMap { finalEx in
                    template.exercises.first { $0.id == finalEx.id }
                }
                
                template.exercises = orderedExercises
                saveTemplate()
            }
        )
    }
    
    @ViewBuilder
    private func emptyView() -> some View {
        VStack {
            HStack(spacing: 5) {
                Text("No exercises added")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .gray)
                Image(systemName: "exclamationmark.circle").foregroundStyle(.red)
            }
            Text("Press + to add an exercise to the workout.").foregroundStyle(.blue).padding()
        }
        .onAppear { self.pulsate = true }
        .onDisappear { self.pulsate = false }
        .padding()
        .padding(.horizontal)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 10)
        .scaleEffect(pulsate ? 1.05 : 1.0)
        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulsate)
    }
    
    private enum ActiveAlert: Identifiable { case fill, delete, replace; var id: Int { hashValue } }
    private func triggerFillAlert() { activeAlert = .fill }
    
    private func performCallBackAction(action: CallBackAction, exercise: Binding<Exercise>) {
        switch action {
        case .addSet: captureSnapshot(); modifier.addNewSet(exercise.wrappedValue, from: &template, user: ctx.userData)
        case .deleteSet: captureSnapshot(); modifier.deleteSet(exercise.wrappedValue, from: &template, user: ctx.userData)
        case .removeExercise: confirmDeleteExercise(exercise.wrappedValue)
        case .replaceExercise: replaceExercise(exercise.wrappedValue)
        case .viewAdjustments: showingAdjustmentsView = true; selectedExercise = exercise.wrappedValue
        case .viewDetail: showingDetailView = true; selectedExercise = exercise.wrappedValue
        case .saveTemplate: saveTemplate()
        }
    }
    
    private func handleSheetDismiss() {
        showingDetailView ? showingDetailView = false : (showingAdjustmentsView ? showingAdjustmentsView = false : nil)
        selectedExercise = nil
    }
    
    // When a deletion is attempted, set the pending exercise and show the confirmation alert.
    private func confirmDeleteExercise(_ exercise: Exercise) {
        exercisePendingDeletion = exercise
        activeAlert = .delete
    }
        
    private func captureSnapshot() {
        undoStack.append(template)
        redoStack.removeAll()  // Clear the redo stack whenever a new snapshot is captured
    }
    
    private func undoAction() {
        guard let lastUndo = undoStack.popLast() else { return }
        redoStack.append(template)  // Save the current state before applying the undo
        template = lastUndo  // Load the last template state from the undo stack
        saveTemplate()
    }
    
    private func redoAction() {
        guard let lastRedo = redoStack.popLast() else { return }
        undoStack.append(template)  // Save the current state before applying the redo
        template = lastRedo  // Load the template state from the redo stack
        saveTemplate()
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        template.exercises.move(fromOffsets: source, toOffset: destination)
        saveTemplate()
        isCollapsed = false
    }
    
    private func replaceExercise(_ exercise: Exercise) {
        captureSnapshot() // only capture if changes will be made
        isReplacing = true
        let oldName = exercise.name
        modifier.replaceInBackground(
            target: exercise,
            template: template,
            exerciseData: ctx.exercises,
            equipmentData: ctx.equipment,
            userData: ctx.userData,
            replaced: replacedExercises,
            onComplete: { result in
                if let newExercise = result.newExercise {
                    // only update when necessary
                    template = result.updatedTemplate
                    replacedExercises = result.updatedReplaced
                    replaceMessage = "Replaced '\(oldName)' with '\(newExercise.name)'.\nThis action can be undone via: Edit → Undo"
                } else {
                    replaceMessage = "No similar exercise found to replace '\(oldName)'."
                }
                activeAlert = .replace
                isReplacing = false
            }
        )
    }
    
    private func addExercise(_ exercise: Exercise) {
        captureSnapshot() // Capture the state before adding
        var exercise = exercise
        exercise.setDetails.append(SetDetail(setNumber: 1, weight: Mass(kg: 0), planned: exercise.getPlannedMetric(value: 0)))
        template.exercises.append(exercise)
    }
    
    private func removeExercise(_ exercise: Exercise) {
        captureSnapshot() // Capture the state before removing
        _ = modifier.remove(exercise, from: &template, user: ctx.userData)
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        for index in offsets {
            _ = modifier.remove(template.exercises[index], from: &template, user: ctx.userData)
        }
    }
    
    private func saveTemplate(displaySaveConfirm: Bool = false) {
        ctx.userData.saveSingleStructToFile(\.workoutPlans, for: .workoutPlans) // no need for userData.updateTemplate since we use $binding
        if displaySaveConfirm { ctx.toast.showSaveConfirmation() }
    }
}


