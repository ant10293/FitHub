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
    @State private var showingExerciseOptions: Bool = false
    @State private var expandList: Bool = false
    @State private var currentTemplateIndex: Int = 0
    @State private var selectedExercise: Exercise?
    @State private var selectedTemplate: SelectedTemplate?
    @State private var alertMessage: String = ""
    @State private var replacedExercises: [String] = [] // Define replacedExercises here
    @State private var isReplacing: Bool = false

    var body: some View {
        TemplateNavigator(
            userData: ctx.userData,
            selectedTemplate: $selectedTemplate
        ) {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Workout Plan Generated!").zIndex(1) }
                    
                    selectionBar
                    HStack {
                        ExpandCollapseList(expandList: $expandList)
                        Spacer()
                        TextButton(
                            title: "Edit",
                            systemImage: "square.and.pencil",
                            action: {
                                if let template = ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex] {
                                    selectedTemplate = .init(template: template, location: .trainer, mode: .directToDetail)
                                }
                            },
                            color: .blue
                        )
                        .padding(.top)
                    }
                    .padding(.horizontal)
                    
                    exerciseList
                    manageSection
                        
                    Spacer()
                }
                .disabled(showingExerciseOptions)
                .padding(.horizontal)
            }
            .generatingOverlay(isReplacing, message: "Replacing Exercise...")
            .navigationBarTitle("Workout Generation", displayMode: .inline)
            .navigationDestination(isPresented: $showingCustomizationForm) { WorkoutCustomization() }
            .alert(isPresented: $showAlert) { Alert(title: Text("Template Update"), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
            .overlay(showingExerciseOptions ? exerciseOptions : nil)
        }
    }
    
    @ViewBuilder private var exerciseOptions: some View {
        if let exercise = selectedExercise {
            ExerciseOptions(
                showAlert: $showAlert,
                alertMessage: $alertMessage,
                replacedExercises: $replacedExercises,
                template: $ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex] ?? .constant(WorkoutTemplate(name: "Default", exercises: [], categories: [])),
                isReplacing: $isReplacing,
                exercise: exercise,
                onClose: {
                    showingExerciseOptions = false
                }
            )
        }
    }
    
    private var selectionBar: some View {
        HStack {
            Spacer()
            Button(action: previousTemplate) {
                Image(systemName: "arrow.left").bold()
                    .contentShape(Rectangle())
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
                            .foregroundStyle(.gray)
                            .zIndex(1)  // Ensures is above all other content
                    }
                }
            }
            .frame(alignment: .center)
            .padding(.horizontal)
            
            Button(action: nextTemplate) {
                Image(systemName: "arrow.right").bold()
                    .contentShape(Rectangle())
            }
            Spacer()
        }
    }
    
    // TODO: should shrink and display a message that no template(s) exist
    private var exerciseList: some View {
        List {
            if let template = ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex] {
                Section {
                    if template.exercises.isEmpty {
                        Text("No exercises defined for this template.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical)
                    } else {
                        ForEach(template.exercises, id: \.id) { exercise in
                            ExerciseRow(
                                exercise,
                                secondary: true,
                                heartOverlay: true,
                                favState: FavoriteState.getState(for: exercise, userData: ctx.userData)
                            ) {
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
                                exercise.setsSubtitle
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
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
        .frame(maxHeight: !expandList ? UIScreen.main.bounds.height * 0.66 : .infinity)
    }
    
    @ViewBuilder private var manageSection: some View {
        if !expandList {
            Button("Modify Workout Generation") { showingCustomizationForm = true }
                .disabled(showingExerciseOptions)
                .font(.subheadline)
                .padding()
            
            RectangularButton(
                title: "Generate Workout Plan",
                enabled: !showingExerciseOptions && !ctx.userData.isWorkingOut,
                width: .fit,
                action: {
                    ctx.userData.generateWorkoutPlan(
                        exerciseData: ctx.exercises,
                        equipmentData: ctx.equipment,
                        keepCurrentExercises: ctx.userData.workoutPrefs.keepCurrentExercises,
                        nextWeek: false,
                        onDone: {
                            ctx.toast.showSaveConfirmation(duration: 2)
                        }
                    )
                }
            )
            
            if let creationDate = ctx.userData.workoutPlans.workoutsCreationDate {
                Text("Last Generated on: \(Format.formatDate(creationDate))")
                    .font(.caption)
                    .padding(.vertical)
                    .multilineTextAlignment(.center)
            }
        }
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
