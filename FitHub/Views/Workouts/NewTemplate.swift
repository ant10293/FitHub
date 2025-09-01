//
//  NewTemplate.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct NewTemplate: View {
    @Environment(\.dismiss) private var dismiss
    @State var template: WorkoutTemplate
    let gender: Gender
    let useDateOnly: Bool
    let checkDuplicate: (String) -> Bool
    var onCreate: (WorkoutTemplate?) -> Void

    var body: some View {
        TemplateEditor(
            mode: .create,
            template: $template,
            originalName: nil,
            gender: gender,
            useDateOnly: useDateOnly,
            checkDuplicate: checkDuplicate,
            onSubmit: onCreate,
            onCancel: { dismiss() }
        )
    }
}


