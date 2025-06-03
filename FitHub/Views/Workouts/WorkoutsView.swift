import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showingTemplateCreation = false
    @State private var showingPopup = false
    @State private var selectedTemplate: SelectedTemplate?
    @State private var navigateToTemplateDetail = false
    @State private var navigateToStartedWorkout = false
    @State private var showingRenameAlert = false
    @State private var showingRenameView = false
    @State private var tempNewName = ""
    @State private var currentExerciseState: CurrentExerciseState?
    @State private var updatedMax: [PerformanceUpdate]?
    @Binding var showResumeWorkoutOverlay: Bool
    
    var body: some View {
        NavigationStack {
            workoutList()
            .sheet(isPresented: $showingTemplateCreation) {
                templateCreationView()
            }
            .navigationDestination(isPresented: $navigateToTemplateDetail) {
                if let selectedTemplate = selectedTemplate {
                    if selectedTemplate.isUserTemplate, userData.userTemplates.indices.contains(selectedTemplate.index) {
                        TemplateDetail(template: $userData.userTemplates[selectedTemplate.index], onDone: {
                            self.navigateToTemplateDetail = false
                        })
                    } else if !selectedTemplate.isUserTemplate, userData.trainerTemplates.indices.contains(selectedTemplate.index) {
                        TemplateDetail(template: $userData.trainerTemplates[selectedTemplate.index], onDone: {
                            self.navigateToTemplateDetail = false
                        })
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToStartedWorkout) {
                if let selectedTemplate = selectedTemplate {
                    if selectedTemplate.isUserTemplate, userData.userTemplates.indices.contains(selectedTemplate.index) {
                        StartedWorkoutView(viewModel: WorkoutViewModel(template: userData.userTemplates[selectedTemplate.index], currentExerciseState: currentExerciseState, updatedMax: updatedMax), onExit: {
                            resetWorkoutState()
                        })
                    } else if !selectedTemplate.isUserTemplate, userData.trainerTemplates.indices.contains(selectedTemplate.index) {
                        StartedWorkoutView(viewModel: WorkoutViewModel(template: userData.trainerTemplates[selectedTemplate.index], currentExerciseState: currentExerciseState, updatedMax: updatedMax), onExit: {
                            resetWorkoutState()
                        })
                    }
                }
            }
            .onChange(of: userData.workoutsCreationDate) {
                if let selectedTemplate = selectedTemplate {
                    if !selectedTemplate.isUserTemplate {
                        navigateToTemplateDetail = false
                    }
                }
            }
            .disabled(showResumeWorkoutOverlay || shouldDisableWorkoutButton())
            .overlay(templatePopupOverlay())
            .overlay(renameTemplateOverlay())
            .overlay(resumeWorkoutOverlay())
            .navigationTitle("Start a Workout")
            .navigationBarHidden(showingPopup)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .padding()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MenuView()) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func resumeWorkoutOverlay() -> some View {
        if showResumeWorkoutOverlay {
            VStack {
                Spacer()
                VStack {
                    Text("You still have a workout in progress.")
                        .font(.title2)
                        .padding(.bottom, 10)
                    Text("Would you like to resume this workout?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button(action: {
                            if let workoutInProgress = userData.activeWorkout {
                                userData.resetExercisesInTemplate(for: workoutInProgress.template)
                                resetWorkoutState()
                            }
                            showResumeWorkoutOverlay = false
                        }) {
                            Text("Cancel")
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button(action: {
                            // Navigate to the workout in progress
                            if let workoutInProgress = userData.activeWorkout {
                                // Update the timer with the saved elapsed time, but don't start it yet
                                timerManager.secondsElapsed = workoutInProgress.elapsedTime
                                
                                currentExerciseState = workoutInProgress.currentExerciseState
                                updatedMax = workoutInProgress.updatedMax
                                
                                // First search in userTemplates
                                if let index = userData.userTemplates.firstIndex(where: { $0.id == workoutInProgress.template.id }) {
                                    let template = userData.userTemplates[index]
                                    selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: true)
                                }
                                // If not found, search in trainerTemplates
                                else if let trainerIndex = userData.trainerTemplates.firstIndex(where: { $0.id == workoutInProgress.template.id }) {
                                    let template = userData.trainerTemplates[trainerIndex]
                                    selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: trainerIndex, isUserTemplate: false)
                                }
                                navigateToStartedWorkout = true
                            }
                            showResumeWorkoutOverlay = false
                        }) {
                            Text("Resume")
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding(.horizontal, 40)
                Spacer()
            }
        }
    }
    
    private func shouldDisableWorkoutButton() -> Bool {
        return timerManager.timerIsActive || userData.activeWorkout != nil
    }
    
    private func resetWorkoutState() {
        print("Reset workout state.")
        currentExerciseState = nil
        updatedMax = nil
        // Clear the saved workout in progress
        userData.activeWorkout = nil
        userData.saveSingleVariableToFile(\.activeWorkout, for: .activeWorkout)
    }
    
    private func workoutList() -> some View {
        List {
            templatesSection(templates: userData.userTemplates, userTemplates: true)
            if !userData.trainerTemplates.isEmpty {
                templatesSection(templates: userData.trainerTemplates, userTemplates: false)
            }
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate], userTemplates: Bool) -> some View {
        Section(header: Text(userTemplates ? "Your Templates" : "Trainer Templates")) {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, userTemplate: userTemplates)
            }
            .onDelete { offset in
                if userTemplates {
                    userData.deleteUserTemplate(at: offset)
                } else {
                    userData.deleteTrainerTemplate(at: offset)
                }
            }
            .disabled(showingPopup)
            
            if userTemplates {
                Button(action: {
                    showingTemplateCreation = true
                }) {
                    Label("Create New Template", systemImage: "square.and.pencil")
                }
                .disabled(showingPopup || showingRenameView)
            }
        }
    }
    
    private func templateButton(for index: Int, userTemplate: Bool) -> some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
            // Main button action area
            Button(action: {
                let template = userTemplate ? userData.userTemplates[index] : userData.trainerTemplates[index]
                selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: userTemplate)
                self.showingPopup = true
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
            .disabled(showingPopup || showingRenameView)
            
            if userTemplate {
                // Dedicated button for rename/delete actions
                Button(action: {
                    self.tempNewName = userData.userTemplates[index].name
                    let template = userTemplate ? userData.userTemplates[index] : userData.trainerTemplates[index]
                    selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: userTemplate)
                    self.showingRenameView = true
                }) {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(showingPopup || showingRenameView)
            }
        }
    }
    
    private func renameTemplateOverlay() -> some View {
        Group {
            if let index = selectedTemplate?.index, showingRenameView {
                RenameTemplate(
                    isPresented: $showingRenameView,
                    name: $tempNewName,
                    workoutTemplate: userData.userTemplates[index],
                    onRename: {
                        self.renameTemplate(at: index, with: self.tempNewName)
                    }, onDelete: {
                        userData.deleteUserTemplate(at: IndexSet(integer: index))
                    }
                )
            }
        }
    }
    
    // Rename the template at the given index with the new name
    private func renameTemplate(at index: Int, with newName: String) {
        if userData.userTemplates.indices.contains(index) {
            userData.userTemplates[index].name = newName
            userData.saveSingleVariableToFile(\.userTemplates, for: .userTemplates)
        }
    }
    
    private func templatePopupOverlay() -> some View {
        Group {
            if let template = selectedTemplate, showingPopup {
                TemplatePopup(template: template.isUserTemplate ? $userData.userTemplates[template.index] : $userData.trainerTemplates[template.index], onClose: {
                    self.showingPopup = false
                }, onBeginWorkout: {
                    self.navigateToStartedWorkout = true
                    self.showingPopup = false
                }, onEdit: {
                    self.navigateToTemplateDetail = true
                })
                .frame(width: 300, height: 400)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.scale)
            }
        }
    }
    
    private func templateCreationView() -> some View {
        NewTemplate() { templateName, selectedCategories, selectedDate in
            // Create a new template
            var newTemplate = WorkoutTemplate(
                name: templateName,
                exercises: [],
                categories: selectedCategories,
                date: selectedDate,
                notificationIDs: [] // Initialize as empty
            )
            if selectedDate != nil {
                // Schedule notifications and get the IDs
                let notificationIDs = userData.scheduleNotification(for: newTemplate)
                newTemplate.notificationIDs.append(contentsOf: notificationIDs) // Append notification IDs
            }
            // Append the new template to the user's templates
            userData.userTemplates.append(newTemplate)
            
            // Set the active template index
            if let index = userData.userTemplates.firstIndex(where: { $0.id == newTemplate.id }) {
                selectedTemplate = SelectedTemplate(id: newTemplate.id, name: newTemplate.name, index: index, isUserTemplate: true)
            }
            
            // Save the new template
            userData.saveSingleVariableToFile(\.userTemplates, for: .userTemplates)

            self.showingTemplateCreation = false
            self.showingPopup = true
        }
    }
}








