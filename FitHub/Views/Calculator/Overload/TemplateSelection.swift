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
        workoutList()
        .navigationDestination(isPresented: $navigateToOverload) {
            if let sel = selectedTemplate, let tpl = resolveTemplate(sel) {
                OverloadCalculator(template: tpl)
            }
        }
        .navigationBarTitle("Select Template", displayMode: .inline)
    }
    
    private func workoutList() -> some View {
        List {
            if userTemplates.isEmpty && trainerTemplates.isEmpty {
                Text("No templates found. Create your own or generate them in the trainer tab.")
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
            } else {
                if !userTemplates.isEmpty {
                    templatesSection(templates: userTemplates, userTemplates: true)
                }
                if !trainerTemplates.isEmpty {
                    templatesSection(templates: trainerTemplates, userTemplates: false)
                }
            }
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate], userTemplates: Bool) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, userTemplate: userTemplates)
            }
        } header: {
            Text(userTemplates ? "Your Templates" : "Trainer Templates")
        }
    }
    
    private func templateButton(for index: Int, userTemplate: Bool) -> some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
            // Main button action area
            Button(action: {
                let template = userTemplate ? userTemplates[index] : trainerTemplates[index]
                selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: userTemplate)
                navigateToOverload = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(userTemplate ? userTemplates[index].name : trainerTemplates[index].name)
                            .foregroundStyle(Color.primary) // Ensure the text color remains unchanged
                        Text(SplitCategory.concatenateCategories(for: userTemplate ? userTemplates[index].categories : trainerTemplates[index].categories))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .centerVertically()
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure the button takes full width and aligns content to the left
                .contentShape(Rectangle()) // Make the entire area tappable
            }
            .buttonStyle(PlainButtonStyle())
        }
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
