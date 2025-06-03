//
//  RenameTemplate.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct RenameTemplate: View {
    @EnvironmentObject var userData: UserData
    @Binding var isPresented: Bool
    @Binding var name: String
    var workoutTemplate: WorkoutTemplate
    var onRename: () -> Void
    var onDelete: () -> Void
    //var onSave: (WorkoutTemplate) -> Void
    //var getNewNotifications: () -> [String]
    
    @State private var selectedCategories: [SplitCategory]
    @State private var selectedDate: Date?
    @State private var deletePressed: Bool = false
    @State private var savePressed: Bool = false
    @State private var editing: Bool = false
    @State private var showingCategorySelection = false
    @State private var showDatePicker: Bool
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(
        isPresented: Binding<Bool>,
        name: Binding<String>,
        workoutTemplate: WorkoutTemplate,
        onRename: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        //onSave: @escaping (WorkoutTemplate) -> Void,
        //getNewNotifications: @escaping () -> [String],
        showDatePicker: Bool = false
    ) {
            
        self._isPresented = isPresented
        self._name = name
        self.workoutTemplate = workoutTemplate
        self.onRename = onRename
        self.onDelete = onDelete
        //self.onSave = onSave
        //self.getNewNotifications = getNewNotifications
        self._selectedCategories = State(initialValue: workoutTemplate.categories) // Initialize categories from workoutTemplate
        self._selectedDate = State(initialValue: workoutTemplate.date ?? Date()) // Initialize date from workoutTemplate, use current date if nil
        self._showDatePicker = State(initialValue: workoutTemplate.date != nil)
    }
    
    var isValidName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count >= 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Edit Template")
                .font(.title2)
                .centerHorizontally()
            
            HStack {
                TextField("Enter new name", text: $name) { isEditing in
                    editing = isEditing
                } onCommit: {
                    editing = false
                    if isValidName && !isDuplicateName() {
                        onRename()
                        self.isPresented = false
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isTextFieldFocused)
                .overlay(alignment: .trailing) {
                    if editing {
                        Button(action: {
                            editing = false
                            if isValidName && !isDuplicateName() {
                                onRename()
                                self.isPresented = false
                            }
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.large) // Makes the image larger
                                .foregroundColor(isValidName && !isDuplicateName() ? .green : .gray)
                        }
                        .padding(.trailing, 20)
                        .disabled(!isValidName || isDuplicateName())
                    } else {
                        Button(action: {
                            editing = true
                            isTextFieldFocused = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .imageScale(.large) // Makes the image larger
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 20)
                    }
                }
                if !name.isEmpty {
                    Button(action: {
                        name = ""
                        editing = true
                        isTextFieldFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing)
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(.bottom, -20)
            
            VStack {
                if !isValidName {
                    Text("Please enter a valid name.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                } else if isDuplicateName() {
                    Text("Name already exists. Please enter a different name.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
            }
            .padding(.bottom)
            
            // Category selection
            HStack {
                Text("Categories:").bold()
                    .padding(.leading)
                Button(action: {
                    showingCategorySelection.toggle()
                }) {
                    Text(selectedCategories.isEmpty ? "No Categories Selected" : SplitCategory.concatenateCategories(for: selectedCategories))
                        .foregroundColor(.blue)
                    
                    Image(systemName: showingCategorySelection ? "chevron.down" : "chevron.right")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            }
            .sheet(isPresented: $showingCategorySelection) {
                CategorySelection(selectedCategories: $selectedCategories) { selectedCategories in
                    self.selectedCategories = selectedCategories
                }
            }
            
            // Date selection
            HStack {
                Button(action: {
                    self.showDatePicker.toggle()
                    if showDatePicker {
                        self.selectedDate = Date()
                    } else {
                        self.selectedDate = nil
                    }
                }) {
                    Image(systemName: showDatePicker ? "checkmark.square" : "square")
                        .padding(.leading)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                
                if showDatePicker {
                    Text("Planned Date:")
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { selectedDate ?? Date() },
                            set: { selectedDate = $0 }
                        ),
                        displayedComponents: userData.useDateOnly ? .date : [.date, .hourAndMinute]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.trailing)
                } else {
                    Text("Planned Date:")
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .padding(.trailing)
            
            
            HStack(spacing: 20) {
                Spacer()
                Button("Delete", systemImage: "trash.fill") {
                    deletePressed = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .tint(.red)
                
                
                Button("Cancel", systemImage: "xmark") {
                    self.name = workoutTemplate.name // Restore the original name
                    self.isPresented = false
                }
                .buttonStyle(.bordered)
                .foregroundColor(.gray)
                .tint(.gray)
                
                Spacer()
            }
            .padding()
            
            if showingSaveButton() {
                VStack {
                    Button("Save and Exit", systemImage: "checkmark") {
                        updateTemplate()
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.green)
                    .tint(.green)
                    .centerHorizontally()
                }
                .padding(.bottom)
            }
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
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
    }
    
    private func isDuplicateName() -> Bool {
        return name != workoutTemplate.name && userData.userTemplates.contains(where: { $0.name == name })
    }
    
    private func showingSaveButton() -> Bool {
        return selectedCategories != workoutTemplate.categories || selectedDate != workoutTemplate.date
    }
    
    /*private func updateTemplate() {
        var template = WorkoutTemplate(id: workoutTemplate.id, name: name, exercises: workoutTemplate.exercises, categories: selectedCategories, dayIndex: nil, date: selectedDate)
        if workoutTemplate.date != template.date {
            // call the closure, grab the IDs
            let notificationIDs = getNewNotifications()
            template.notificationIDs = notificationIDs
        }
        // pass the template to be saved
        if template != workoutTemplate {
            onSave(template)
        }
    }*/
    
    private func updateTemplate() {
        // Find the index of the workoutTemplate in the userData's templates
        if let index = userData.userTemplates.firstIndex(where: { $0.id == workoutTemplate.id }) {
            // Get the template from the array (mutable copy)
            var updatedTemplate = userData.userTemplates[index]
            // Update the categories and date of the template
            updatedTemplate.categories = selectedCategories
            
            if selectedDate != nil {
                updatedTemplate.date = selectedDate
                
                // Remove existing notifications for the template
                userData.removeNotifications(for: updatedTemplate)
                
                // Schedule new notifications and get the IDs
                let notificationIDs = userData.scheduleNotification(for: updatedTemplate)
                
                // Store the new notification IDs in the template
                updatedTemplate.notificationIDs = notificationIDs
            }
            
            // Update the template in the userData's array with the modified template
            userData.userTemplates[index] = updatedTemplate
            
            // Save the changes to disk or file
            userData.saveSingleVariableToFile(\.userTemplates, for: .userTemplates)
        }
    }
}
