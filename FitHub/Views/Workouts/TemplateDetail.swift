//
//  TemplateDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct TemplateDetail: View {
    @Binding var template: WorkoutTemplate
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var toastManager: ToastManager // Change this to EnvironmentObject
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @State private var showingExerciseSelection: Bool = false
    @State private var isKeyboardVisible: Bool = false // Track keyboard visibility
    @State private var showingSaveConfirmation: Bool = false
    @State private var pulsate: Bool = false
    @State private var isEditing = false // State to manage editing mode
    @State private var originalTemplate: WorkoutTemplate?
    @State private var undoStack: [WorkoutTemplate] = []
    @State private var redoStack: [WorkoutTemplate] = []
    @State private var removedSetDetailHistory: [[UUID: [SetDetail]]] = [] // History for undo
    @State private var restoredSetDetailHistory: [[UUID: [SetDetail]]] = [] // History for redo
    @State var isCollapsed: Bool = false // Control collapsed state
    @State private var exercisePendingDeletion: Exercise? = nil
    @State private var activeAlert: ActiveAlert? = nil
    var onDone: () -> Void
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all) // Ensures the background color covers the entire view
                .zIndex(0)  // Ensures the overlay is below all other content
            
            VStack {
                if isEditing {
                    editToolBar
                }
                
                if toastManager.showingSaveConfirmation {
                    saveConfirmationView
                        .zIndex(1)  // Ensures the overlay is above all other content
                }
                
                Spacer()
                
                if template.exercises.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach($template.exercises, id: \.id) { $exercise in
                            ExerciseSetDetail(
                                template: $template,
                                exercise: $exercise,
                                isCollapsed: $isCollapsed,
                                addSetAction: { captureSnapshot(); addNewSetToExercise(exercise) },
                                deleteSetAction: { captureSnapshot(); deleteSetFromExercise(exercise) },
                                onRemoveExercise: { exercise in
                                    confirmDeleteExercise(exercise)
                                },
                                captureSnap: { captureSnapshot() }
                            )
                            .listRowBackground(Color.clear) // Ensure list rows have a clear background
                            .listRowSeparator(.hidden)
                            .id(exercise.id)  // this is necessary to refresh the view smoothly when swapping exercises
                        }
                        .onDelete { offsets in captureSnapshot(); deleteExercise(at: offsets) }
                        .onMove { source, destination in captureSnapshot(); moveExercise(from: source, to: destination) }
                    }
                    .listStyle(PlainListStyle())
                    .scrollIndicators(.visible)
                }
            }
            .navigationBarItems(trailing: Button(isEditing ? "Close" : "Edit") {
                isEditing.toggle()
            })
            .sheet(isPresented: $showingExerciseSelection) {
                exerciseSelectionSheet
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .fill:
                    return Alert(
                        title: Text("Fill Template?"),
                        message: Text("This will require closing and reopening this template."),
                        primaryButton: .destructive(Text("Fill"), action: {
                            onDone() // Perform fill action here.
                        }),
                        secondaryButton: .cancel()
                    )
                case .delete:
                    return Alert(
                        title: Text("Are you sure you want to remove \(exercisePendingDeletion != nil ? "'"+exercisePendingDeletion!.name+"'" : "this exercise")?"),
                        message: Text("The exercise and its sets can be restored via: Edit → Undo"),
                        primaryButton: .destructive(Text("Remove"), action: {
                            if let exercise = exercisePendingDeletion {
                                removeExercise(exercise)
                                exercisePendingDeletion = nil
                            }
                        }),
                        secondaryButton: .cancel({
                            exercisePendingDeletion = nil
                        })
                    )
                }
            }
            .navigationTitle(template.name).navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear {
                removeKeyboardObservers()
                saveTemplate(displaySaveConfirm: false)
            }
        }
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .overlay(!isKeyboardVisible ? floatingActionButton : nil, alignment: .bottomTrailing)
    }
        
    enum ActiveAlert: Identifiable {
        case fill, delete

        var id: Int {
            hashValue
        }
    }
    
    private var editToolBar: some View {
        HStack {
            Button(action: {
                undoAction() // Handle undo action
            }) {
                HStack {
                    Text("Undo")
                        .font(.caption)
                    Image(systemName: "arrow.uturn.backward")
                        .imageScale(.large)
                }
                .padding(.leading, 15)
                .padding(.trailing)
                .foregroundColor(undoStack.isEmpty ? .gray : .blue) // Gray out if disabled
            }
            .disabled(undoStack.isEmpty)
            
            Button(action: {
                redoAction() // Handle redo action
            }) {
                HStack {
                    Image(systemName: "arrow.uturn.forward")
                        .imageScale(.large)
                    Text("Redo")
                        .font(.caption)
                }
                .foregroundColor(redoStack.isEmpty ? .gray : .blue) // Gray out if disabled
            }
            .disabled(redoStack.isEmpty)
            
            Spacer()
            Button(action: {
                //showFillMsg = true
                triggerFillAlert()
            }) {
                HStack {
                    Image(systemName: "doc.fill.badge.plus")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    
                }
            }.disabled(template.exercises.isEmpty)
            Spacer()
            
            Button(action: {
                saveTemplate(displaySaveConfirm: true)
            }) {
                HStack {
                    Text("Save")
                    Image(systemName: "tray.and.arrow.down") // Use this icon or choose another that suits your app's design
                        .imageScale(.large)
                }
                .padding(.trailing, 15)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .foregroundColor(.blue)
    }
    
    // When a deletion is attempted, set the pending exercise and show the confirmation alert.
    private func confirmDeleteExercise(_ exercise: Exercise) {
        exercisePendingDeletion = exercise
        activeAlert = .delete
    }
    
    private func triggerFillAlert() {
        activeAlert = .fill
    }
    
    private func captureSnapshot() {
        undoStack.append(template)
        redoStack.removeAll()  // Clear the redo stack whenever a new snapshot is captured
    }
    
    private func undoAction() {
        guard let lastUndo = undoStack.popLast() else { return }
        redoStack.append(template)  // Save the current state before applying the undo
        template = lastUndo  // Load the last template state from the undo stack
        
        // Restore deleted sets if applicable
        if let lastRemovedDetail = removedSetDetailHistory.popLast() {
            for (exerciseID, removedSets) in lastRemovedDetail {
                guard let exerciseIndex = template.exercises.firstIndex(where: { $0.id == exerciseID }) else { continue }
                for removedSet in removedSets {
                    template.exercises[exerciseIndex].setDetails.append(removedSet)
                    //template.exercises[exerciseIndex].sets += 1
                }
            }
        }
        saveTemplate(displaySaveConfirm: false)
    }
    
    private func redoAction() {
        guard let lastRedo = redoStack.popLast() else { return }
        undoStack.append(template)  // Save the current state before applying the redo
        template = lastRedo  // Load the template state from the redo stack
        
        // Reapply removed sets if applicable
        if let lastRestoredDetail = restoredSetDetailHistory.popLast() {
            for (exerciseID, restoredSets) in lastRestoredDetail {
                guard let exerciseIndex = template.exercises.firstIndex(where: { $0.id == exerciseID }) else { continue }
                for restoredSet in restoredSets {
                    template.exercises[exerciseIndex].setDetails.removeAll(where: { $0 == restoredSet })
                    //template.exercises[exerciseIndex].sets -= 1
                }
            }
        }
        saveTemplate(displaySaveConfirm: false)
    }
    
    private func restoreLastDeletedSet(for exercise: Exercise) {
        guard let exerciseIndex = template.exercises.firstIndex(where: { $0.id == exercise.id }),
              let lastRemovedDetail = removedSetDetailHistory.last,
              var removedSets = lastRemovedDetail[exercise.id],
              let lastRemovedSet = removedSets.popLast() else {
            return
        }
        // Restore the set
        template.exercises[exerciseIndex].setDetails.append(lastRemovedSet)
        //template.exercises[exerciseIndex].sets += 1
        
        // Update history
        removedSetDetailHistory[removedSetDetailHistory.count - 1][exercise.id] = removedSets
        if removedSets.isEmpty {
            removedSetDetailHistory[removedSetDetailHistory.count - 1].removeValue(forKey: exercise.id)
        }
        saveTemplate(displaySaveConfirm: false)
    }
    
    private func cleanUpResources() {
        // Clear the Pasteboard or any other resources
        UIPasteboard.general.items = []
        print("Pasteboard cleared")
        UIApplication.shared.perform(Selector(("_performMemoryWarning")))
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        template.exercises.move(fromOffsets: source, toOffset: destination)
        saveTemplate(displaySaveConfirm: false)
        isCollapsed = false
    }
    
    private var saveConfirmationView: some View {
        VStack {
            Text("Template Saved Successfully!")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .frame(width: 300, height: 100)
        .background(Color.clear)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale) // Smooth transition for showing/hiding
        .centerHorizontally()
    }
    
    private var floatingActionButton: some View {
        Button(action: {
            showingExerciseSelection = true
        }) {
            Image(systemName: "plus")
                .resizable()
                .frame(width: 24, height: 24)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 10)
                .padding()
        }
    }
    
    private var exerciseSelectionSheet: some View {
        ExerciseSelection(
            selectedExercises: template.exercises,
            templateCategories: template.categories,
            onDone: { finalSelection in
                // Remove exercises that were deselected
                for exercise in template.exercises {
                    if !finalSelection.contains(where: { $0.id == exercise.id }) {
                        removeExercise(exercise)
                    }
                }
                // Add new exercises that are in the final selection but not in the current template
                for exercise in finalSelection {
                    if !template.exercises.contains(where: { $0.id == exercise.id }) {
                        addExercise(exercise)
                        self.addNewSetToExercise(exercise)
                    }
                }
                // Update the template's exercises to the new ordered list
                template.exercises = finalSelection
                saveTemplate(displaySaveConfirm: false)
            }
        )
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func addNewSetToExercise(_ exercise: Exercise) {
        if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }) {
            let currentSets = template.exercises[index].sets
            let newSet = SetDetail(setNumber: currentSets + 1, weight: 0, reps: 0)
            template.exercises[index].setDetails.append(newSet)
            saveTemplate(displaySaveConfirm: false)
        }
    }
    
    private func deleteSetFromExercise(_ exercise: Exercise) {
        if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }) {
            guard !template.exercises[index].setDetails.isEmpty else { return }
            template.exercises[index].setDetails.removeLast()
            saveTemplate(displaySaveConfirm: false)
        }
    }
    
    private func addExercise(_ exercise: Exercise) {
        captureSnapshot() // Capture the state before adding
        template.exercises.append(exercise)
        //saveTemplate(displaySaveConfirm: false)
    }
    
    private func removeExercise(_ exercise: Exercise) {
        captureSnapshot() // Capture the state before adding
        if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }) {
            template.exercises.remove(at: index)
        }
        //saveTemplate(displaySaveConfirm: false)
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        template.exercises.remove(atOffsets: offsets)
        saveTemplate(displaySaveConfirm: false)
    }
    
    private func saveTemplate(displaySaveConfirm: Bool) {
        userData.saveTemplate(template: template)
        if displaySaveConfirm {
            toastManager.showSaveConfirmation()  // Trigger the notification
        }
    }
    
    private var emptyView: some View {
        VStack {
            Spacer()
            VStack {
                HStack(spacing: 5) {
                    Text("No exercises added")
                        .foregroundColor(colorScheme == .dark ? .white : .gray)
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)  // You can change the color to suit your design
                }
                Text("Press + to add an exercise to the workout.")
                    .padding()
                    .foregroundColor(.blue)
            }
            .onAppear { self.pulsate = true }
            .onDisappear { self.pulsate = false }
            .padding()
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15) // More rounded corners
            .shadow(radius: 10)
            .scaleEffect(pulsate ? 1.01 : 1.0)
            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulsate)
        Spacer()
        }
    }
}


