import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var showResumeWorkoutOverlay: Bool
    @State private var showingTemplateCreation: Bool = false
    @State private var showingTemplateEditor: Bool = false
    @State private var selectedTemplate: SelectedTemplate?
    @State private var editingTemplateIndex: Int?
    
    var body: some View {
        NavigationStack {
            TemplateNavigator(
                userData: ctx.userData,
                selectedTemplate: $selectedTemplate,
                navigationMode: .popupOverlay,
                skipPopupForResume: true
            ) {
                workoutList
                .sheet(isPresented: $showingTemplateCreation) { templateCreationView }
                .sheet(isPresented: $showingTemplateEditor) { templateEditorView }
                .disabled(showResumeWorkoutOverlay || shouldDisableWorkoutButton)
                .overlay(showResumeWorkoutOverlay ? resumeWorkoutOverlay : nil)
                .navigationTitle("Start a Workout")
                .customToolbar(
                    settingsDestination: { AnyView(SettingsView()) },
                    menuDestination: { AnyView(MenuView()) }
                )
            }
        }
    }
    
    private var resumeWorkoutOverlay: some View {
        ResumeWorkoutOverlay(
            cancel: {
                if let workoutInProgress = activeWorkout {
                    ctx.userData.resetExercisesInTemplate(for: workoutInProgress.template, shouldSave: true)
                }
                showResumeWorkoutOverlay = false
            },
            resume: {
                // Navigate to the workout in progress
                if let workoutInProgress = activeWorkout {
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
                }
                showResumeWorkoutOverlay = false
            }
        )
    }
    
    private var shouldDisableWorkoutButton: Bool {
        return ctx.userData.isWorkingOut || ctx.userData.sessionTracking.activeWorkout != nil
    }
    
    private var activeWorkout: WorkoutInProgress? {
        return ctx.userData.sessionTracking.activeWorkout
    }
    
    private var workoutList: some View {
        List {
            if !ctx.userData.workoutPlans.trainerTemplates.isEmpty {
                templatesSection(templates: ctx.userData.workoutPlans.trainerTemplates, userTemplates: false)
            }
            templatesSection(templates: ctx.userData.workoutPlans.userTemplates, userTemplates: true)
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate], userTemplates: Bool) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, userTemplate: userTemplates, template: templates[index])
            }
            .onDelete { offset in
                if userTemplates {
                    ctx.userData.deleteUserTemplate(at: offset)
                } else {
                    ctx.userData.deleteTrainerTemplate(at: offset)
                }
            }
            
            if userTemplates {
                Button(action: { showingTemplateCreation = true }) {
                    Label("Create New Template", systemImage: "square.and.pencil")
                }
                .disabled(showingTemplateEditor)
            }
        } header: {
            Text(userTemplates ? "Your Templates" : "Trainer Templates")
        }
    }
    
    private func templateButton(for index: Int, userTemplate: Bool, template: WorkoutTemplate) -> some View {
        TemplateRow(
            template: template,
            index: index,
            userTemplate: userTemplate,
            disabled: showingTemplateEditor,
            onSelect: { newSelection in
                selectedTemplate = newSelection
            },
            onEdit: { newSelection in
                // For editing, only show the sheet directly - don't set selectedTemplate
                // This prevents the popup from appearing
                editingTemplateIndex = index
                showingTemplateEditor = true
            }
        )
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
                    }
                    showingTemplateCreation = false
                }
            }
        )
    }
    
    @ViewBuilder private var templateEditorView: some View {
        if let index = editingTemplateIndex {
            let currentTemplate = ctx.userData.workoutPlans.userTemplates[index]
            EditTemplate(
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
                        tpl.name = WorkoutTemplate.uniqueTemplateName(initialName: tpl.name, from: ctx.userData.workoutPlans.archivedTemplates)
                        ctx.userData.workoutPlans.archivedTemplates.append(tpl)
                        ctx.userData.deleteUserTemplate(at: index)
                    }
                }
            )
        }
    }
    
    private var uniqueTemplateName: String {
        let initialName: String = "New Template"
        return WorkoutTemplate.uniqueTemplateName(initialName: initialName, from: ctx.userData.workoutPlans.userTemplates)
    }
}
