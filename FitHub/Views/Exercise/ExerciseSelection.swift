import SwiftUI

struct ExerciseSelection: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State var selectedExercises: [Exercise] = []
    @State private var searchText: String = ""
    @State private var selectedCategory: CategorySelections = .split(.all)
    @State private var showingFavorites: Bool = false
    @State private var donePressed: Bool = false
    @State private var templateFilter: Bool = false
    var templateCategories: [SplitCategory]?
    var onDone: ([Exercise]) -> Void  /// Called when the user finishes selection.
    var forPerformanceView: Bool = false     /// If true, we hide checkboxes and pick one exercise immediately, dismissing the view.
    
    var body: some View {
        NavigationStack {
            VStack {
                SplitCategoryPicker(
                    userData: ctx.userData,
                    selectedCategory: $selectedCategory,
                    templateCategories: templateCategories,
                    onChange: { sortOption in
                        if sortOption == .templateCategories {
                            templateFilter = true
                        } else {
                            templateFilter = false
                        }
                    }
                )
                .padding(.bottom, -5)
               
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search Exercises")
                    .padding(.horizontal)
                
                // The List of Exercises
                List {
                    if filteredExercises.isEmpty {
                        Text("No exercises found \(forPerformanceView ? "with performance data" : "").")
                            .padding()
                            .multilineTextAlignment(.center)
                    } else {
                        Section {
                            ForEach(filteredExercises, id: \.id) { exercise in
                                let favState = FavoriteState.getState(for: exercise, userData: ctx.userData)
                                
                                ExerciseRow(
                                    exercise,
                                    heartOverlay: true,
                                    favState: favState,
                                    accessory: {
                                        // trailing icon: chevron or checkbox
                                        Image(systemName: forPerformanceView
                                              ? "chevron.right"
                                              : (selectedExercises.contains(where: { $0.id == exercise.id })
                                                 ? "checkmark.square.fill"
                                                 : "square"))
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    },
                                    detail: { EmptyView() },
                                    onTap: {
                                        if forPerformanceView {
                                            onDone([exercise])
                                            dismiss()
                                        } else {
                                            if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
                                                selectedExercises.remove(at: index)
                                            } else {
                                                selectedExercises.append(exercise)
                                            }
                                        }
                                    }
                                )
                            }
                        } footer: {
                            Text("\(filteredExercises.count) exercise\(filteredExercises.count == 1 ? "" : "s")")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationBarTitle("Select Exercise\(forPerformanceView ? "" : "s")", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onDisappear(perform: disappearAction)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingFavorites.toggle() }) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(showingFavorites ? .red : .gray)
                            .padding(10)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        donePressed = true
                        onDone(selectedExercises)
                        dismiss()
                    }) {
                        Text(forPerformanceView ? "Close" : "Done")
                            .padding(10)
                    }
                }
            }
        }
    }
    
    private func disappearAction() { if !donePressed && !forPerformanceView { onDone(selectedExercises) } }
    
    private var filterTemplateCats: Bool { ctx.userData.sessionTracking.exerciseSortOption == .templateCategories || templateFilter }
    
    private var templateSortingEnabled: Bool { ctx.userData.settings.sortByTemplateCategories && !(templateCategories?.isEmpty ?? true) }
    
    private var filteredExercises: [Exercise] {        
        let base = ctx.exercises.filteredExercises(
            searchText: searchText,
            selectedCategory: selectedCategory,
            templateCategories: templateSortingEnabled ? templateCategories : nil,
            templateFilter: filterTemplateCats,
            favoritesOnly: showingFavorites,
            userData: ctx.userData,
            equipmentData: ctx.equipment
        )
        
        // If `forPerformanceView` is true, filter out exercises with no performance or maxValue <= 0
        if forPerformanceView {
            let perfByName = ctx.exercises.allExercisePerformance // Grab the lookup once
            let filtered = base.filter { ex in // Filter out the ones you don’t want
                guard let perf = perfByName[ex.id], let max = perf.currentMax, max.value.displayValue > 0 else { return false }
                return true
            }
            
            return filtered.sorted { a, b in // Sort in one pass, looking up each date on the fly
                let da = perfByName[a.id]?.currentMax?.date ?? .distantPast
                let db = perfByName[b.id]?.currentMax?.date ?? .distantPast
                return da > db
            }
        } else {
            return base
        }
    }
}


