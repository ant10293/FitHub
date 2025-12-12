import SwiftUI

struct ExerciseSelection: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var selectedExercises: [Exercise]
    @State private var searchText: String
    @State private var selectedCategory: CategorySelections
    @State private var showingFavorites: Bool
    @State private var donePressed: Bool
    @State private var templateFilter: Bool
    let templateCategories: [SplitCategory]?
    let mode: SelectionMode     /// Controls behavior / presentation style for this selector.
    let onDone: ([Exercise]) -> Void     /// Called when the user finishes selection.

    // MARK: - Init
    init(
        selectedExercises: [Exercise] = [],
        templateCategories: [SplitCategory]? = nil,
        initialCategory: CategorySelections? = nil,
        mode: SelectionMode = .templateSelection,
        onDone: @escaping ([Exercise]) -> Void
    ) {
        _selectedExercises = State(initialValue: selectedExercises)
        _selectedCategory = State(initialValue: initialCategory ?? .split(.all))
        _searchText = State(initialValue: "")
        _showingFavorites = State(initialValue: false)
        _donePressed = State(initialValue: false)
        _templateFilter = State(initialValue: false)
        self.templateCategories = templateCategories
        self.mode = mode
        self.onDone = onDone
    }

    // MARK: - Derived Mode Flags
    private var isPerformanceMode: Bool { mode == .performanceView }
    private var isOneRMMode: Bool { mode == .oneRMCalculator }
    /// In these modes we immediately resolve selection on tap and dismiss.
    private var isSingleSelectImmediate: Bool { mode.isSingleSelectImmediate }

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
                    if filteredExercises.isEmpty {
                        Text("No exercises found\(isPerformanceMode ? " with performance data" : "").")
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
                                        Image(systemName: isSingleSelectImmediate
                                              ? "chevron.right"
                                              : (selectedExercises.contains(where: { $0.id == exercise.id })
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
                            Text(Format.countText(filteredExercises.count))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationBarTitle("Select Exercise\(isSingleSelectImmediate ? "" : "s")", displayMode: .inline)
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
                        Text("Close")
                            .padding(10)
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

        guard isPerformanceMode else { return base }


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
