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
    @State private var expandList: Bool = false
    @State private var currentTemplateIndex: Int = 0
    @State private var selectedExercise: Exercise?
    @State private var alertMessage: String = ""
    @State private var replacedExercises: [String] = [] // Define replacedExercises here
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Workout Plan Generated!").zIndex(1) }
                
                selectionBar
                ExpandCollapseList(expandList: $expandList)
                exerciseList
                manageSection
                    
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationBarTitle("Workout Generation", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        .alert(isPresented: $showAlert) { Alert(title: Text("Template updated"), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
        .overlay(showingExerciseOptions ? exerciseOptions : nil)
    }
    
    @ViewBuilder private var exerciseOptions: some View {
        if let exercise = selectedExercise {
            ExerciseOptions(
                showAlert: $showAlert,
                alertMessage: $alertMessage,
                replacedExercises: $replacedExercises,
                template: $ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex] ?? .constant(WorkoutTemplate(name: "Default", exercises: [], categories: [])),
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
                            .foregroundStyle(.gray)
                            .zIndex(1)  // Ensures is above all other content
                    }
                }
                
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(.blue)
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
    }
    
    private var exerciseList: some View {
        List {
            if let template = ctx.userData.workoutPlans.trainerTemplates[safe: currentTemplateIndex] {
                Section {
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
