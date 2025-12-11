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
                selectedTemplate: $selectedTemplate
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
                ctx.userData.resetWorkoutSession()
                showResumeWorkoutOverlay = false
            },
            resume: {
                // Navigate to the workout in progress
                if let active = activeWorkout {
                    selectedTemplate = SelectedTemplate(template: active.template, location: .active, mode: .directToWorkout)
                }
                showResumeWorkoutOverlay = false
            }
        )
    }
    
    private var shouldDisableWorkoutButton: Bool {
        return ctx.userData.isWorkingOut || activeWorkout != nil
    }
    
    private var activeWorkout: WorkoutInProgress? { return ctx.userData.sessionTracking.activeWorkout }
    
    private var workoutList: some View {
        List {
            if !ctx.userData.workoutPlans.trainerTemplates.isEmpty {
                templatesSection(templates: ctx.userData.workoutPlans.trainerTemplates, location: .trainer)
            }
            templatesSection(templates: ctx.userData.workoutPlans.userTemplates, location: .user)
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate], location: TemplateLocation) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, location: location, template: templates[index])
            }
            .onDelete { offset in
                if location == .user {
                    ctx.userData.deleteUserTemplate(at: offset)
                } else {
                    ctx.userData.deleteTrainerTemplate(at: offset)
                }
            }
            
            // MARK: premium feature > 4 templates
            if location == .user {
                Button(action: {
                    if ctx.disableCreateWorkout {
                        ctx.userData.premiumFeatureBlocked = .templateLimit
                    } else {
                        showingTemplateCreation = true
                    }
                }) {
                    Label("Create New Template", systemImage: "square.and.pencil")
                }
                .disabled(showingTemplateEditor)
            }
        } header: {
            Text(location.label)
        }
    }
    
    private func templateButton(for index: Int, location: TemplateLocation, template: WorkoutTemplate) -> some View {
        TemplateRow(
            template: template,
            index: index,
            location: location,
            disabled: showingTemplateEditor,
            onSelect: { newSelection in
                selectedTemplate = newSelection
            },
            onEdit: { editSelection in
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
            useDateOnly: ctx.userData.settings.useDateOnly,
            checkDuplicate: { templateName in
                return ctx.userData.workoutPlans.userTemplates.contains(where: { $0.name == templateName })
            },
            onCreate: { newTemplate in
                if let newTemplate = newTemplate {
                    ctx.userData.addUserTemplate(template: newTemplate)
                    selectedTemplate = .init(template: newTemplate, location: .user, mode: .popupOverlay)
                    showingTemplateCreation = false
                }
            }
        )
    }
    
    @ViewBuilder private var templateEditorView: some View {
        if let index = editingTemplateIndex, let currentTemplate = ctx.userData.workoutPlans.userTemplates[safe: index] {
            EditTemplate(
                template: currentTemplate,
                originalTemplate: currentTemplate,
                useDateOnly: ctx.userData.settings.useDateOnly,
                checkDuplicate: { templateName in
                    return ctx.userData.workoutPlans.userTemplates.contains(where: { $0.name == templateName })
                },
                onDelete: {
                    ctx.userData.deleteUserTemplate(at: index)
                },
                onUpdateTemplate: { updatedTemplate in
                    if let updatedTemplate = updatedTemplate {
                        ctx.userData.updateTemplate(template: updatedTemplate)
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
        return WorkoutTemplate.uniqueTemplateName(initialName: "New Template", from: ctx.userData.workoutPlans.userTemplates)
    }
}
