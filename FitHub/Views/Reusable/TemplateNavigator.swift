//
//  TemplateNavigator.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/3/25.
//

import SwiftUI

enum NavigationMode {
    case popupOverlay, directToDetail, directToWorkout, mixed
}

struct TemplateNavigator<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var userData: UserData
    
    @Binding var selectedTemplate: SelectedTemplate?
    @State private var navigateToTemplateDetail: Bool = false
    @State private var navigateToStartedWorkout: Bool = false
    @State private var currentTemplate: SelectedTemplate? = nil
    
    let navigationMode: NavigationMode
    let skipPopupForResume: Bool
    let onTemplateEditingComplete: (() -> Void)?
    let content: () -> Content
    
    init(
        userData: UserData,
        selectedTemplate: Binding<SelectedTemplate?>,
        navigationMode: NavigationMode = .popupOverlay,
        skipPopupForResume: Bool = false,
        onTemplateEditingComplete: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.userData = userData
        self._selectedTemplate = selectedTemplate
        self.navigationMode = navigationMode
        self.skipPopupForResume = skipPopupForResume
        self.onTemplateEditingComplete = onTemplateEditingComplete
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .disabled(shouldDisableContent)
                .navigationDestination(isPresented: $navigateToTemplateDetail) { templateDetailView }
                .navigationDestination(isPresented: $navigateToStartedWorkout) { startedWorkoutView }
            
            // Popup overlay with proper centering
            if shouldShowPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        selectedTemplate = nil
                    }
                
                templatePopupOverlay
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
        }
        .onChange(of: selectedTemplate) { oldValue, newValue in
            handleTemplateSelection(newValue)
        }
    }
    
    // MARK: - Template Selection Logic
    
    private func handleTemplateSelection(_ template: SelectedTemplate?) {
        guard let template = template else { return }
        
        // Store the current template for navigation
        currentTemplate = template
        
        // Check if we should skip popup for resume workout
        if skipPopupForResume && userData.sessionTracking.activeWorkout != nil {
            navigateToStartedWorkout = true
            return
        }
        
        // Handle different navigation modes
        switch navigationMode {
        case .popupOverlay: break
        case .directToDetail: navigateToTemplateDetail = true
        case .directToWorkout: navigateToStartedWorkout = true
        case .mixed: 
            // For mixed mode, show popup for template selection from WeekView
            // Direct navigation will be handled by the parent view
            break
        }
    }
    
    private var shouldShowPopup: Bool {
        return (navigationMode == .popupOverlay || navigationMode == .mixed) && selectedTemplate != nil
    }
    
    private var shouldDisableContent: Bool {
        return shouldShowPopup
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
        if let sel = currentTemplate, let binding = templateBinding(for: sel) {
            TemplateDetail(
                template: binding,
                onDone: {
                    navigateToTemplateDetail = false
                    currentTemplate = nil
                    selectedTemplate = nil
                    onTemplateEditingComplete?()
                }
            )
        }
    }

    @ViewBuilder
    private var startedWorkoutView: some View {
        if let sel = currentTemplate, let tpl = templateBinding(for: sel)?.wrappedValue {
            StartedWorkoutView(
                viewModel: WorkoutVM(template: tpl, activeWorkout: userData.sessionTracking.activeWorkout),
                onExit: {
                    navigateToStartedWorkout = false
                    currentTemplate = nil
                    selectedTemplate = nil
                }
            )
        }
    }
    
    // MARK: - Popup Overlay
    
    @ViewBuilder
    private var templatePopupOverlay: some View {
        if let template = selectedTemplate, let tpl = templateBinding(for: template)?.wrappedValue {
            VStack {
                Spacer()
                
                TemplatePopup(
                    userData: userData,
                    template: tpl,
                    onClose: {
                        selectedTemplate = nil
                    }, 
                    onBeginWorkout: {
                        currentTemplate = template
                        navigateToStartedWorkout = true
                    },
                    onEdit: {
                        currentTemplate = template
                        navigateToTemplateDetail = true
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.5)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .transition(.scale)
                
                Spacer()
            }
        }
    }
}
