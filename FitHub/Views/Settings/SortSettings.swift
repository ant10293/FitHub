//
//  SortSettings.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/19/25.
//

import SwiftUI



struct SortSettings: View {
    // Persisted settings
    @ObservedObject var userData: UserData
    
    
    var body: some View {
        List {
            // ───────── Disable Picker ─────────
            Section {
                // option to disable ExerciseSortOptions picker
                Toggle("Exercise Sort Picker", isOn: $userData.settings.enableSortPicker)
                    .onChange(of: userData.settings.enableSortPicker) {
                        userData.saveSingleStructToFile(\.settings, for: .settings)
                    }
            } footer: {
                Text("When disabled, the Sort picker in the exercise category selection bar is hidden.")
            }
            
            // ───────── Save as Default ─────────
            Section {
                // option to save new selections as default
                Toggle("Save New Selection as Default", isOn: $userData.settings.saveSelectedSort)
                    .onChange(of: userData.settings.saveSelectedSort) {
                        userData.saveSingleStructToFile(\.settings, for: .settings)
                    }
                
                // Only show the default-category picker when NOT saving current selection
                if !userData.settings.saveSelectedSort {
                    // if save new selections is false, show setDefault options
                    // setDefault allows the user to set a category that will always be selected upon viewing exercises
                    Picker("Default Category", selection: $userData.sessionTracking.exerciseSortOption) {
                        ForEach(ExerciseSortOption.allCases.filter { $0 != .templateCategories }, id: \.self) { option in
                            Text(option.rawValue).tag(Optional(option))
                        }
                    }
                    .onChange(of: userData.sessionTracking.exerciseSortOption) { oldValue, newValue in
                        if oldValue != newValue {
                            userData.saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)
                        }
                    }
                }
            } footer: {
                Text(
                    userData.settings.saveSelectedSort
                    ? "Your current sort settings will be remembered and used as the new default."
                    : "Choose a default category that will always be pre-selected when you open the exercise list."
                )
            }
            
            // ───────── Sort by Template Categories ─────────
            Section {
                // option to sort by template categories by default when editing a template with categories
                Toggle("Sort by Template Categories", isOn: $userData.settings.sortByTemplateCategories)
                    .onChange(of: userData.settings.sortByTemplateCategories) {
                        if isDefault {
                            userData.saveSingleStructToFile(\.settings, for: .settings)
                        }
                    }
            } footer: {
                Text("If a workout template has its own category list, enabling this will automatically filter exercises to match those categories.")
            }
            
            // ───────── Visibility Filters ─────────
            Section {
                // ── Hide Unequipped ─────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Hide Unequipped Exercises", isOn: $userData.settings.hideUnequippedExercises)
                        .onChange(of: userData.settings.hideUnequippedExercises) {
                            userData.saveSingleStructToFile(\.settings, for: .settings)
                        }

                    Text("Hides any exercise that requires equipment you haven’t selected.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                // ── Hide Difficult ─────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Hide Difficult Exercises", isOn: $userData.settings.hideDifficultExercises)
                        .onChange(of: userData.settings.hideDifficultExercises) {
                            userData.saveSingleStructToFile(\.settings, for: .settings)
                        }

                    Text("Filters out exercises that exceed your current strength level of '\(userData.evaluation.strengthLevel.fullName)'.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                // ── Hide Disliked ──────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Hide Disliked Exercises", isOn: $userData.settings.hideDislikedExercises)
                        .onChange(of: userData.settings.hideDislikedExercises) {
                            userData.saveSingleStructToFile(\.settings, for: .settings)
                        }

                    Text("Hides any exercise you’ve marked as “disliked.”")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            } header: {
                Text("Visibility Filters")
            }
        }
        .navigationBarTitle("Exercise Sorting", displayMode: .inline)
        .toolbar {
             ToolbarItem(placement: .topBarTrailing) {
                 Button("Reset") { resetAll() }
                     .foregroundStyle(isDefault ? Color.gray : Color.red)        // make the label red
                     .disabled(isDefault)       // disable when no items
             }
         }
    }
    
    private func resetAll() {
        userData.settings.saveSelectedSort = false
        userData.settings.enableSortPicker = true
        userData.sessionTracking.exerciseSortOption = .moderate
        userData.settings.sortByTemplateCategories = true

        userData.settings.hideUnequippedExercises = false
        userData.settings.hideDifficultExercises = false
        userData.settings.hideDislikedExercises = false

        userData.saveToFile()
    }

    private var isDefault: Bool {
        return userData.settings.enableSortPicker
            && userData.sessionTracking.exerciseSortOption == .moderate
            && userData.settings.sortByTemplateCategories
            && !userData.settings.saveSelectedSort
            && !userData.settings.hideUnequippedExercises
            && !userData.settings.hideDifficultExercises
            && !userData.settings.hideDislikedExercises
    }
}


