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
    let mode: Mode
    @Binding var template: WorkoutTemplate
    let originalName: String?        // pass originalTemplate.name for edit; nil for create
    let useDateOnly: Bool
    let checkDuplicate: (String) -> Bool

    // Actions
    var onSubmit: (WorkoutTemplate?) -> Void
    var onDelete: (() -> Void)? = nil
    var onArchive: ((WorkoutTemplate?) -> Void)? = nil
    var onCancel: (() -> Void)? = nil   // optional; default uses dismiss()

    // Local state
    @State private var showingCategorySelection: Bool = false
    @State private var showDatePicker: Bool
    @State private var submitted: Bool = false

    init(
        mode: Mode,
        template: Binding<WorkoutTemplate>,
        originalName: String?,
        useDateOnly: Bool,
        checkDuplicate: @escaping (String) -> Bool,
        onSubmit: @escaping (WorkoutTemplate?) -> Void,
        onDelete: (() -> Void)? = nil,
        onArchive: ((WorkoutTemplate?) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.mode = mode
        self._template = template
        self.originalName = originalName
        self.useDateOnly = useDateOnly
        self.checkDuplicate = checkDuplicate
        self.onSubmit = onSubmit
        self.onDelete = onDelete
        self.onArchive = onArchive
        self.onCancel = onCancel
        // Date picker is visible iff template already has a date
        self._showDatePicker = State(initialValue: template.wrappedValue.date != nil)
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
                        color: isInputValid ? Color.blue : Color.gray,
                        action: submit
                    )
                    .padding()
                }

                if mode == .edit {
                    // Secondary actions for Edit only
                    HStack(spacing: 12) {
                        if let onDelete {
                            Button("Delete", systemImage: "trash.fill", action: onDelete)
                                .buttonStyle(.bordered)
                                .foregroundStyle(.red)
                                .tint(.red)
                        }
                        if let onArchive {
                            Button("Archive", systemImage: "archivebox") { onArchive(template) }
                                .buttonStyle(.bordered)
                                .foregroundStyle(.blue)
                                .tint(.blue)
                        }
                    }
                    .padding(.bottom)
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

    @ViewBuilder var datePicker: some View {
        HStack {
            Button(action: toggleDatePicker) {
                Label("Planned Date:", systemImage: showDatePicker ? "checkmark.square" : "square")
                    .font(.headline)
            }
            .foregroundStyle(showDatePicker ? .primary : .secondary)
            Spacer()
        }
        if showDatePicker {
            DatePicker(
                "",
                selection: Binding(
                    get: { template.date ?? Date() },
                    set: { template.date = $0 }
                ),
                displayedComponents: useDateOnly ? .date : [.date, .hourAndMinute]
            )
            .datePickerStyle(CompactDatePickerStyle())
            .padding(.trailing)
        }
    }
    
    var trimmedName: String { InputLimiter.trimmed(template.name) }

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

    func toggleDatePicker() {
        showDatePicker.toggle()
        if showDatePicker {
            template.date = template.date ?? Date()
        } else {
            template.date = nil
        }
    }

    func cancel() { if let onCancel { onCancel() } else { dismiss() } }
}


