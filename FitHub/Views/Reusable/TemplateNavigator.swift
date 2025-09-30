//
//  TemplateNavigator.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/3/25.
//

import SwiftUI

enum NavigationMode {
    case popupOverlay, directToDetail, directToWorkout
}

// Use an identifiable route for workout destinations so dismissal drops the view immediately
private struct WorkoutRoute: Identifiable, Hashable {
    let id: UUID
    let sel: SelectedTemplate
    
    static func == (lhs: WorkoutRoute, rhs: WorkoutRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct TemplateNavigator<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var userData: UserData
    
    @Binding var selectedTemplate: SelectedTemplate?
    @State private var navigateToTemplateDetail: Bool = false
    @State private var currentTemplate: SelectedTemplate? = nil
    
    @State private var workoutRoute: WorkoutRoute? = nil
    
    let content: () -> Content
    
    init(
        userData: UserData,
        selectedTemplate: Binding<SelectedTemplate?>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.userData = userData
        self._selectedTemplate = selectedTemplate
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .disabled(shouldDisableContent)
                .navigationDestination(isPresented: $navigateToTemplateDetail) { templateDetailView }
                .navigationDestination(item: $workoutRoute) { route in
                    startedWorkoutView(route: route)
                }
            
            // Popup overlay with proper centering
            if shouldShowPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    //.onTapGesture { selectedTemplate = nil }
                
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
        
        switch template.mode {
        case .popupOverlay: break
        case .directToDetail: navigateToTemplateDetail = true
        case .directToWorkout:
            workoutRoute = WorkoutRoute(id: UUID(), sel: template)
        }
    }
    
    private var shouldShowPopup: Bool {
        return selectedTemplate?.mode == .popupOverlay && selectedTemplate != nil
    }
    
    private var shouldDisableContent: Bool {
        return shouldShowPopup
    }
    
    // MARK: - Navigation Destinations
    private func templateBinding(for sel: SelectedTemplate) -> Binding<WorkoutTemplate>? {
        switch sel.location {
        case .user:
            let idx = userData.workoutPlans.userTemplates.firstIndex(where: { $0.id == sel.template.id })
            guard let i = idx else { return nil }
            return $userData.workoutPlans.userTemplates[safe: i]
        case .trainer:
            let idx = userData.workoutPlans.trainerTemplates.firstIndex(where: { $0.id == sel.template.id })
            guard let i = idx else { return nil }
            return $userData.workoutPlans.trainerTemplates[safe: i]
        case .archived:
            let idx = userData.workoutPlans.archivedTemplates.firstIndex(where: { $0.id == sel.template.id })
            guard let i = idx else { return nil }
            return $userData.workoutPlans.archivedTemplates[safe: i]
        }
    }
     
    @ViewBuilder
    private var templateDetailView: some View {
        if let sel = currentTemplate, let binding = templateBinding(for: sel) {
            TemplateDetail(
                template: binding,
                isArchived: sel.location == .archived,
                onDone: {
                    navigateToTemplateDetail = false
                    currentTemplate = nil
                    selectedTemplate = nil
                }
            )
        }
    }

    @ViewBuilder
    private func startedWorkoutView(route: WorkoutRoute) -> some View {
        let sel = route.sel
        if let tpl = templateBinding(for: sel)?.wrappedValue {
            StartedWorkoutView(
                viewModel: WorkoutVM(
                    template: tpl,
                    activeWorkout: userData.sessionTracking.activeWorkout,
                    workoutsStartDate: userData.workoutPlans.workoutsStartDate
                ),
                onExit: {
                    workoutRoute = nil
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
                        workoutRoute = WorkoutRoute(id: UUID(), sel: template)
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
