//
//  TemplateNavigator.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/3/25.
//

import SwiftUI

struct TemplateNavigator<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var userData: UserData
    
    @Binding var selectedTemplate: SelectedTemplate?
    @State private var navigateToTemplateDetail: Bool = false
    @State private var navigateToStartedWorkout: Bool = false
    
    let usePopupOverlay: Bool
    let content: () -> Content
    
    init(
        userData: UserData,
        selectedTemplate: Binding<SelectedTemplate?>,
        usePopupOverlay: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.userData = userData
        self._selectedTemplate = selectedTemplate
        self.usePopupOverlay = usePopupOverlay
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .navigationDestination(isPresented: $navigateToTemplateDetail) { templateDetailView }
                .navigationDestination(isPresented: $navigateToStartedWorkout) { startedWorkoutView }
                .overlay(usePopupOverlay ? templatePopupOverlay : nil)
        }
        .onChange(of: selectedTemplate) { oldValue, newValue in
            // For direct navigation views (not popup), automatically navigate when template is selected
            if !usePopupOverlay, newValue != nil {
                navigateToTemplateDetail = true
            }
        }
    }
    
    // MARK: - Navigation Destinations
    private func templateBinding(for sel: SelectedTemplate) -> Binding<WorkoutTemplate>? {
        if sel.isUserTemplate {
            // Prefer re-locating by id (index can drift); fall back to sel.index if still valid.
            let idx = userData.workoutPlans.userTemplates.firstIndex(where: { $0.id == sel.id })
                ?? (userData.workoutPlans.userTemplates.indices.contains(sel.index) ? sel.index : nil)
            guard let i = idx else { return nil }
            return $userData.workoutPlans.userTemplates[i]
        } else {
            let idx = userData.workoutPlans.trainerTemplates.firstIndex(where: { $0.id == sel.id })
                ?? (userData.workoutPlans.trainerTemplates.indices.contains(sel.index) ? sel.index : nil)
            guard let i = idx else { return nil }
            return $userData.workoutPlans.trainerTemplates[i]
        }
    }

    @ViewBuilder
    private var templateDetailView: some View {
        if let sel = selectedTemplate, let binding = templateBinding(for: sel) {
            TemplateDetail(
                template: binding,
                onDone: {
                    navigateToTemplateDetail = false
                    selectedTemplate = nil
                }
            )
        }
    }

    @ViewBuilder
    private var startedWorkoutView: some View {
        if let sel = selectedTemplate, let tpl = templateBinding(for: sel)?.wrappedValue {
            StartedWorkoutView(
                viewModel: WorkoutVM(template: tpl, activeWorkout: userData.sessionTracking.activeWorkout),
                onExit: {
                    navigateToStartedWorkout = false
                    selectedTemplate = nil
                }
            )
        }
    }
    
    // MARK: - Popup Overlay
    
    @ViewBuilder
    private var templatePopupOverlay: some View {
        if let template = selectedTemplate, let tpl = templateBinding(for: template)?.wrappedValue {
            TemplatePopup(
                userData: userData,
                template: tpl,
                onClose: {
                    selectedTemplate = nil
                }, 
                onBeginWorkout: {
                    navigateToStartedWorkout = true
                    selectedTemplate = nil
                }, 
                onEdit: {
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
}
