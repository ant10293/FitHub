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
                            Text(Format.countText(filteredExercises.count))
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
                        Text(forPerformanceView ? "Close" : "Close")
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
        
        guard forPerformanceView else { return base }


        // Dedupe by ID, preserve order
        var seen = Set<Exercise.ID>()
        let uniqueBase = base.filter { seen.insert($0.id).inserted }

        // ✅ Filter: must have a peak and its actualValue > 0
        let filtered = uniqueBase.filter { ex in
            guard let peak = ctx.exercises.peakMetric(for: ex.id) else { return false }
            return peak.actualValue > 0
        }

        // ✅ Sort: newest max first (same source of truth)
        return filtered.sorted { a, b in
            let da = ctx.exercises.getMax(for: a.id)?.date ?? .distantPast
            let db = ctx.exercises.getMax(for: b.id)?.date ?? .distantPast
            return da > db
        }
    }
}


