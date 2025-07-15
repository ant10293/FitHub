//
//  NewTemplate.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct NewTemplate: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @StateObject private var kbd = KeyboardManager.shared
    @State private var templateCreated: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showingCategorySelection: Bool = false
    @State var template: WorkoutTemplate
    let gender: Gender
    let useDateOnly: Bool
    let checkDuplicate: (String) -> Bool
    var onCreate: (WorkoutTemplate?) -> Void
    
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
                    ActionButton(
                        title: "Create Template",
                        enabled: isInputValid(),
                        color: isInputValid() ? Color.blue : Color.gray,
                        action: {
                            templateCreated = true
                            let trimmedName = InputLimiter.trimmed(template.name)
                            template.name = trimmedName
                            onCreate(template)
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                    .padding()
                }
                
                Spacer()
                
            }
            .padding()
            .navigationBarTitle("New Template").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .sheet(isPresented: $showingCategorySelection, onDismiss: { showingCategorySelection = false }) {
            CategorySelection(initial: template.categories, newTemplate: true, gender: gender, onSave: { selectedCategories in
                template.categories = selectedCategories
            })
        }
    }
    
    private var nameField: some View {
        HStack {
            TextField("Template Name", text: $template.name)
                .frame(height: UIScreen.main.bounds.height * 0.05)
                .padding(.leading)
                .background(
                    RoundedRectangle(cornerRadius: 4) // Background shape
                        .fill(colorScheme == .dark ? Color.black : Color(UIColor.secondarySystemBackground))
                )
                .overlay(alignment: .trailing) {
                    if !template.name.isEmpty {
                        Button(action: {
                            template.name = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .padding()
        }
    }
    
    private var categoryPicker: some View {
        HStack {
            Text("Categories:")
                .font(.headline)
            
            Button(action: {
                kbd.dismiss()
                showingCategorySelection.toggle()
            }) {
                Text(template.categories.isEmpty ? "No Categories Selected" : SplitCategory.concatenateCategories(for: template.categories))
                Image(systemName: showingCategorySelection ? "chevron.down" : "chevron.right")
            }
            .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder private var datePicker: some View {
        HStack {
            Button {
                toggleDatePicker()
            } label: {
                Label("Planned Date:", systemImage: showDatePicker ? "checkmark.square" : "square")
                    .font(.headline)
            }
            .foregroundColor(showDatePicker ? .primary : .secondary)

            Spacer()
        }

        if showDatePicker {
            DatePicker("", selection: Binding(get: { template.date ?? Date() }, set: { template.date = $0 }),
                       displayedComponents: useDateOnly ? .date : [.date, .hourAndMinute])
            .datePickerStyle(CompactDatePickerStyle())
            .padding(.trailing)
        }
    }
    
    private func toggleDatePicker() {
        showDatePicker.toggle()
        if showDatePicker {
            template.date = Date()
        } else {
            template.date = nil
        }
    }
    
    private var isDuplicateName: Bool { checkDuplicate(InputLimiter.trimmed(template.name)) }
    
    private var nameError: String? {
        if !templateCreated {
            if isDuplicateName {
                return "Name already exists. Please enter a different name."
            } else if !InputLimiter.isValidInput(template.name) && !template.name.isEmpty {
                return "Invalid Name. Please remove any symbols or whitespaces."
                 
            } else if template.name.isEmpty {
                return "Field is required."
            }
        }
        return nil
    }
    
    private func isInputValid() -> Bool {
        if (template.name.isEmpty || !InputLimiter.isValidInput(template.name) || isDuplicateName) {
            return false
        } else {
            return true
        }
    }
}

