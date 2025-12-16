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
    @State private var showingActionOverlay: Bool = false
    @State private var selectedTemplate: SelectedTemplate?
    @State private var editingTemplate: WorkoutTemplate?

    var body: some View {
        TemplateNavigator(selectedTemplate: $selectedTemplate) {
            workoutList
        }
        .overlay(content: {
            if let template = editingTemplate {
                showingActionOverlay ? actionOverlay(template: template) : nil
            }
        })
        .navigationBarTitle("Manage Templates", displayMode: .inline)
    }

    // MARK: – List / empty‑state wrapper
    private var workoutList: some View {
        ZStack {
            if !userData.workoutPlans.archivedTemplates.isEmpty {
                List {
                    templatesSection(templates: userData.workoutPlans.archivedTemplates)
                }
            } else {
                EmptyState(
                    systemName: "tray",
                    title: "Nothing Archived Yet",
                    subtitle: "When you archive a workout template it will be stored here for safekeeping."
                )
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
            location: .archived,
            mode: .directToDetail,
            disabled: showingActionOverlay,
            hideEditButton: false,
            onSelect: { newSelection in
                selectedTemplate = newSelection
            },
            onEdit: { editSelection in
                editingTemplate = editSelection.template
                showingActionOverlay = true
            }
        )
    }

    private func actionOverlay(template: WorkoutTemplate) -> some View {
        VStack {
            Text("Template Actions")
                .font(.title2)

            Text("Selected: ") +
            Text("\(template.name)")
                .foregroundStyle(Color.secondary)
                .italic()

            LabelButton(
                title: "Unarchive",
                systemImage: "tray.full",
                tint: .green,
                width: .fit,
                action: {
                    moveTemplateBack(template: template)
                }
            )
            .padding(.top)

            HStack {
                LabelButton(
                    title: "Delete",
                    systemImage: "trash.fill",
                    tint: .red,
                    width: .fit,
                    action: {
                        deleteTemplate(template: template)
                    }
                )

                LabelButton(
                    title: "Cancel",
                    systemImage: "xmark",
                    tint: .gray,
                    width: .fit,
                    action: resetEditing
                )
            }
            .padding()
        }
        .padding()
        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 10)
        .padding()
    }

    private func moveTemplateBack(template: WorkoutTemplate) {
        deleteArchived(at: template.id)
        var template = template
        template.name = WorkoutTemplate.uniqueTemplateName(initialName: template.name, from: userData.workoutPlans.userTemplates)
        userData.addUserTemplate(template: template)
        resetEditing()
    }

    private func deleteTemplate(template: WorkoutTemplate) {
        deleteArchived(at: template.id)
        resetEditing()
    }

    private func deleteArchived(at id: UUID) {
        userData.workoutPlans.archivedTemplates.removeAll { $0.id == id }
    }

    private func resetEditing() {
        showingActionOverlay = false
        editingTemplate = nil
    }
}
