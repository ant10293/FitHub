//
//  NewTemplate.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct NewTemplate: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @State private var templateName: String = "New Template"
    @State private var selectedCategories: [SplitCategory] = []
    @State private var showingCategorySelection: Bool = false
    @State private var isKeyboardVisible: Bool = false
    @State private var templateCreated: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var selectedDate: Date?
    var onCreate: (String, [SplitCategory], Date?) -> Void

    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Enter Template Name")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top)
                    .padding(.leading, -160)
                    .padding(.bottom, -10)
                
                HStack {
                    TextField("Enter Template Name", text: $templateName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(alignment: .trailing) {
                            if !templateName.isEmpty {
                                Button(action: {
                                    templateName = ""
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
                
                if !templateCreated {
                    if isDuplicateName() {
                        Text("Name already exists. Please enter a different name.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(alignment: .leading)
                    } else if !isValidName() && !templateName.isEmpty {
                        Text("Invalid Name. Please remove any symbols or whitespaces.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(alignment: .leading)
                    }
                }
                
                HStack {
                    Text("Categories:")
                        .padding(.leading, -30)
                    Button(action: {
                        hideKeyboard()
                        showingCategorySelection.toggle()
                    }) {
                        Text(selectedCategories.isEmpty ? "No Categories Selected" : SplitCategory.concatenateCategories(for: selectedCategories))
                            .foregroundColor(.blue)
                        
                        Image(systemName: showingCategorySelection ? "chevron.down" : "chevron.right")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                    }
                }
                
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
                            .foregroundColor(showDatePicker ? .white : .gray)
                            .padding(.leading)
                        // .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
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
                .padding(.vertical)
                
                .sheet(isPresented: $showingCategorySelection) {
                    CategorySelection(selectedCategories: $selectedCategories) { selectedCategories in
                        self.selectedCategories = selectedCategories
                    }
                }
                
                if !isKeyboardVisible {
                    HStack {
                        Button(action: {
                            templateCreated = true
                            onCreate(templateName, selectedCategories, selectedDate)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Create Template")
                                .centerHorizontally()
                                .foregroundColor(.white)
                                .padding()
                                .background(!isInputValid() ? Color.gray : Color.blue)
                            
                                .cornerRadius(8)
                                .frame(width: 350, height: 60) // Set desired width and height
                        }
                        .disabled(!isInputValid())
                        .contentShape(Rectangle())
                        .centerHorizontally()
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("New Template")
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear(perform: removeKeyboardObservers)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                templateName = getUniqueTemplateName(initialName: "New Template")
            }
        }
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func isInputValid() -> Bool {
        if (templateName.isEmpty || !isValidName() || isDuplicateName()) {
            return false
        }
        else {
            return true
        }
    }
    
    private func isDuplicateName() -> Bool {
        return userData.userTemplates.contains(where: { $0.name == templateName })
    }
    
    private func isValidName() -> Bool {
        // Check if the name is empty or contains only whitespace
        guard !templateName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        // Define a character set of valid characters (letters, numbers, spaces)
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ")
        
        // Check if the name contains only allowed characters
        return templateName.rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }
    
    private func getUniqueTemplateName(initialName: String = "New Template") -> String {
        var name = initialName
        var index = 1
        while userData.userTemplates.contains(where: { $0.name == name }) {
            index += 1
            name = "\(initialName) \(index)"
        }
        return name
    }
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
}
