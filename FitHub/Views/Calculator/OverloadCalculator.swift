//
//  ProgressiveOverloadView.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/5/24.
//

import SwiftUI

struct TemplateSelection: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedTemplate: SelectedTemplate?
    @State private var navigateToOverload: Bool = false

    var body: some View {
        workoutList()
        .navigationDestination(isPresented: $navigateToOverload) {
            if let selectedTemplate = selectedTemplate {
                OverloadCalculator(selectedTemplate: selectedTemplate)
            }
        }
        .navigationTitle("Select Template").navigationBarTitleDisplayMode(.inline)
    }
    
    private func workoutList() -> some View {
        List {
            if userData.userTemplates.isEmpty && userData.trainerTemplates.isEmpty {
                Text("No templates found.")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                if !userData.userTemplates.isEmpty {
                    templatesSection(templates: userData.userTemplates, userTemplates: true)
                }
                if !userData.trainerTemplates.isEmpty {
                    templatesSection(templates: userData.trainerTemplates, userTemplates: false)
                }
            }
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate], userTemplates: Bool) -> some View {
        Section(header: Text(userTemplates ? "Your Templates" : "Trainer Templates")) {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, userTemplate: userTemplates)
            }
        }
    }
    
    private func templateButton(for index: Int, userTemplate: Bool) -> some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
            // Main button action area
            Button(action: {
                let template = userTemplate ? userData.userTemplates[index] : userData.trainerTemplates[index]
                selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: userTemplate)
                navigateToOverload = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(userTemplate ? userData.userTemplates[index].name : userData.trainerTemplates[index].name)
                            .foregroundColor(.primary) // Ensure the text color remains unchanged
                        Text(SplitCategory.concatenateCategories(for: userTemplate ? userData.userTemplates[index].categories : userData.trainerTemplates[index].categories))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .centerVertically()
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure the button takes full width and aligns content to the left
                .contentShape(Rectangle()) // Make the entire area tappable
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct OverloadCalculator: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    @EnvironmentObject var csvLoader: CSVLoader
    @EnvironmentObject var equipmentData: EquipmentData
    @State private var selectedWeek: Int = 1
    @State private var weekExerciseMap: [Int: [Exercise]] = [:] // Map weeks to processed exercises
    var selectedTemplate: SelectedTemplate

    var body: some View {
        ZStack {
              Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
                
            VStack {
                // Week Picker
                HStack {
                    Text("Week")
                        .fontWeight(.semibold)
                        .font(.subheadline)
                        .padding(.leading)
                    
                    Picker("Select Week", selection: $selectedWeek) {
                        ForEach(1...userData.progressiveOverloadPeriod, id: \.self) { week in
                            Text("\(week)")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .onChange(of: selectedWeek) {
                        updateProcessedExercises()
                    }
                }
                
                if let processedExercises = weekExerciseMap[selectedWeek] {
                    let previousWeekExercises = weekExerciseMap[selectedWeek - 1] // Safely fetch previous week
                    let template = selectedTemplate.isUserTemplate ? userData.userTemplates[selectedTemplate.index] : userData.trainerTemplates[selectedTemplate.index]
                    WorkoutTemplateView(processedExercises: processedExercises, previousWeekExercises: previousWeekExercises ?? [], templateName: template.name)
                }
            }
            .onAppear {
                updateProcessedExercises()
            }
            .navigationTitle("Progressive Overload").navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func updateProcessedExercises() {
        var template: WorkoutTemplate
        let selectedTemplateIndex = selectedTemplate.index
        
        if selectedTemplate.isUserTemplate {
            guard userData.userTemplates.indices.contains(selectedTemplateIndex) else {
                //print("Debug: selectedTemplateIndex out of range - \(selectedTemplateIndex)")
                return
            }
            template = userData.userTemplates[selectedTemplateIndex]
        } else {
            // Debug: check if the selectedTemplateIndex is within the range
            guard userData.trainerTemplates.indices.contains(selectedTemplateIndex) else {
                //print("Debug: selectedTemplateIndex out of range - \(selectedTemplateIndex)")
                return
            }
            template = userData.trainerTemplates[selectedTemplateIndex]
        }
        //print("Debug: Using template - \(template.name)")
        
        // Initialize week 0 with the base exercises if it hasn't been initialized yet
        if weekExerciseMap[0] == nil {
            weekExerciseMap[0] = template.exercises.map { exercise in
                var baseExercise = exercise
                baseExercise.weeksStagnated = userData.stagnationPeriod
                baseExercise.overloadProgress = 0
                baseExercise.setDetails = exercise.setDetails // Original details are preserved here
                return baseExercise
            }
        }
        
        // Process all weeks up to the selected week
        for week in 1...selectedWeek {
            //print("\nDebug: Processing week \(week)")
            
            // Only process if not already cached
            if weekExerciseMap[week] == nil {
                //print("Debug: No cached data for week \(week), processing...")
                
                //weekExerciseMap[week] = template.exercises.map { exercise in
                weekExerciseMap[week] = weekExerciseMap[0]!.map { exercise in
                    var newExercise = exercise
                    
                    // Set weeks stagnated to the user's stagnation period
                    newExercise.weeksStagnated = userData.stagnationPeriod
                    //print("Debug: Updated weeksStagnated for exercise \(exercise.name) to \(newExercise.weeksStagnated)")
                    
                    // Update overload progress based on the week
                    newExercise.overloadProgress = week
                    //print("Debug: Updated overloadProgress for exercise \(exercise.name) to \(week)")
                    
                    // Apply progressive overload to set details
                    newExercise.setDetails = ProgressiveOverloadStyle.applyProgressiveOverload(
                        exercise: newExercise,
                        period: userData.progressiveOverloadPeriod,
                        style: userData.progressiveOverloadStyle,
                        roundingPreference: userData.roundingPreference,
                        equipmentData: equipmentData)
                    
                    //print("Debug: Applied progressive overload to \(exercise.name), new set details: \(newExercise.setDetails)")
                    
                    return newExercise
                }
            } else {
                //print("Debug: Using cached data for week \(week)")
            }
        }
    }
}


struct WorkoutTemplateView: View {
    var processedExercises: [Exercise]
    var previousWeekExercises: [Exercise]?
    var templateName: String
    
    var body: some View {
        ZStack {
            // 1) the full-screen background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(templateName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    if processedExercises.isEmpty {
                        HStack {
                            Spacer()
                            Text("No Exercises Available for this Template.")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    } else {
                        ForEach(processedExercises) { exercise in
                            VStack(alignment: .leading, spacing: 10) {
                                
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    //.padding(.bottom, 5)
                                
                                // Labels Row
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 5) {
                                    // Headers
                                    Text("Set")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                    Text("Weight")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                    Text("Reps")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                }
                                
                                LazyVGrid(
                                    columns: [
                                        GridItem(.adaptive(minimum: 80), spacing: 10),
                                        GridItem(.adaptive(minimum: 80), spacing: 10),
                                        GridItem(.adaptive(minimum: 80), spacing: 10)
                                    ],
                                    spacing: 5
                                ) {
                                    // Rows for each set
                                    ForEach(exercise.setDetails) { set in
                                        let previousSet = previousWeekExercises?
                                            .first(where: { $0.id == exercise.id })?
                                            .setDetails
                                            .first(where: { $0.setNumber == set.setNumber })
                                        
                                        // Set number
                                        Text("\(set.setNumber)")
                                            .font(.caption)
                                        
                                        // Weight comparison
                                        if let previousWeight = previousSet?.weight, previousWeight != set.weight {
                                            HStack(spacing: 2) {
                                                // Display previous weight
                                                Text(previousWeight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(previousWeight))" : "\(previousWeight, specifier: "%.1f")")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                Text(" → ")
                                                    .font(.caption)
                                                
                                                // Display current weight with appropriate color
                                                Text(set.weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(set.weight)) lbs" : "\(set.weight, specifier: "%.1f") lbs")
                                                    .font(.caption)
                                                    .foregroundColor(set.weight > previousWeight ? .green : .red)
                                            }
                                        } else {
                                            Text(exercise.usesWeight ? (set.weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(set.weight)) lbs" : "\(set.weight, specifier: "%.1f") lbs") : "Bodyweight")
                                                .font(.caption)
                                        }
                                        
                                        // Reps comparison
                                        if let previousReps = previousSet?.reps, previousReps != set.reps {
                                            HStack(spacing: 2) {
                                                // Display previous reps
                                                Text("\(previousReps)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                Text(" → ")
                                                    .font(.caption)
                                                
                                                // Display current reps with appropriate color
                                                Text("\(set.reps)")
                                                    .font(.caption)
                                                    .foregroundColor(set.reps > previousReps ? .green : .red)
                                            }
                                        } else {
                                            Text("\(set.reps)")
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
