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
    let gender: Gender
    let useDateOnly: Bool
    let checkDuplicate: (String) -> Bool
    var onDelete: () -> Void
    var onUpdateTemplate: (WorkoutTemplate?) -> Void
    var onArchiveTemplate: (WorkoutTemplate?) -> Void

    var body: some View {
        TemplateEditor(
            mode: .edit,
            template: $template,
            originalName: originalTemplate.name,
            gender: gender,
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
