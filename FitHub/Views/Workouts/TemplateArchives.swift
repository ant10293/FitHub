//
//  TemplateArchives.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/17/25.
//

import SwiftUI

struct TemplateArchives: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var userData: UserData
    @State private var selectedTemplate: SelectedTemplate?
    @State private var navigateToDetail: Bool = false
    @State private var showingActionOverlay: Bool = false

    var body: some View {
        workoutList()
        .navigationDestination(isPresented: $navigateToDetail) {
            if let selectedTemplate = selectedTemplate {
                if userData.workoutPlans.archivedTemplates.indices.contains(selectedTemplate.index) {
                    TemplateDetail(template: $userData.workoutPlans.archivedTemplates[selectedTemplate.index], onDone: {
                        navigateToDetail = false
                    })
                }
            }
        }
        .overlay(content: {
            if let selected = selectedTemplate {
                showingActionOverlay ? actionOverlay(selected: selected) : nil
            }
        })
        .navigationBarTitle("Manage Templates", displayMode: .inline)
    }
    
    private func workoutList() -> some View {
        List {
            if userData.workoutPlans.archivedTemplates.isEmpty {
                Text("No templates found.")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                templatesSection(templates: userData.workoutPlans.archivedTemplates)
            }
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate]) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index)
            }
        } header: {
            Text("Archived Templates")
        }
    }
    
    private func templateButton(for index: Int) -> some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
            // Main button action area
            Button(action: {
                let template = userData.workoutPlans.archivedTemplates[index]
                selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: true)
                navigateToDetail = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(userData.workoutPlans.archivedTemplates[index].name)
                            .foregroundColor(.primary) // Ensure the text color remains unchanged
                        Text(SplitCategory.concatenateCategories(for: userData.workoutPlans.archivedTemplates[index].categories))
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
            
            Button(action: {
                let template = userData.workoutPlans.archivedTemplates[index]
                selectedTemplate = SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: true)
                showingActionOverlay = true
            }) {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(showingActionOverlay)
        }
    }
    
    private func actionOverlay(selected: SelectedTemplate) -> some View {
        VStack {
            Text("Template Actions")
                .font(.title2)
            
            Text("Selected: ") +
            Text("\(selected.name)")
                .foregroundStyle(.secondary)
                .italic()

            Button("Unarchive", systemImage: "tray.full") {
               moveTemplateBack(selected: selected)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.green)
            .tint(.green)
            .padding(.top)

            HStack {
                Button("Delete", systemImage: "trash.fill") {
                    deleteTemplate(selected: selected)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .tint(.red)
                
                Button("Cancel", systemImage: "xmark") {
                    showingActionOverlay = false
                }
                .buttonStyle(.bordered)
                .foregroundColor(.gray)
                .tint(.gray)
            }
            .padding()
        }
        .padding()
        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 10)
        .padding()
    }
    
    private func moveTemplateBack(selected: SelectedTemplate) {
        var template = userData.workoutPlans.archivedTemplates.remove(at: selected.index)
        template.name = userData.uniqueTemplateName(initialName: template.name, from: userData.workoutPlans.userTemplates)
        userData.addUserTemplate(template: template)
        showingActionOverlay = false
    }

    private func deleteTemplate(selected: SelectedTemplate) {
        userData.deleteUserTemplate(at: selected.index)
        showingActionOverlay = false
    }
}
