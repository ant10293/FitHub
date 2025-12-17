import SwiftUI

struct ExerciseSelection: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var selectedExercises: [Exercise]
    @State private var selectedCategory: CategorySelections
    @State private var searchText: String = ""
    @State private var showingFavorites: Bool = false
    @State private var donePressed: Bool = false
    @State private var templateFilter: Bool = false
    @State private var filteredExercisesCache: [Exercise] = []
    let templateCategories: [SplitCategory]?
    let mode: SelectionMode     /// Controls behavior / presentation style for this selector.
    let onDone: ([Exercise]) -> Void     /// Called when the user finishes selection.

    // MARK: - Init
    init(
        sortByTemplateCategories: Bool = false,
        savedSortOption: ExerciseSortOption? = nil,
        selectedExercises: [Exercise] = [],
        templateCategories: [SplitCategory]? = nil,
        initialCategory: CategorySelections? = nil,
        initialSortOption: ExerciseSortOption? = nil,
        mode: SelectionMode = .templateSelection,
        onDone: @escaping ([Exercise]) -> Void
    ) {
        _selectedExercises = State(initialValue: selectedExercises)
                
        let initialDerived: CategorySelections = {
            // override
            if let initialCategory {
                return initialCategory
            }
            // for template detail
            else if sortByTemplateCategories,
                        let templateCategories,
                        let first = templateCategories.first {
                return .split(first)
            }
            else if let saved = savedSortOption {
                return saved.getDefaultSelection()
            } else {
                return .split(.all)
            }
        }()
        _selectedCategory = State(initialValue: initialDerived)
        
        self.templateCategories = templateCategories
        self.mode = mode
        self.onDone = onDone
    }

    // MARK: - Derived Mode Flags
    private var isPerformanceMode: Bool { mode == .performanceView }
    private var isOneRMMode: Bool { mode == .oneRMCalculator }
    /// In these modes we immediately resolve selection on tap and dismiss.
    private var isSingleSelectImmediate: Bool { mode.isSingleSelectImmediate }
    
    private var selectedIDs: Set<Exercise.ID> { Set(selectedExercises.map(\.id)) }

    var body: some View {
        NavigationStack {
            VStack {
                if !isOneRMMode {
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
                }

                // Search bar
                SearchBar(text: $searchText, placeholder: "Search Exercises")
                    .padding(.horizontal)

                // The List of Exercises
                List {
                    if filteredExercisesCache.isEmpty {
                        Text("No exercises found\(isPerformanceMode ? " with performance data" : "").")
                            .padding()
                            .multilineTextAlignment(.center)
                    } else {
                        Section {
                            ForEach(filteredExercisesCache, id: \.id) { exercise in
                                let favState = FavoriteState.getState(for: exercise, userData: ctx.userData)

                                ExerciseRow(
                                    exercise,
                                    heartOverlay: true,
                                    favState: favState,
                                    accessory: {
                                        // trailing icon: chevron or checkbox
                                        Image(systemName: isSingleSelectImmediate
                                              ? "chevron.right"
                                              : (selectedIDs.contains(exercise.id)
                                                 ? "checkmark.square.fill"
                                                 : "square"))
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    },
                                    detail: {
                                        detailView(for: exercise)
                                    },
                                    onTap: {
                                        handleTap(on: exercise)
                                    }
                                )
                            }
                        } footer: {
                            Text(Format.countText(filteredExercisesCache.count))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationBarTitle("Select Exercise\(isSingleSelectImmediate ? "" : "s")", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onDisappear(perform: disappearAction)
            .onAppear(perform: recomputeFilteredExercises)
            .onChange(of: searchText) { recomputeFilteredExercises() }
            .onChange(of: selectedCategory) { recomputeFilteredExercises() }
            .onChange(of: showingFavorites) { recomputeFilteredExercises() }
            .onChange(of: templateFilter) { recomputeFilteredExercises() }
            .onChange(of: filterTemplateCats) { recomputeFilteredExercises() }
            .onChange(of: templateSortingEnabled) { recomputeFilteredExercises() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingFavorites.toggle() }) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(showingFavorites ? .red : .gray)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        donePressed = true
                        onDone(selectedExercises)
                        dismiss()
                    }) {
                        Text("Close")
                    }
                }
            }
        }
    }

    private func disappearAction() {
        // For multi-select modes, ensure the caller still receives the final selection
        if !donePressed && !isSingleSelectImmediate {
            onDone(selectedExercises)
        }
    }

    private var filterTemplateCats: Bool { ctx.userData.sessionTracking.exerciseSortOption == .templateCategories || templateFilter }

    private var templateSortingEnabled: Bool { ctx.userData.settings.sortByTemplateCategories && !(templateCategories?.isEmpty ?? true) }

    private func recomputeFilteredExercises() {
        let base = ctx.exercises.filteredExercises(
            searchText: searchText,
            selectedCategory: selectedCategory,
            templateCategories: templateSortingEnabled ? templateCategories : nil,
            templateFilter: filterTemplateCats,
            favoritesOnly: showingFavorites,
            userData: ctx.userData,
            equipmentData: ctx.equipment
        )

        guard isPerformanceMode else {
            filteredExercisesCache = base
            return
        }

        // Dedupe by ID, preserve order
        var seen = Set<Exercise.ID>()
        let uniqueBase = base.filter { seen.insert($0.id).inserted }

        // ✅ Filter: must have a peak and its actualValue > 0
        let filtered = uniqueBase.filter { ex in
            guard let peak = ctx.exercises.peakMetric(for: ex.id) else { return false }
            return peak.actualValue > 0
        }

        // ✅ Sort: newest max first (same source of truth)
        filteredExercisesCache = filtered.sorted { a, b in
            let da = ctx.exercises.getMax(for: a.id)?.date ?? .distantPast
            let db = ctx.exercises.getMax(for: b.id)?.date ?? .distantPast
            return da > db
        }
    }

    // MARK: - Helpers
    private func handleTap(on exercise: Exercise) {
        if isSingleSelectImmediate {
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

    @ViewBuilder
    private func detailView(for exercise: Exercise) -> some View {
        switch mode {
        case .oneRMCalculator:
            ExerciseRowDetails(
                exercise: exercise,
                peak: ctx.exercises.peakMetric(for: exercise.id),
                showAliases: false
            )
        default:
            EmptyView()
        }
    }

    enum SelectionMode {
        case performanceView, oneRMCalculator, templateSelection

        var isSingleSelectImmediate: Bool {
            switch self {
            case .performanceView, .oneRMCalculator: return true
            case .templateSelection: return false
            }
        }
    }
}
