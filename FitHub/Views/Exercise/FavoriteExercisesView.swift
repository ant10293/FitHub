import SwiftUI


struct FavoriteExercisesView: View {
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: ExerciseFilter = .favorites
    @State private var showingResetConfirmation: Bool = false
    @State private var hasInitializedCategory: Bool = false
    private let modifier = ExerciseModifier()

    var body: some View {
        NavigationStack {
            FilterableExerciseList(
                exercises: ctx.exercises,
                userData: ctx.userData,
                equipment: ctx.equipment,
                searchText: $searchText,
                selectedCategory: .constant(.resistanceType(.any)),
                showingFavorites: Binding(
                    get: { selectedFilter == .favorites },
                    set: { if $0 { selectedFilter = .favorites } }
                ),
                dislikedOnly: Binding(
                    get: { selectedFilter == .disliked },
                    set: { if $0 { selectedFilter = .disliked } }
                ),
                emptyMessage: selectedFilter.emptyMessage,
                pickerContent: {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(ExerciseFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.horizontal, .bottom])
                },
                exerciseRow: { exercise in
                    AnyView(
                        ExerciseRow(
                            exercise,
                            accessory: {
                                RatingIcon(
                                    exercise: exercise,
                                    favState: FavoriteState.getState(for: exercise, userData: ctx.userData),
                                    selectedFilter: selectedFilter,
                                    onFavorite: {
                                        modifier.toggleFavorite(for: exercise.id, userData: ctx.userData)
                                    },
                                    onDislike: {
                                        modifier.toggleDislike(for: exercise.id, userData: ctx.userData)
                                    }
                                )
                            }
                        )
                    )
                }
            )
            .onAppear(perform: initializeFilter)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationBarTitle("Favorite Exercises", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        showingResetConfirmation = true
                    }
                    .foregroundStyle(emptyLists ? Color.gray : Color.red)
                    .disabled(emptyLists)
                }
            }
            .alert("Remove All Exercises?", isPresented: $showingResetConfirmation) {
                Button("Remove All", role: .destructive) {
                    removeAll()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear both your favorites and dislikes. Are you sure?")
            }
        }
    }

    enum ExerciseFilter: String, CaseIterable, Identifiable {
        case favorites = "Favorites"
        case disliked = "Disliked"
        case all = "All Exercises"

        var id: String { self.rawValue }
        
        var emptyMessage: String {
            switch self {
            case .all: "No exercises found."
            case .favorites: "No favorite exercises found."
            case .disliked: "No disliked exercises found."
            }
        }
    }

    private var emptyLists: Bool {
        return ctx.userData.evaluation.favoriteExercises.isEmpty && ctx.userData.evaluation.dislikedExercises.isEmpty
    }
    
    private func removeAll() {
        ctx.userData.evaluation.favoriteExercises.removeAll()
        ctx.userData.evaluation.dislikedExercises.removeAll()
    }
    
    private func initializeFilter() {
        // Conditionally set selectedFilter based on user data
        guard !hasInitializedCategory else { return }
        selectedFilter = ctx.userData.evaluation.favoriteExercises.isEmpty ? .all : .favorites
        hasInitializedCategory = true
    }
}

struct RatingIcon: View {
    let exercise: Exercise
    let favState: FavoriteState
    let selectedFilter: FavoriteExercisesView.ExerciseFilter
    let size: Image.Scale
    let onFavorite: () -> Void
    let onDislike: () -> Void

    init(
        exercise: Exercise,
        favState: FavoriteState,
        selectedFilter: FavoriteExercisesView.ExerciseFilter = .all,
        size: Image.Scale = .medium,
        onFavorite: @escaping () -> Void,
        onDislike: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.favState = favState
        self.selectedFilter = selectedFilter
        self.size = size
        self.onFavorite = onFavorite
        self.onDislike = onDislike
    }
    var body: some View {
        HStack(spacing: 12) {
            if selectedFilter != .favorites {
                let isDisliked = favState == .disliked
                Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .foregroundStyle(isDisliked ? .blue : .gray)
                    .imageScale(size)
                    .onTapGesture(perform: onDislike)
            }
            if selectedFilter != .disliked {
                let isFavorite = favState == .favorite
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .red : .gray)
                    .imageScale(size)
                    .onTapGesture(perform: onFavorite)
            }
        }
    }
}


