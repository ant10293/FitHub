import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.colorScheme) var colorScheme
    @State private var showingTemplateCreation = false
    @State private var showingPopup = false
    @State private var selectedTemplate: SelectedTemplate?
    @State private var navigateToTemplateDetail = false
    @State private var navigateToStartedWorkout = false
    @State private var showingRenameAlert = false
    @State private var showingEditView = false
    @State private var activeWorkout: WorkoutInProgress?
    @Binding var showResumeWorkoutOverlay: Bool
    
    var body: some View {
        NavigationStack {
            workoutList
            .sheet(isPresented: $showingTemplateCreation) {
                templateCreationView
            }
            .navigationDestination(isPresented: $navigateToTemplateDetail) {
                if let selectedTemplate = selectedTemplate {
                    if selectedTemplate.isUserTemplate, ctx.userData.workoutPlans.userTemplates.indices.contains(selectedTemplate.index) {
                        TemplateDetail(template: $ctx.userData.workoutPlans.userTemplates[selectedTemplate.index], onDone: { navigateToTemplateDetail = false })
                    } else if !selectedTemplate.isUserTemplate, ctx.userData.workoutPlans.trainerTemplates.indices.contains(selectedTemplate.index) {
                        TemplateDetail(template: $ctx.userData.workoutPlans.trainerTemplates[selectedTemplate.index], onDone: { navigateToTemplateDetail = false })
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToStartedWorkout) {
                if let selectedTemplate = selectedTemplate {
                    if selectedTemplate.isUserTemplate, ctx.userData.workoutPlans.userTemplates.indices.contains(selectedTemplate.index) {
                        StartedWorkoutView(viewModel: WorkoutVM(template: ctx.userData.workoutPlans.userTemplates[selectedTemplate.index], activeWorkout: activeWorkout), onExit: {
                            resetWorkoutState()
                        })
                    } else if !selectedTemplate.isUserTemplate, ctx.userData.workoutPlans.trainerTemplates.indices.contains(selectedTemplate.index) {
                        StartedWorkoutView(viewModel: WorkoutVM(template: ctx.userData.workoutPlans.trainerTemplates[selectedTemplate.index], activeWorkout: activeWorkout), onExit: {
                            resetWorkoutState()
                        })
                    }
                }
            }
            .onChange(of: ctx.userData.workoutPlans.workoutsCreationDate) {
                if let selectedTemplate = selectedTemplate, !selectedTemplate.isUserTemplate {
                    navigateToTemplateDetail = false 
                }
            }
            .disabled(showResumeWorkoutOverlay || shouldDisableWorkoutButton() || showingPopup || showingEditView)
            .overlay(templatePopupOverlay)
            .overlay(editTemplateOverlay)
            .overlay(showResumeWorkoutOverlay ? resumeWorkoutOverlay : nil)
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
    
    private var resumeWorkoutOverlay: some View {
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
                        if let workoutInProgress = ctx.userData.sessionTracking.activeWorkout {
                            ctx.userData.resetExercisesInTemplate(for: workoutInProgress.template)
                            resetWorkoutState(userUpdate: true)
                        }
                        showResumeWorkoutOverlay = false
                    }) {
                        Text("Cancel")
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(action: {
                        // Navigate to the workout in progress
                        if let workoutInProgress = ctx.userData.sessionTracking.activeWorkout {
                            activeWorkout = workoutInProgress
                            
                            // First search in userTemplates
                            if let index = ctx.userData.workoutPlans.userTemplates.firstIndex(where: { $0.id == workoutInProgress.template.id }) {
                                let template = ctx.userData.workoutPlans.userTemplates[index]
                                selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: true)
                            }
                            // If not found, search in trainerTemplates
                            else if let trainerIndex = ctx.userData.workoutPlans.trainerTemplates.firstIndex(where: { $0.id == workoutInProgress.template.id }) {
                                let template = ctx.userData.workoutPlans.trainerTemplates[trainerIndex]
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
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    private func shouldDisableWorkoutButton() -> Bool {
        return ctx.userData.isWorkingOut || ctx.userData.sessionTracking.activeWorkout != nil
    }
    
    private func resetWorkoutState(userUpdate: Bool = false) {
        print("Reset workout state.")
        activeWorkout = nil
        
        if userUpdate {
            // Clear the saved workout in progress
            ctx.userData.sessionTracking.activeWorkout = nil
            ctx.userData.saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)
        }
    }
    
    private var workoutList: some View {
        List {
            templatesSection(templates: ctx.userData.workoutPlans.userTemplates, userTemplates: true)
            if !ctx.userData.workoutPlans.trainerTemplates.isEmpty {
                templatesSection(templates: ctx.userData.workoutPlans.trainerTemplates, userTemplates: false)
            }
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate], userTemplates: Bool) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, userTemplate: userTemplates)
            }
            .onDelete { offset in
                if userTemplates {
                    ctx.userData.deleteUserTemplate(at: offset)
                } else {
                    ctx.userData.deleteTrainerTemplate(at: offset)
                }
            }
            .disabled(showingPopup)
            
            if userTemplates {
                Button(action: { showingTemplateCreation = true }) {
                    Label("Create New Template", systemImage: "square.and.pencil")
                }
                .disabled(showingPopup || showingEditView)
            }
        } header: {
            Text(userTemplates ? "Your Templates" : "Trainer Templates")
        }
    }
    
    private func templateButton(for index: Int, userTemplate: Bool) -> some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
            // Main button action area
            Button(action: {
                let template = userTemplate ? ctx.userData.workoutPlans.userTemplates[index] : ctx.userData.workoutPlans.trainerTemplates[index]
                selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: userTemplate)
                showingPopup = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(userTemplate ? ctx.userData.workoutPlans.userTemplates[index].name : ctx.userData.workoutPlans.trainerTemplates[index].name)
                            .foregroundColor(.primary) // Ensure the text color remains unchanged
                        Text(SplitCategory.concatenateCategories(for: userTemplate ? ctx.userData.workoutPlans.userTemplates[index].categories : ctx.userData.workoutPlans.trainerTemplates[index].categories))
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
            .disabled(showingPopup || showingEditView)
            
            if userTemplate {
                // Dedicated button for rename/delete actions
                Button(action: {
                    let template = userTemplate ? ctx.userData.workoutPlans.userTemplates[index] : ctx.userData.workoutPlans.trainerTemplates[index]
                    selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: userTemplate)
                    showingEditView = true
                }) {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(showingPopup || showingEditView)
            }
        }
    }
    
    @ViewBuilder private var editTemplateOverlay: some View {
        if let index = selectedTemplate?.index, showingEditView {
            let currentTemplate = ctx.userData.workoutPlans.userTemplates[index]
            EditTemplate(
                isPresented: $showingEditView,
                showDatePicker: currentTemplate.date != nil,
                template: currentTemplate,
                originalTemplate: currentTemplate,
                gender: ctx.userData.physical.gender,
                useDateOnly: ctx.userData.settings.useDateOnly,
                checkDuplicate: { templateName in
                    return ctx.userData.workoutPlans.userTemplates.contains(where: { $0.name == templateName })
                },
                onDelete: {
                    ctx.userData.deleteUserTemplate(at: index)
                },
                onUpdateTemplate: { updatedTemplate in
                    if let updatedTemplate = updatedTemplate {
                        _ = ctx.userData.updateTemplate(template: updatedTemplate)
                    }
                },
                onArchiveTemplate: { templateToArchive in
                    if let template = templateToArchive {
                        var tpl = template
                        tpl.name = ctx.userData.uniqueTemplateName(initialName: tpl.name, from: ctx.userData.workoutPlans.archivedTemplates)
                        ctx.userData.workoutPlans.archivedTemplates.append(tpl)
                        ctx.userData.deleteUserTemplate(at: index)
                    }
                }
            )
        }
    }
    
    @ViewBuilder private var templatePopupOverlay: some View {
        if let template = selectedTemplate, showingPopup {
            TemplatePopup(
                template: template.isUserTemplate ? $ctx.userData.workoutPlans.userTemplates[template.index] : $ctx.userData.workoutPlans.trainerTemplates[template.index],
                onClose: {
                    showingPopup = false
                }, onBeginWorkout: {
                    navigateToStartedWorkout = true
                    showingPopup = false
                }, onEdit: {
                    navigateToTemplateDetail = true
                }
            )
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.5)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .transition(.scale)
        }
    }
    
    private var templateCreationView: some View {
        NewTemplate(
            template: WorkoutTemplate(name: uniqueTemplateName, exercises: [], categories: []),
            gender: ctx.userData.physical.gender,
            useDateOnly: ctx.userData.settings.useDateOnly,
            checkDuplicate: { templateName in
                return ctx.userData.workoutPlans.userTemplates.contains(where: { $0.name == templateName })
            },
            onCreate: { newTemplate in
                if let newTemplate = newTemplate {
                    ctx.userData.addUserTemplate(template: newTemplate)
                    if let index = ctx.userData.workoutPlans.userTemplates.firstIndex(where: { $0.id == newTemplate.id }) {
                        selectedTemplate = SelectedTemplate(id: newTemplate.id, name: newTemplate.name, index: index, isUserTemplate: true)
                        showingPopup = true
                    }
                    showingTemplateCreation = false
                }
            }
        )
    }
    
    private var uniqueTemplateName: String {
        let initialName: String = "New Template"
        return ctx.userData.uniqueTemplateName(initialName: initialName, from: ctx.userData.workoutPlans.userTemplates)
    }
}
