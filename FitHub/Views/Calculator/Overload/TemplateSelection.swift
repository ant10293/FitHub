//
//  TemplateSelection.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/19/25.
//

import SwiftUI

struct TemplateSelection: View {
    @State private var selectedTemplate: SelectedTemplate?
    @State private var navigateToOverload: Bool = false
    var userTemplates: [WorkoutTemplate]
    var trainerTemplates: [WorkoutTemplate]
    
    var body: some View {
        workoutList
        .navigationDestination(isPresented: $navigateToOverload) {
            if let sel = selectedTemplate, let tpl = resolveTemplate(sel) {
                OverloadCalculator(template: tpl)
            }
        }
        .navigationBarTitle("Select Template", displayMode: .inline)
    }
    
    private var workoutList: some View {
        List {
            if userTemplates.isEmpty && trainerTemplates.isEmpty {
                Text("No templates found. Create your own or generate them in the trainer tab.")
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
            } else {
                if !trainerTemplates.isEmpty {
                    templatesSection(templates: trainerTemplates, userTemplates: false)
                }
                if !userTemplates.isEmpty {
                    templatesSection(templates: userTemplates, userTemplates: true)
                }
            }
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate], userTemplates: Bool) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, userTemplate: userTemplates, template: templates[index])
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
            hideEditButton: true,
            onSelect: { newSelection in
                selectedTemplate = newSelection
                navigateToOverload = true
            }
        )
    }
    
    private func resolveTemplate(_ sel: SelectedTemplate) -> WorkoutTemplate? {
        if sel.isUserTemplate {
            guard userTemplates.indices.contains(sel.index) else { return nil }
            return userTemplates[sel.index]
        } else {
            guard trainerTemplates.indices.contains(sel.index) else { return nil }
            return trainerTemplates[sel.index]
        }
    }
}
