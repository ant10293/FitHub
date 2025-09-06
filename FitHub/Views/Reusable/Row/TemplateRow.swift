//
//  TemplateRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/5/25.
//

import SwiftUI

struct TemplateRow: View {
    var template: WorkoutTemplate
    var index: Int
    var userTemplate: Bool
    var disabled: Bool = false
    var hideEditButton: Bool = false
    var onSelect: (SelectedTemplate) -> Void
    var onEdit: ((SelectedTemplate) -> Void) = { _ in }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
            // Main button action area
            Button(action: { onSelect(selectedTemplate) } ) {
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
                .contentShape(Rectangle()) // Make the entire area tappable
            }
            .buttonStyle(PlainButtonStyle())
            
            if userTemplate && !hideEditButton {
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
        SelectedTemplate(id: template.id, name: template.name, index: index, isUserTemplate: userTemplate)
    }
}
