//
//  TemplateNavigator.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/3/25.
//

import SwiftUI

struct TemplateNavigator<Content: View>: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedTemplate: SelectedTemplate?
    @State private var navigateToTemplateDetail: Bool = false
    @State private var navigateToStartedWorkout: Bool = false
    @State private var activeWorkout: WorkoutInProgress?
    @State private var currentTemplate: SelectedTemplate? = nil
    
    let usePopupOverlay: Bool
    let content: () -> Content
    
    init(
        selectedTemplate: Binding<SelectedTemplate?>,
        usePopupOverlay: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._selectedTemplate = selectedTemplate
        self.usePopupOverlay = usePopupOverlay
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .navigationDestination(isPresented: $navigateToTemplateDetail) {
                    templateDetailView
                }
                .navigationDestination(isPresented: $navigateToStartedWorkout) {
                    startedWorkoutView
                }
                .overlay(usePopupOverlay ? templatePopupOverlay : nil)
        }
        .onAppear {
            // Set active workout if one exists (only for WorkoutsView context)
            if let activeWorkout = ctx.userData.sessionTracking.activeWorkout {
                self.activeWorkout = activeWorkout
            }
        }
        .onChange(of: selectedTemplate) { oldValue, newValue in
            // Store the current template for navigation
            if let newValue = newValue {
                currentTemplate = newValue
            }
            
            // For direct navigation views (not popup), automatically navigate when template is selected
            if !usePopupOverlay, newValue != nil {
                navigateToTemplateDetail = true
            }
        }
    }
    
    // MARK: - Navigation Destinations
    
    @ViewBuilder
    private var templateDetailView: some View {
        if let template = currentTemplate {
            if template.isUserTemplate, ctx.userData.workoutPlans.userTemplates.indices.contains(template.index) {
                TemplateDetail(
                    template: $ctx.userData.workoutPlans.userTemplates[template.index], 
                    onDone: { 
                        navigateToTemplateDetail = false 
                        currentTemplate = nil
                        selectedTemplate = nil
                    }
                )
            } else if !template.isUserTemplate, ctx.userData.workoutPlans.trainerTemplates.indices.contains(template.index) {
                TemplateDetail(
                    template: $ctx.userData.workoutPlans.trainerTemplates[template.index], 
                    onDone: { 
                        navigateToTemplateDetail = false 
                        currentTemplate = nil
                        selectedTemplate = nil
                    }
                )
            } else {
                // Fallback for invalid template
                VStack {
                    Text("Template not found")
                        .font(.title2)
                    Button("Go Back") {
                        navigateToTemplateDetail = false
                        currentTemplate = nil
                        selectedTemplate = nil
                    }
                }
                .navigationTitle("Error")
            }
        } else {
            // Fallback view if no template is selected
            VStack {
                Text("No template selected")
                    .font(.title2)
                Button("Go Back") {
                    navigateToTemplateDetail = false
                    currentTemplate = nil
                    selectedTemplate = nil
                }
            }
            .navigationTitle("Template Detail")
        }
    }
    
    @ViewBuilder
    private var startedWorkoutView: some View {
        if let template = currentTemplate {
            if template.isUserTemplate, ctx.userData.workoutPlans.userTemplates.indices.contains(template.index) {
                StartedWorkoutView(
                    viewModel: WorkoutVM(
                        template: ctx.userData.workoutPlans.userTemplates[template.index], 
                        activeWorkout: activeWorkout
                    ), 
                    onExit: {
                        resetWorkoutState()
                        navigateToStartedWorkout = false
                        currentTemplate = nil
                        selectedTemplate = nil
                    }
                )
            } else if !template.isUserTemplate, ctx.userData.workoutPlans.trainerTemplates.indices.contains(template.index) {
                StartedWorkoutView(
                    viewModel: WorkoutVM(
                        template: ctx.userData.workoutPlans.trainerTemplates[template.index], 
                        activeWorkout: activeWorkout
                    ), 
                    onExit: {
                        resetWorkoutState()
                        navigateToStartedWorkout = false
                        currentTemplate = nil
                        selectedTemplate = nil
                    }
                )
            } else {
                // Fallback for invalid template
                VStack {
                    Text("Template not found")
                        .font(.title2)
                    Button("Go Back") {
                        navigateToStartedWorkout = false
                        currentTemplate = nil
                        selectedTemplate = nil
                    }
                }
                .navigationTitle("Error")
            }
        } else {
            // Fallback view if no template is selected
            VStack {
                Text("No template selected")
                    .font(.title2)
                Button("Go Back") {
                    navigateToStartedWorkout = false
                    currentTemplate = nil
                    selectedTemplate = nil
                }
            }
            .navigationTitle("Workout")
        }
    }
    
    // MARK: - Popup Overlay
    
    @ViewBuilder
    private var templatePopupOverlay: some View {
        if let template = selectedTemplate {
            TemplatePopup(
                userData: ctx.userData, 
                template: template.isUserTemplate ? 
                    $ctx.userData.workoutPlans.userTemplates[template.index] : 
                    $ctx.userData.workoutPlans.trainerTemplates[template.index],
                onClose: {
                    selectedTemplate = nil
                }, 
                onBeginWorkout: {
                    currentTemplate = template
                    navigateToStartedWorkout = true
                    selectedTemplate = nil
                }, 
                onEdit: {
                    currentTemplate = template
                    navigateToTemplateDetail = true
                    selectedTemplate = nil
                }
            )
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.5)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .transition(.scale)
        }
    }
    
    // MARK: - Public Methods
    
    func setActiveWorkout(_ workout: WorkoutInProgress?) {
        activeWorkout = workout
    }
    
    private func resetWorkoutState() {
        activeWorkout = nil
    }
}
