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
    let userTemplates: [WorkoutTemplate]
    let trainerTemplates: [WorkoutTemplate]

    var body: some View {
        workoutList
            .navigationDestination(isPresented: $navigateToOverload) {
                if let sel = selectedTemplate, let tpl = allTemplates.first(where: { $0.id == sel.template.id }) {
                    OverloadCalculator(template: tpl)
                } else {
                    // template got deleted while we were on the detail screen → pop
                    Color.clear.onAppear { selectedTemplate = nil; navigateToOverload = false }
                }
            }
            .navigationBarTitle("Select Template", displayMode: .inline)
    }

    private var allTemplates: [WorkoutTemplate] { userTemplates + trainerTemplates }

    @ViewBuilder private var workoutList: some View {
        if userTemplates.isEmpty && trainerTemplates.isEmpty {
            EmptyState(
                systemName: "nosign",
                title: "No workouts created yet...",
                subtitle: "Create a workout in the 'Workouts' tab or generate them in the 'Trainer' tab to get started!"
            )
        } else {
            List {
                if userTemplates.isEmpty && trainerTemplates.isEmpty {
                    Text("No templates found. Create your own or generate them in the trainer tab.")
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                } else {
                    if !trainerTemplates.isEmpty {
                        templatesSection(templates: trainerTemplates, location: .trainer)
                    }
                    if !userTemplates.isEmpty {
                        templatesSection(templates: userTemplates, location: .user)
                    }
                }
            }
        }
    }

    private func templatesSection(templates: [WorkoutTemplate], location: TemplateLocation) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, location: location, template: templates[index])
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
            hideEditButton: true,
            onSelect: { newSelection in
                selectedTemplate = newSelection
                navigateToOverload = true
            }
        )
    }
}
