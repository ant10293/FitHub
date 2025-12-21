//
//  FilterableExerciseList.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/15/25.
//

import SwiftUI

struct FilterableExerciseList<PickerContent: View>: View {
    // Dependencies
    let exercises: ExerciseData
    let userData: UserData
    let equipment: EquipmentData
    
    // Filter bindings
    @Binding var searchText: String
    @Binding var selectedCategory: CategorySelections
    @Binding var showingFavorites: Bool
    @Binding var dislikedOnly: Bool
    var templateCategories: [SplitCategory]? = nil
    var templateFilter: Bool = false
    
    // Configuration
    var mode: ExerciseListFilterHelper.FilterMode = .standard
    var debounceMs: Int = 0
    var emptyMessage: String = "No exercises found."
    var searchPlaceholder: String = "Search Exercises"
    var showSearchBar: Bool = true
    
    // Picker content (view builder)
    @ViewBuilder let pickerContent: () -> PickerContent
    
    // Exercise row content
    let exerciseRow: (Exercise) -> AnyView
    
    // State (internal - handles caching)
    @StateObject private var filterHelper = ExerciseListFilterHelper()
    
    var body: some View {
        VStack(spacing: 0) {
            // Picker (custom content)
            pickerContent()
                .padding(.bottom, -5)
            
            // SearchBar
            if showSearchBar {
                SearchBar(text: $searchText, placeholder: searchPlaceholder)
                    .padding(.horizontal)
            }
            
            // Exercise List
            List {
                if filterHelper.filteredExercises.isEmpty {
                    if filterHelper.isInitialLoad {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Text(emptyMessage)
                            .foregroundStyle(.gray)
                            .padding()
                    }
                } else {
                    Section {
                        ForEach(filterHelper.filteredExercises, id: \.id) { exercise in
                            exerciseRow(exercise)
                        }
                    } footer: {
                        Text(Format.countText(filterHelper.filteredExercises.count))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.top, screenHeight * 0.01)
        }
        .onAppear(perform: updateFilter)
        .onChange(of: searchText) { updateFilter() }
        .onChange(of: selectedCategory) { updateFilter() }
        .onChange(of: showingFavorites) { updateFilter() }
        .onChange(of: dislikedOnly) { updateFilter() }
        .onChange(of: templateFilter) { updateFilter() }
    }
    
    private func updateFilter() {
        filterHelper.updateFilter(
            exercises: exercises,
            params: ExerciseListFilterHelper.FilterParams(
                searchText: searchText,
                selectedCategory: selectedCategory,
                showingFavorites: showingFavorites,
                dislikedOnly: dislikedOnly,
                templateCategories: templateCategories,
                templateFilter: templateFilter
            ),
            userData: userData,
            equipment: equipment,
            debounceMs: debounceMs,
            mode: mode
        )
    }
}

