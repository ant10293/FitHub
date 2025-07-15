import SwiftUI

struct ExerciseSelection: View {
    @Environment(\.presentationMode) var presentationMode
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
                    enableSortPicker: ctx.userData.settings.enableSortPicker,
                    saveSelectedSort: ctx.userData.settings.saveSelectedSort,
                    sortByTemplateCategories: ctx.userData.settings.sortByTemplateCategories,
                    sortOption: ctx.userData.sessionTracking.exerciseSortOption,
                    templateCategories: templateCategories,
                    selectedCategory: $selectedCategory,
                    onChange: { sortOption in
                        if sortOption == .templateCategories {
                            templateFilter = true
                        } else {
                            templateFilter = false
                        }
                        if ctx.userData.sessionTracking.exerciseSortOption != sortOption, ctx.userData.settings.saveSelectedSort {
                            ctx.userData.sessionTracking.exerciseSortOption = sortOption
                            ctx.userData.saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)
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
                        Text("No exercises found.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        Section {
                            ForEach(filteredExercises, id: \.id) { exercise in
                                let favState: FavoriteState = ctx.userData.evaluation.favoriteExercises.contains(exercise.id) ? .favorite
                                : (ctx.userData.evaluation.dislikedExercises.contains(exercise.id) ? .disliked : .unmarked)
                                
                                ExerciseRow(exercise, heartOverlay: favState != .unmarked ? true : false, favState: favState, accessory: {
                                    // trailing icon: chevron or checkbox
                                    Image(systemName: forPerformanceView
                                          ? "chevron.right"
                                          : (selectedExercises.contains(where: { $0.id == exercise.id })
                                             ? "checkmark.square.fill"
                                             : "square"))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    },
                                    detail: {
                                        EmptyView() // no subtitle or extra detail here
                                    },
                                    onTap: {
                                        if forPerformanceView {
                                            onDone([exercise])
                                            presentationMode.wrappedValue.dismiss()
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFavorites.toggle() }) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(showingFavorites ? .red : .gray)
                            .padding(10)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        donePressed = true
                        onDone(selectedExercises)
                        presentationMode.wrappedValue.dismiss()
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
                guard let perf = perfByName[ex.id], let max = perf.maxValue, max > 0 else { return false }
                return true
            }
            
            return filtered.sorted { a, b in // Sort in one pass, looking up each date on the fly
                let da = perfByName[a.id]?.currentMaxDate ?? .distantPast
                let db = perfByName[b.id]?.currentMaxDate ?? .distantPast
                return da > db
            }
        } else {
            return base
        }
    }
}


