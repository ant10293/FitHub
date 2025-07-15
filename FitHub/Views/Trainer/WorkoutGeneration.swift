//
//  WorkoutGeneration.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/13/24.
//

import SwiftUI


struct WorkoutGeneration: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @EnvironmentObject private var ctx: AppContext
    @State private var showingCustomizationForm: Bool = false
    @State private var showAlert: Bool = false
    @State private var showingTemplateDetail: Bool = false // control the navigation to TemplateDetailView
    @State private var showingExerciseOptions: Bool = false
    @State private var showingLogDetail: Bool = false   // ← add near other @State vars
    @State private var currentTemplateIndex: Int = 0
    @State private var selectedExercise: Exercise?
    @State private var alertMessage: String = ""
    @State private var replacedExercises: [String] = [] // Define replacedExercises here
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Workout Plan Generated!", height: 150).zIndex(1) }
                VStack {
                    HStack {
                        Spacer()
                        Button(action: previousTemplate) {
                            Image(systemName: "arrow.left").bold()
                                .contentShape(Rectangle())
                                .disabled(showingExerciseOptions)
                        }
                        
                        HStack {
                            VStack(spacing: 4) {
                                Text(ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex]?.name ?? "No Template")
                                
                                if let categories = ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex]?.categories {
                                    Text(SplitCategory.concatenateCategories(for: categories))
                                        .font(.subheadline)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.7)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                        .zIndex(1)  // Ensures is above all other content
                                }
                            }
                            
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.blue)
                                .padding(.leading, -5)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { showingTemplateDetail = true }
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
                        if let template = ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex] {
                            Section {
                                ForEach(template.exercises, id: \.id) { exercise in
                                    ExerciseRow(exercise, secondary: true) {
                                        Button(action: {
                                            selectedExercise = exercise
                                            showingExerciseOptions = true
                                        }) {
                                            Image(systemName: "ellipsis")
                                                .imageScale(.medium)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } detail: {
                                        Text(subtitle(for: exercise))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            } header: {
                                Text("\(template.numExercises) Exercises")
                                    .font(.caption)
                            }
                        }
                    }
                    .disabled(showingExerciseOptions)
                    .padding(.top, -5) // Reduce space above the list
                }
                .padding(.horizontal)
                
                Button("Modify Workout Generation") { showingCustomizationForm = true }
                .disabled(showingExerciseOptions)
                .font(.subheadline)
                .padding()
                
                Button("Generate Workout Plan") {
                    print("keepCurrentExercises: \(ctx.userData.workoutPrefs.keepCurrentExercises)")
                    ctx.userData.generateWorkoutPlan(exerciseData: ctx.exercises, equipmentData: ctx.equipment, keepCurrentExercises: ctx.userData.workoutPrefs.keepCurrentExercises, nextWeek: false)
                    ctx.toast.showSaveConfirmation(duration: 2)
                }
                .disabled(showingExerciseOptions)
                .foregroundColor(.white)
                .padding()
                .background(!showingExerciseOptions ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .clipShape(Rectangle())
                
                if let creationDate = ctx.userData.workoutPlans.workoutsCreationDate {
                    Text("Last Generated on: \(Format.formatDate(creationDate))")
                        .font(.caption)
                        .padding(.vertical)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
        .navigationBarTitle("Workout Generation", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if ctx.userData.workoutPlans.logFileURL != nil {      // only show when we have a file
                    Button {
                        showingLogDetail = true                       // push detail view
                    } label: {
                        Image(systemName: "doc.text.magnifyingglass") // pick any icon you like
                            .imageScale(.medium)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingLogDetail) {
            if let url = ctx.userData.workoutPlans.logFileURL {
                LogDetailView(url: url)      // <— the reader view you built earlier
            }
        }
        .navigationDestination(isPresented: $showingTemplateDetail) {
            if let template = $ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex] {
                TemplateDetail(template: template, onDone: {
                    self.showingTemplateDetail = false
                })
            }
        }
        .navigationDestination(isPresented: $showingCustomizationForm) { WorkoutCustomization() }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Template updated"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .overlay(
            Group {
                if showingExerciseOptions, let exercise = selectedExercise {
                    ExerciseOptions(
                        showAlert: $showAlert,
                        alertMessage: $alertMessage,
                        replacedExercises: $replacedExercises,
                        template: $ctx.userData.workoutPlans.trainerTemplates[currentTemplateIndex],
                        exercise: exercise,
                        onClose: {
                            showingExerciseOptions = false
                        }
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
            currentTemplateIndex = ctx.userData.workoutPlans.trainerTemplates.count - 1
        }
    }
    
    // Navigate to the next template
    private func nextTemplate() {
        if currentTemplateIndex < (ctx.userData.workoutPlans.trainerTemplates.count - 1) {
            currentTemplateIndex += 1
        } else {
            currentTemplateIndex = 0
        }
    }
}



