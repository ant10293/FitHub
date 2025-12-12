//
//  TemplateRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/5/25.
//

import SwiftUI

struct TemplateRow: View {
    let template: WorkoutTemplate
    let index: Int
    let location: TemplateLocation
    let mode: NavigationMode
    let disabled: Bool
    let hideEditButton: Bool
    let onSelect: (SelectedTemplate) -> Void
    let onEdit: (SelectedTemplate) -> Void

    init(
        template: WorkoutTemplate,
        index: Int,
        location: TemplateLocation,
        mode: NavigationMode = .popupOverlay,
        disabled: Bool = false,
        hideEditButton: Bool = false,
        onSelect: @escaping (SelectedTemplate) -> Void,
        onEdit: @escaping (SelectedTemplate) -> Void = { _ in }
    ) {
        self.template = template
        self.index = index
        self.location = location
        self.mode = mode
        self.disabled = disabled
        self.hideEditButton = hideEditButton
        self.onSelect = onSelect
        self.onEdit = onEdit
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
            // Main button action area
            Button(action: { onSelect(selectedTemplate) } ) {
                TemplateLabel(template: template)
                .contentShape(Rectangle()) // Make the entire area tappable
            }
            .buttonStyle(PlainButtonStyle())

            if location != .trainer && !hideEditButton {
                // Dedicated button for rename/delete actions
                Button(action: { onEdit(selectedTemplate) } ) {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .disabled(disabled)
    }

    private var selectedTemplate: SelectedTemplate {
        .init(template: template, location: location, mode: mode)
    }
}

struct TemplateLabel: View {
    let template: WorkoutTemplate

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(template.name)
                    .foregroundStyle(Color.primary) // Ensure the text color remains unchanged
                Text(SplitCategory.concatenateCategories(for: template.categories))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .centerVertically()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure the button takes full width and aligns content to the left
    }
}
