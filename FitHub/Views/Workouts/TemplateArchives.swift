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
    @State private var showingActionOverlay: Bool = false

    var body: some View {
        TemplateNavigator(
            userData: userData,
            selectedTemplate: $selectedTemplate,
            navigationMode: .directToDetail
        ) {
            ZStack {
                if !userData.workoutPlans.archivedTemplates.isEmpty {
                    List {
                        templatesSection(templates: userData.workoutPlans.archivedTemplates)
                    }
                } else {
                    EmptyTemplatesState
                }
            }
            .overlay(content: {
                if let selected = selectedTemplate {
                    showingActionOverlay ? actionOverlay(selected: selected) : nil
                }
            })
            .navigationBarTitle("Manage Templates", displayMode: .inline)
        }
    }
    
    private func templatesSection(templates: [WorkoutTemplate]) -> some View {
        Section {
            ForEach(templates.indices, id: \.self) { index in
                templateButton(for: index, template: templates[index])
            }
        } header: {
            Text("Archived Templates")
        }
    }
    
    private func templateButton(for index: Int, template: WorkoutTemplate) -> some View {
        TemplateRow(
            template: template,
            index: index,
            userTemplate: true,
            disabled: showingActionOverlay,
            hideEditButton: true,
            onSelect: { newSelection in
                selectedTemplate = newSelection
            }
        )
    }
    
    private func actionOverlay(selected: SelectedTemplate) -> some View {
        VStack {
            Text("Template Actions")
                .font(.title2)
            
            Text("Selected: ") +
            Text("\(selected.name)")
                .foregroundStyle(Color.secondary)
                .italic()

            Button("Unarchive", systemImage: "tray.full") {
               moveTemplateBack(selected: selected)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.green)
            .tint(.green)
            .padding(.top)

            HStack {
                Button("Delete", systemImage: "trash.fill") {
                    deleteTemplate(selected: selected)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
                .tint(.red)
                
                Button("Cancel", systemImage: "xmark") {
                    showingActionOverlay = false
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.gray)
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
        template.name = WorkoutTemplate.uniqueTemplateName(initialName: template.name, from: userData.workoutPlans.userTemplates)
        userData.addUserTemplate(template: template)
        showingActionOverlay = false
    }

    private func deleteTemplate(selected: SelectedTemplate) {
        userData.deleteUserTemplate(at: selected.index)
        showingActionOverlay = false
    }
    
    // MARK: – Empty state
    private var EmptyTemplatesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .symbolRenderingMode(.hierarchical)
                .font(.system(.largeTitle, weight: .regular))
                .foregroundStyle(.secondary)

            Text("Nothing Archived Yet")
                .font(.title3.weight(.semibold))

            Text("When you **archive** a workout template it will be stored here for safekeeping.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
