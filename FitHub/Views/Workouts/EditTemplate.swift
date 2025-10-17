//
//  EditTemplate.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EditTemplate: View {
    @Environment(\.dismiss) private var dismiss
    @State var template: WorkoutTemplate
    let originalTemplate: WorkoutTemplate
    let useDateOnly: Bool
    let checkDuplicate: (String) -> Bool
    let onDelete: () -> Void
    let onUpdateTemplate: (WorkoutTemplate?) -> Void
    let onArchiveTemplate: (WorkoutTemplate?) -> Void

    var body: some View {
        TemplateEditor(
            template: $template,
            mode: .edit,
            originalName: originalTemplate.name,
            useDateOnly: useDateOnly,
            checkDuplicate: checkDuplicate,
            onSubmit: { updated in
                onUpdateTemplate(updated)
                dismiss()
            },
            onDelete: { onDelete(); dismiss() },
            onArchive: { updated in
                onArchiveTemplate(updated)
                dismiss()
            },
            onCancel: { dismiss() }
        )
    }
}
