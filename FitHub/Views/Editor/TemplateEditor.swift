//
//  TemplateEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/10/25.
//

import SwiftUI


struct TemplateEditor: View {
    enum Mode { case create, edit }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var kbd = KeyboardManager.shared

    // Configuration
    @Binding var template: WorkoutTemplate
    let mode: Mode
    let originalName: String?        // pass originalTemplate.name for edit; nil for create
    let useDateOnly: Bool
    let checkDuplicate: (String) -> Bool

    // Actions
    let onSubmit: (WorkoutTemplate?) -> Void
    let onDelete: (() -> Void)?
    let onArchive: ((WorkoutTemplate?) -> Void)?
    let onCancel: (() -> Void)?   // optional; default uses dismiss()

    // Local state
    @State private var showingCategorySelection: Bool = false
    @State private var submitted: Bool = false

    init(
        template: Binding<WorkoutTemplate>,
        mode: Mode,
        originalName: String?,
        useDateOnly: Bool,
        checkDuplicate: @escaping (String) -> Bool,
        onSubmit: @escaping (WorkoutTemplate?) -> Void,
        onDelete: (() -> Void)? = nil,
        onArchive: ((WorkoutTemplate?) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self._template = template
        self.mode = mode
        self.originalName = originalName
        self.useDateOnly = useDateOnly
        self.checkDuplicate = checkDuplicate
        self.onSubmit = onSubmit
        self.onDelete = onDelete
        self.onArchive = onArchive
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading, spacing: 4) {
                    NameField(title: "Name", placeholder: "Template Name", text: $template.name, error: nameError)

                    categoryPicker
                        .padding(.vertical)

                    datePicker
                        .padding(.bottom)
                }
                .padding(.bottom)

                if !kbd.isVisible {
                    RectangularButton(
                        title: mode == .create ? "Create Template" : "Save Changes",
                        enabled: isInputValid,
                        bgColor: isInputValid ? Color.blue : Color.gray,
                        action: submit
                    )
                    .padding()
                }

                if mode == .edit {
                    // Secondary actions for Edit only
                    HStack(spacing: 12) {
                        if let onDelete {
                            LabelButton(
                                title: "Delete",
                                systemImage: "trash.fill",
                                tint: .red,
                                action: onDelete
                            )
                        }
                        if let onArchive {
                            LabelButton(
                                title: "Archive",
                                systemImage: "archivebox",
                                tint: .blue,
                                action: { onArchive(template) }
                            )
                        }
                    }
                    .padding([.horizontal, .bottom])
                }

                Spacer(minLength: 0)
            }
            .padding()
            .navigationBarTitle(mode == .create ? "New Template" : "Edit Template", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { cancel() }
                        .foregroundStyle(.red)
                }
            }
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .sheet(isPresented: $showingCategorySelection) {
            if mode == .create {
                CategorySelection(initial: template.categories, newTemplate: true) { selected in
                    template.categories = selected
                }
            } else {
                CategorySelection(initial: template.categories) { selected in
                    template.categories = selected
                }
            }
        }
    }
}

// MARK: - Subviews
private extension TemplateEditor {
    var categoryPicker: some View {
        HStack {
            Text("Categories:")
                .font(.headline)

            Button(action: { kbd.dismiss(); showingCategorySelection.toggle() }) {
                Text(template.categories.isEmpty ? "No Categories Selected" : SplitCategory.concatenateCategories(for: template.categories))
                Image(systemName: showingCategorySelection ? "chevron.down" : "chevron.right")
            }
            .foregroundStyle(.blue)
        }
    }
    
    var datePicker: some View {
        OptionalDatePicker(
            initialDate: template.date,
            label: "Planned Date:",
            useDateOnly: useDateOnly
        ) { newDate in
            template.date = newDate
        }
    }

    var trimmedName: String { template.name.trimmed }

    var isDuplicateName: Bool {
        if mode == .create { return checkDuplicate(trimmedName) }
        // edit mode: allow original name
        if let original = originalName, original == trimmedName { return false }
        return checkDuplicate(trimmedName)
    }

    var nameError: String? {
        if !submitted {
            if isDuplicateName { return "Name already exists. Please enter a different name." }
            if template.name.isEmpty { return "Field is required." }
            if !InputLimiter.isValidInput(template.name) { return "Invalid Name. Please remove any symbols or whitespaces." }
        }
        return nil
    }

    var isInputValid: Bool { !trimmedName.isEmpty && InputLimiter.isValidInput(trimmedName) && !isDuplicateName }

    func submit() {
        submitted = true
        guard isInputValid else { return }
        template.name = trimmedName
        onSubmit(template)
        cancel() // match NewTemplate behavior which dismisses after create
    }

    func cancel() { if let onCancel { onCancel() } else { dismiss() } }
}

