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
            if let initialCategory {
                return initialCategory
            } else if sortByTemplateCategories,
                        let templateCategories,
                        let first = templateCategories.first {
                return .split(first)
            } else if let saved = savedSortOption {
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
            FilterableExerciseList(
                exercises: ctx.exercises,
                userData: ctx.userData,
                equipment: ctx.equipment,
                searchText: $searchText,
                selectedCategory: Binding(
                    get: { selectedCategory },
                    set: { selectedCategory = $0 }
                ),
                showingFavorites: $showingFavorites,
                dislikedOnly: .constant(false),
                templateCategories: templateSortingEnabled ? templateCategories : nil,
                templateFilter: filterTemplateCats,
                mode: isPerformanceMode ? .performanceView : .standard,
                emptyMessage: "No exercises found\(isPerformanceMode ? " with performance data" : "").",
                showSearchBar: !isOneRMMode,
                pickerContent: {
                    if !isOneRMMode {
                        SplitCategoryPicker(
                            userData: ctx.userData,
                            selectedCategory: Binding(
                                get: { selectedCategory },
                                set: { selectedCategory = $0 }
                            ),
                            templateCategories: templateCategories,
                            onChange: { sortOption in
                                templateFilter = (sortOption == .templateCategories)
                            }
                        )
                    } else {
                        EmptyView()
                    }
                },
                exerciseRow: { exercise in
                    AnyView(
                        ExerciseRow(
                            exercise,
                            heartOverlay: true,
                            favState: FavoriteState.getState(for: exercise, userData: ctx.userData),
                            accessory: {
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
                    )
                }
            )
            .navigationBarTitle("Select Exercise\(isSingleSelectImmediate ? "" : "s")", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onDisappear(perform: disappearAction)
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
