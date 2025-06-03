//
//  WorkoutGeneration.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/13/24.
//

import SwiftUI


struct WorkoutGeneration: View {
    @ObservedObject var userData: UserData
    @ObservedObject var exerciseData: ExerciseData
    @ObservedObject var equipmentData: EquipmentData
    @ObservedObject var csvLoader: CSVLoader
    @State private var showingSaveConfirmation = false
    @State private var showingDayPicker = false
    @State private var showingSplitSelection = false
    @State private var showingCustomizationForm = false
    @State private var numberOfWorkoutDaysPerWeek: Int = 0
    @State private var selectedDays: [daysOfWeek] = []
    @State private var numberOfSets: Int = 0
    @State private var midpointReps: Int = 0
    @State private var rangeWidth: Int = 0
    @State private var keepCurrentExercises: Bool = false
    @State private var selectedExerciseType: ExerciseType = .default
    @State private var savedPressed: Bool = false
    @State private var showingResetAlert = false // State variable for showing the post-reset alert
    @State private var showingMuscleGroupView = false // State variable for showing the post-reset alert
    @State var showFront: Bool = true
    @State private var currentTemplateIndex = 0
    @State private var showingExerciseOptions: Bool = false
    @State private var selectedExercise: Exercise?
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var replacedExercises: [String] = [] // Define replacedExercises here
    @State private var showingTemplateDetail: Bool = false // New state variable to control the navigation to TemplateDetailView
    @State private var selectedSetStructure: SetStructures = .pyramid
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    
    init(userData: UserData, exerciseData: ExerciseData, equipmentData: EquipmentData, csvLoader: CSVLoader) {
        self.userData = userData
        self.exerciseData = exerciseData
        self.equipmentData = equipmentData
        self.csvLoader = csvLoader
        
        let currentRepsAndSets = FitnessGoal.getRepsAndSets(for: userData.goal, restPeriod: userData.customRestPeriod ?? FitnessGoal.determineRestPeriod(for: userData.goal))
        
        let sets = userData.customSets ?? currentRepsAndSets.sets
        let customRepsRange = userData.customRepsRange ?? currentRepsAndSets.repsRange
        let midpoint = customRepsRange.lowerBound
        let width = customRepsRange.upperBound - customRepsRange.lowerBound
        
        _numberOfWorkoutDaysPerWeek = State(initialValue: userData.workoutDaysPerWeek)
        _selectedDays = State(initialValue: userData.customWorkoutDays ?? daysOfWeek.defaultDays(for: userData.workoutDaysPerWeek))
        _numberOfSets = State(initialValue: sets)
        _midpointReps = State(initialValue: midpoint)
        _rangeWidth = State(initialValue: width)
        _keepCurrentExercises = State(initialValue: userData.keepCurrentExercises)
        _selectedExerciseType = State(initialValue: userData.exerciseType)
        _selectedSetStructure = State(initialValue: userData.setStructure)
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all) //
            
            VStack {
                if showingSaveConfirmation {
                    saveConfirmationView
                        .zIndex(1)  // Ensures the overlay is above all other content
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: previousTemplate) {
                            Image(systemName: "arrow.left").bold()
                                .contentShape(Rectangle())
                                .disabled(showingExerciseOptions)
                        }
                        
                        HStack {
                            VStack {
                                Text(userData.trainerTemplates[safe: currentTemplateIndex]?.name ?? "No Template")
                                    .font(.headline)
                                    .padding()
                                    .padding(.bottom, 1) // Reduce bottom padding
                                
                                
                                if let categories = userData.trainerTemplates[safe: currentTemplateIndex]?.categories {
                                    Text(SplitCategory.concatenateCategories(for: categories))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .zIndex(1)  // Ensures is above all other content
                                        .padding(.top, -25) // Reduce space above the list
                                }
                            }
                            
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.blue)
                                .padding(.leading, -5)
                            
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingTemplateDetail = true
                        }
                        .frame(alignment: .center)
                        .padding(.horizontal)
                        
                        Button(action: nextTemplate) {
                            Image(systemName: "arrow.right").bold()
                                .contentShape(Rectangle())
                                .disabled(showingExerciseOptions)
                        }
                        Spacer()
                    }
                    
                    List {
                        if let template = userData.trainerTemplates[safe: currentTemplateIndex] {
                            ForEach(template.exercises, id: \.id) { exercise in
                                HStack {
                                    Image(exercise.fullImagePath) // Assuming your Exercise model has an image property
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 6)) // Apply rounded rectangle shape
                                    
                                    VStack(alignment: .leading) {
                                        Text(exercise.name)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(subtitle(for: exercise))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        selectedExercise = exercise
                                        showingExerciseOptions = true
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .frame(width: 30, height: 30)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .disabled(showingExerciseOptions)
                    .padding(.top, -15) // Reduce space above the list
                }
                .padding(.horizontal)
                
                Button("Modify Workout Generation") {
                    showingCustomizationForm = true
                }
                .disabled(showingExerciseOptions)
                .font(.subheadline)
                .padding()
                
                Button("Generate Workout Plan") {
                    print("keepCurrentExercises: \(userData.keepCurrentExercises)")
                    userData.generateWorkoutPlan(exerciseData: exerciseData, equipmentData: equipmentData, csvLoader: csvLoader, keepCurrentExercises: keepCurrentExercises, selectedExerciseType: selectedExerciseType, nextWeek: false)
                    showingSaveConfirmation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingSaveConfirmation = false
                    }
                }
                .disabled(showingExerciseOptions)
                .foregroundColor(.white)
                .padding()
                .background(!showingExerciseOptions ? Color.blue : Color.gray)
                .cornerRadius(10)
                .clipShape(Rectangle())
                
                if let creationDate = userData.workoutsCreationDate {
                    Text("Last Generated on: \(formatDate(creationDate))")
                        .font(.caption)
                        .padding(.vertical)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
        }
        .navigationTitle("Workout Generation").navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingTemplateDetail) {
            if let template = $userData.trainerTemplates[safe: currentTemplateIndex] {
                TemplateDetail(template: template, onDone: {
                    self.showingTemplateDetail = false
                })
            }
        }
        .navigationDestination(isPresented: $showingCustomizationForm) {
            customizationForm
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Template updated"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .overlay(
            Group {
                if showingExerciseOptions,
                   let exercise = selectedExercise {
                    ExerciseOptionsView(
                        exercise: exercise,
                        template: userData.trainerTemplates[currentTemplateIndex],
                        exerciseData: exerciseData,
                        userData: userData,
                        onClose: {
                            showingExerciseOptions = false
                        },
                        showAlert: $showAlert,
                        alertMessage: $alertMessage,
                        replacedExercises: $replacedExercises // Pass replacedExercises as a Binding
                    )
                }
            }
        )
    }
    
    private func subtitle(for exercise: Exercise) -> String {
        let repRange = getRepRange(for: exercise)
        return "Sets: \(exercise.sets), Reps: \(repRange)"
    }
    
    private func getRepRange(for exercise: Exercise) -> String {
        let reps = exercise.setDetails.compactMap { $0.reps }
        guard let minReps = reps.min(), let maxReps = reps.max() else {
            return "0-0"
        }
        return "\(minReps)-\(maxReps)"
    }
    
    private func previousTemplate() {
        if currentTemplateIndex > 0 {
            currentTemplateIndex -= 1
        } else {
            currentTemplateIndex = userData.trainerTemplates.count - 1
        }
    }
    
    // Navigate to the next template
    private func nextTemplate() {
        if currentTemplateIndex < (userData.trainerTemplates.count - 1) {
            currentTemplateIndex += 1
        } else {
            currentTemplateIndex = 0
        }
    }
    
    private var customizationForm: some View {
        VStack {
            Spacer()
            Form {
                Section(header: Text("Customize Your Workout Plan")) {
                    Picker("Workout Days per Week", selection: $numberOfWorkoutDaysPerWeek) {
                        ForEach(3...6, id: \.self) {
                            Text("\($0) days")
                        }
                    }
                    .onChange(of: numberOfWorkoutDaysPerWeek) { oldValue, newValue in
                        if oldValue != newValue {
                            userData.workoutDaysPerWeek = newValue
                            userData.saveSingleVariableToFile(\.workoutDaysPerWeek, for: .workoutDaysPerWeek)
                            let defaultDays = daysOfWeek.defaultDays(for: userData.workoutDaysPerWeek)
                            selectedDays = defaultDays
                        }
                    }
                    
                    Stepper("Number of Sets: \(numberOfSets)", value: $numberOfSets, in: 1...10)
                        .onChange(of: numberOfSets) { oldValue, newValue in
                            if oldValue != newValue {
                                userData.customSets = newValue
                                userData.saveSingleVariableToFile(\.customSets, for: .customSets)
                            }
                        }
                    
                    HStack {
                        Text("Rep Range: \(midpointReps)-\(midpointReps + rangeWidth)")
                        Slider(value: Binding(
                            get: { Double(midpointReps) },
                            set: { newValue in
                                midpointReps = Int(newValue)
                            }
                        ), in: 1...20, step: 1)
                    }
                    .onChange(of: midpointReps) { oldValue, newValue in
                        if oldValue != newValue {
                            userData.customRepsRange = (midpointReps)...(midpointReps+rangeWidth)
                            userData.saveSingleVariableToFile(\.customRepsRange, for: .customRepsRange)
                        }
                    }
                    
                    Stepper("Range Width: \(rangeWidth)", value: $rangeWidth, in: 1...9)
                        .onChange(of: rangeWidth) { oldValue, newValue in
                            if oldValue != newValue {
                                userData.customRepsRange = (midpointReps)...(midpointReps+rangeWidth)
                                userData.saveSingleVariableToFile(\.customRepsRange, for: .customRepsRange)
                            }
                        }
                    
                    VStack {
                        Picker("Set-weight Structure", selection: $selectedSetStructure) {
                            ForEach(SetStructures.allCases, id: \.self) { structure in
                                Text(structure.rawValue)
                            }
                        }
                        Text(selectedSetStructure.desc)
                            .font(.caption)
                            .frame(alignment: .leading)
                    }
                    .onChange(of: selectedSetStructure) { oldValue, newValue in
                        if oldValue != newValue {
                            userData.setStructure = newValue
                            userData.saveSingleVariableToFile(\.setStructure, for: .setStructure)
                        }
                    }
                    
                    Toggle("Keep current Exercises", isOn: $keepCurrentExercises) // Add this line
                        .onChange(of: keepCurrentExercises) { oldValue, newValue in
                            userData.keepCurrentExercises = newValue
                            userData.saveSingleVariableToFile(\.keepCurrentExercises, for: .keepCurrentExercises)
                        }
                    
                    // Replace the toggle for bodyweight exercises with this picker
                    Picker("Exercise Type", selection: $selectedExerciseType) {
                        ForEach(ExerciseType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: selectedExerciseType) { oldValue, newValue in
                        if oldValue != newValue {
                            userData.exerciseType = newValue
                            userData.saveSingleVariableToFile(\.exerciseType, for: .exerciseType)
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Button(action: {
                            showingSplitSelection = true
                        }) {
                            HStack {
                                Text("Customize Split")
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .sheet(isPresented: $showingSplitSelection) {
                            SplitSelection(userData: userData)
                        }
                    }
                    .onChange(of: selectedDays) { oldValue, newValue in
                        if oldValue != newValue {
                            if !newValue.isEmpty {
                                userData.customWorkoutDays = newValue
                            } else {
                                userData.customWorkoutDays = nil
                            }
                            userData.saveSingleVariableToFile(\.customWorkoutDays, for: .customWorkoutDays)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Button(action: {
                            showingDayPicker = true
                        }) {
                            HStack {
                                Text("Select Workout Days")
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .sheet(isPresented: $showingDayPicker) {
                            DayPickerView(selectedDays: $selectedDays, numDays: $numberOfWorkoutDaysPerWeek)
                        }
                        
                        HStack(spacing: 0) {
                            ForEach(Array(selectedDays.sorted().enumerated()), id: \.element) { index, day in
                                Text(day.shortName)
                                    .tag(day)
                                    .bold()
                                
                                if index < selectedDays.count - 1 {
                                    Text(", ") // Adds a comma after each day except the last one
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Section {
                    Button("Reset to Defaults") {
                        resetToDefaults() // Reset immediately when button is pressed
                    }
                    .foregroundColor(.red)
                    .alert("Customization Reset", isPresented: $showingResetAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("All settings have been reset to their default values.")
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func resetToDefaults() {
        let currentRepsAndSets = FitnessGoal.getRepsAndSets(for: userData.goal, restPeriod: userData.customRestPeriod ?? FitnessGoal.determineRestPeriod(for: userData.goal))
        numberOfSets = currentRepsAndSets.sets
        midpointReps = (currentRepsAndSets.repsRange.lowerBound + currentRepsAndSets.repsRange.upperBound) / 2
        let defaultDays = daysOfWeek.defaultDays(for: userData.workoutDaysPerWeek) 
        selectedDays = defaultDays
        keepCurrentExercises = false
        selectedExerciseType = .default
        
        let customRepsRange = currentRepsAndSets.repsRange
        midpointReps = customRepsRange.lowerBound
        rangeWidth = customRepsRange.upperBound - customRepsRange.lowerBound
        
        userData.customRepsRange = nil
        userData.customSets = nil
        userData.keepCurrentExercises = false
        userData.exerciseType = .default
        userData.customWorkoutSplit = nil
        userData.setStructure = .pyramid
        
        userData.saveToFile()
        showingResetAlert = true
    }
    
    private var saveConfirmationView: some View {
        VStack {
            Text("Workout Plan Generated!")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .frame(width: 300, height: 150)
        .background(Color.clear)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale)
    }
}


struct ExerciseOptionsView: View {
    var exercise: Exercise
    var template: WorkoutTemplate
    @ObservedObject var exerciseData: ExerciseData
    @ObservedObject var userData: UserData
    @EnvironmentObject var csvLoader: CSVLoader
    @EnvironmentObject var equipmentData: EquipmentData
    var onClose: () -> Void
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @Binding var replacedExercises: [String] // Binding to the array in the parent view
    @State private var showSimilarExercises = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(exercise.name)")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Button(action: {
                    toggleFavorite(for: exercise)
                }) {
                    HStack {
                        Image(systemName: userData.favoriteExercises.contains(exercise.name) ? "star.fill" : "star")
                        Text("Favorite Exercise")
                            .font(.headline)
                    }
                }
                .padding(.vertical, -5)
                Text("Select this exercise as a favorite to ensure that it will be included in future generated workouts.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                Button(action: {
                    toggleDislike(for: exercise)
                }) {
                    HStack {
                        Image(systemName: userData.dislikedExercises.contains(exercise.name) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        Text("Dislike Exercise")
                            .font(.headline)
                    }
                }
                .padding(.vertical, -5)
                Text("Disliking this exercise will ensure that it will not be included in future generated workouts.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                // add an alert when replacing or deleting exercises
                // if exercise is not disliked, provide a prompt to dislike the exercise
                Button(action: {
                    replaceExercise()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Replace Exercise")
                            .font(.headline)
                    }
                }
                .padding(.vertical, -5)
                Text("Replace '\(exercise.name)' with a similar exercise that works the same muscles.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                Button(action: {
                    showSimilarExercises = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Find Replacement")
                            .font(.headline)
                    }
                }
                .padding(.vertical, -5)
                Text("Find a replacement exercise by viewing similar exercises that work the same muscles.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                Button(action: {
                    removeExercise()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove Exercise")
                            .font(.headline)
                    }
                }
                .padding(.vertical, -5)
                Text("Remove '\(exercise.name)' from this template.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 300)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 10)
        .navigationDestination(isPresented: $showSimilarExercises) {
            SimilarExercisesView(currentExercise: exercise, allExercises: exerciseData.allExercises, template: template) { replacedExercise in
                // Handle the replacement logic here
                replaceSpecificExercise(with: replacedExercise)
            }
        }
    }
    
    private func toggleDislike(for exercise: Exercise) {
        if let index = userData.dislikedExercises.firstIndex(of: exercise.name) {
            userData.dislikedExercises.remove(at: index)
        } else {
            // Remove from favorites if present
            if let favoriteIndex = userData.favoriteExercises.firstIndex(of: exercise.name) {
                userData.favoriteExercises.remove(at: favoriteIndex)
                userData.saveSingleVariableToFile(\.favoriteExercises, for: .favoriteExercises)
                
            }
            userData.dislikedExercises.append(exercise.name)
            userData.saveSingleVariableToFile(\.dislikedExercises, for: .dislikedExercises)
        }
    }
    
    private func toggleFavorite(for exercise: Exercise) {
        if let index = userData.favoriteExercises.firstIndex(of: exercise.name) {
            userData.favoriteExercises.remove(at: index)
        } else {
            // Remove from disliked if present
            if let dislikeIndex = userData.dislikedExercises.firstIndex(of: exercise.name) {
                userData.dislikedExercises.remove(at: dislikeIndex)
                userData.saveSingleVariableToFile(\.dislikedExercises, for: .dislikedExercises)
            }
            userData.favoriteExercises.append(exercise.name)
            userData.saveSingleVariableToFile(\.favoriteExercises, for: .favoriteExercises)
        }
    }
    
    private func replaceExercise() {
        if let templateIndex = userData.trainerTemplates.firstIndex(where: { $0.id == template.id }) {
            if let exerciseIndex = userData.trainerTemplates[templateIndex].exercises.firstIndex(where: { $0.name == exercise.name }) {
                let currentExercise = userData.trainerTemplates[templateIndex].exercises[exerciseIndex]
                let similarExercises = findSimilarExercises(to: currentExercise, in: exerciseData.allExercises, userData: userData, existingExercises: userData.trainerTemplates[templateIndex].exercises, replacedExercises: replacedExercises)
                if let newExercise = similarExercises.first, newExercise.name != currentExercise.name {
                    let repsAndSets = RepsAndSets.determineRepsAndSets(customRestPeriod: userData.customRestPeriod, goal: userData.goal, customRepsRange: userData.customRepsRange, customSets: userData.customSets)
                    
                    let detailedExercise = userData.calculateDetailedExercise(exercise: newExercise, repsAndSets: repsAndSets, exerciseData: exerciseData, csvLoader: csvLoader, equipmentData: equipmentData, nextWeek: false)
                    
                    userData.trainerTemplates[templateIndex].exercises[exerciseIndex] = detailedExercise
                    replacedExercises.append(currentExercise.name) // Add replaced exercise to the list
                    print("Appended \(currentExercise.name) to replacedExercises: \(replacedExercises)")
                    print("Updated replacedExercises array: \(replacedExercises)")
                    alertMessage = "Replaced '\(currentExercise.name)' with '\(newExercise.name)' in \(userData.trainerTemplates[templateIndex].name)."
                    showAlert = true
                    userData.saveSingleVariableToFile(\.trainerTemplates, for: .trainerTemplates)
                } else {
                    alertMessage = "No similar exercise found to replace '\(currentExercise.name)'"
                    showAlert = true
                }
            }
        }
        onClose()
    }
    
    func replaceSpecificExercise(with newExercise: Exercise) {
        // Find the template that contains the current exercise
        if let templateIndex = userData.trainerTemplates.firstIndex(where: { $0.exercises.contains(where: { $0.name == exercise.name }) }) {
            
            // Find the index of the current exercise in the template
            if let exerciseIndex = userData.trainerTemplates[templateIndex].exercises.firstIndex(where: { $0.name == exercise.name }) {
                let repsAndSets = RepsAndSets.determineRepsAndSets(customRestPeriod: userData.customRestPeriod, goal: userData.goal, customRepsRange: userData.customRepsRange, customSets: userData.customSets)
                
                let detailedExercise = userData.calculateDetailedExercise(exercise: newExercise, repsAndSets: repsAndSets, exerciseData: exerciseData, csvLoader: csvLoader, equipmentData: equipmentData, nextWeek: false)
                
                // Replace the current exercise with the new exercise in the template
                userData.trainerTemplates[templateIndex].exercises[exerciseIndex] = detailedExercise //updatedExercise
                // Save the updated template to file
                userData.saveSingleVariableToFile(\.trainerTemplates, for: .trainerTemplates)
            }
        }
    }
    
    private func removeExercise() {
        if let templateIndex = userData.trainerTemplates.firstIndex(where: { $0.id == template.id }) {
            if let exerciseIndex = userData.trainerTemplates[templateIndex].exercises.firstIndex(where: { $0.name == exercise.name }) {
                userData.trainerTemplates[templateIndex].exercises.remove(at: exerciseIndex)
                alertMessage = "Removed '\(exercise.name)' from \(userData.trainerTemplates[templateIndex].name)."
                showAlert = true
                userData.saveSingleVariableToFile(\.trainerTemplates, for: .trainerTemplates)
            }
        }
        onClose()
    }
}

func findSimilarExercises(to exercise: Exercise, in allExercises: [Exercise], userData: UserData, existingExercises: [Exercise], replacedExercises: [String]) -> [Exercise] {
    print("Finding similar exercises for: \(exercise.name)")
    print("Replaced exercises: \(replacedExercises)")
    
    // Convert arrays to sets for easy equality or subset checks
    let exercisePrimarySet = Set(exercise.primaryMuscles)
    
    // 1) Filter for candidate exercises that:
    //    - Are not the same name
    //    - Overlap or match the same primary muscles
    //    - Equipment requirements are satisfied by the user's equipment
    //    - Have the same distinction, e.g. .compound vs .isolation
    //    - Are not already in existing exercises
    //    - Have not been replaced
    var similarExercises = allExercises.filter { candidate in
        
        // Exclude if same name
        guard candidate.name != exercise.name else { return false }
        
        // Convert candidate's primary array to a set
        let candidatePrimarySet = Set(candidate.primaryMuscles)
        
        // Check if the sets are "equal" or at least "intersect"
        // to mimic your old logic:
        // If you want them EXACT, do:  candidatePrimarySet == exercisePrimarySet
        // If you want them to share ANY primary muscle, do:  !candidatePrimarySet.isDisjoint(with: exercisePrimarySet)
        
        let samePrimaryMuscles = (candidatePrimarySet == exercisePrimarySet)
        
        // Equipment check
        let userEquipment = userData.equipmentSelected.map { $0.name }
        
        // candidate.equipmentRequired might be an array of some custom type or enum
        // We'll assume it's [String] for the sake of example, or do whatever suits your code
        let equipmentSatisfied = candidate.equipmentRequired.allSatisfy { required in
            userEquipment.contains(required)
        }
        
        // Distinction check: e.g., .compound or .isolation
        let sameDistinction = (candidate.exDistinction == exercise.exDistinction)
        
        // Ensure it's not in existing exercises
        let notInExisting = !existingExercises.contains(where: { $0.name == candidate.name })
        
        // Ensure it hasn't been replaced
        let notReplaced = !replacedExercises.contains(candidate.name)
        
        return samePrimaryMuscles &&
        equipmentSatisfied &&
        sameDistinction &&
        notInExisting &&
        notReplaced
    }
    
    // 2) If none were found, relax the constraints a bit
    //    e.g., ignore exDistinction? or ignore the distinction
    if similarExercises.isEmpty {
        similarExercises = allExercises.filter { candidate in
            guard candidate.name != exercise.name else { return false }
            let candidatePrimarySet = Set(candidate.primaryMuscles)
            
            // Now maybe you only require they share ANY primary muscle
            let shareAnyPrimary = !candidatePrimarySet.isDisjoint(with: exercisePrimarySet)
            
            let userEquipment = userData.equipmentSelected.map { $0.name }
            let equipmentSatisfied = candidate.equipmentRequired.allSatisfy { required in
                userEquipment.contains(required)
            }
            
            let notInExisting = !existingExercises.contains(where: { $0.name == candidate.name })
            let notReplaced = !replacedExercises.contains(candidate.name)
            
            // Distinction is no longer required in fallback
            return shareAnyPrimary &&
            equipmentSatisfied &&
            notInExisting &&
            notReplaced
        }
    }
    
    return similarExercises
}
