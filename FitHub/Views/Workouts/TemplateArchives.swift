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
    @State private var navigateToDetail: Bool = false
    @State private var showingActionOverlay: Bool = false
    @State private var selectedTemplate: SelectedTemplate?

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
    
    // MARK: – List / empty‑state wrapper
    private func workoutList() -> some View {
        ZStack {
            if !userData.workoutPlans.archivedTemplates.isEmpty {
                List {
                    templatesSection(templates: userData.workoutPlans.archivedTemplates)
                }
            } else {
                EmptyTemplatesState
            }
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
            hideEditButton: false,
            onSelect: { newSelection in
                selectedTemplate = newSelection
                navigateToDetail = true
            },
            onEdit: { editSelection in
                selectedTemplate = editSelection
                showingActionOverlay = true
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
        userData.deleteArchivedTemplate(at: selected.index)
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
