//
//  EditTemplate.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EditTemplate: View {
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    @Binding var isPresented: Bool
    @State private var deletePressed: Bool = false
    @State private var editing: Bool = false
    @State private var showingCategorySelection: Bool = false
    @State var showDatePicker: Bool
    @State var template: WorkoutTemplate
    let originalTemplate: WorkoutTemplate
    let gender: Gender
    let useDateOnly: Bool
    let checkDuplicate: (String) -> Bool
    var onDelete: () -> Void
    var onUpdateTemplate: (WorkoutTemplate?) -> Void
    var onArchiveTemplate: (WorkoutTemplate?) -> Void
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Edit Template")
                .font(.title2)
                .centerHorizontally()
            
            nameTextField
            categorySelection
            dateSelection
            buttonSection
        }
        .alert(isPresented: $deletePressed) {
            Alert(
                title: Text("Are you sure you want to delete this Template?"),
                message: Text("This action cannot be undone."),
                primaryButton: .default(Text("Cancel")) {
                    deletePressed = false
                },
                secondaryButton: .default(Text("Delete")) {
                    onDelete()
                    isPresented = false
                }
            )
        }
        .padding()
        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 10)
        .padding()
    }
    
    private var nameError: String? {
        if !InputLimiter.isValidInput(template.name) {
            return "Please enter a valid name."
        } else if isDuplicateName() {
            return "Name already exists. Please enter a different name."
        }
        return nil
    }
    
    private func isDuplicateName() -> Bool {
        return originalTemplate.name != template.name && checkDuplicate(template.name)
    }
    
    private var nameTextField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TextField("Enter new name", text: $template.name) { isEditing in
                    editing = isEditing
                } onCommit: {
                    editing = false
                    if InputLimiter.isValidInput(template.name) && !isDuplicateName() {
                        onUpdateTemplate(template)
                        self.isPresented = false
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4) // Background shape
                        .fill(colorScheme == .dark ? Color.black : Color(UIColor.secondarySystemBackground))
                )
                .focused($isTextFieldFocused)
                .overlay(alignment: .trailing) {
                    if editing {
                        Button(action: {
                            editing = false
                            if InputLimiter.isValidInput(template.name) && !isDuplicateName() {
                                onUpdateTemplate(template)
                                self.isPresented = false
                            }
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.large) // Makes the image larger
                                .foregroundColor(InputLimiter.isValidInput(template.name) && !isDuplicateName() ? .green : .gray)
                        }
                        .padding(.trailing, 10)
                        .disabled(!InputLimiter.isValidInput(template.name) || isDuplicateName())
                    } else {
                        Button(action: {
                            editing = true
                            isTextFieldFocused = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .imageScale(.large) // Makes the image larger
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 10)
                    }
                }
                .padding()
                
                Button(action: {
                    template.name = ""
                    editing = true
                    isTextFieldFocused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing)
                        .contentShape(Rectangle())
                        .disabled(template.name.isEmpty)
                }
            }
            if let error = nameError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, -5)
                    .padding(.bottom)
                    .padding(.leading)
            }
        }
    }
    
    private var categorySelection: some View {
        // Category selection
        HStack {
            Text("Categories:").padding(.leading)
            Button(action: { showingCategorySelection.toggle() }) {
                Text(template.categories.isEmpty ? "No Categories Selected" : SplitCategory.concatenateCategories(for: template.categories))
                    .foregroundColor(.blue)
                
                Image(systemName: showingCategorySelection ? "chevron.down" : "chevron.right")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }
        }
        .sheet(isPresented: $showingCategorySelection) {
            CategorySelection(initial: template.categories, gender: gender, onSave: { selectedCategories in
                template.categories = selectedCategories
            })
        }
    }
    
    private var dateSelection: some View {
        VStack {
            HStack {
                Group {
                    Button(action: {
                        showDatePicker.toggle()
                        if showDatePicker {
                            template.date = Date()
                        } else {
                            template.date = nil
                        }
                    }) {
                        Image(systemName: showDatePicker ? "checkmark.square" : "square")
                            .padding(.leading)
                        Text("Planned Date:")
                    }
                    
                    Spacer()
                }
                .foregroundColor(showDatePicker ? .primary : .secondary)
            }

            if showDatePicker {
                DatePicker("", selection: Binding(get: { template.date ?? Date() }, set: { template.date = $0 }),
                           displayedComponents: useDateOnly ? .date : [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
            }
        }
        .padding(.trailing)
    }
    
    @ViewBuilder private var buttonSection: some View {
        HStack(spacing: 20) {
            Spacer()
            Button("Delete", systemImage: "trash.fill") {
                deletePressed = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .tint(.red)
            
            Button(" Done ", systemImage: "checkmark") {
                onUpdateTemplate(template)
                isPresented = false
            }
            .buttonStyle(.bordered)
            .foregroundColor(.green)
            .tint(.green)
            
            Spacer()
        }
        .padding()
        
        Button("Archive", systemImage: "archivebox") {
            onArchiveTemplate(template)
            isPresented = false
        }
        .buttonStyle(.bordered)
        .foregroundColor(.blue)
        .tint(.blue)
        .padding(.bottom)
        .centerHorizontally()
    }
}

