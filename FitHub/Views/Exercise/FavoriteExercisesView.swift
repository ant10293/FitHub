import SwiftUI


struct FavoriteExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: ExerciseFilter = .favorites
    @State private var showingResetConfirmation: Bool = false
    private let modifier = ExerciseModifier()

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search Exercises")
                    .padding(.horizontal)
                
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ExerciseFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                List {
                    if filteredExercises.isEmpty {
                        // Display a message if no exercises match the filter
                        Text(selectedFilter == .favorites ? "No favorite exercises found." : (selectedFilter == .disliked ? "No disliked exercises found." : "No exercises found."))
                            .foregroundStyle(.gray)
                            .padding()
                    } else {
                        Section {
                            ForEach(filteredExercises, id: \.id) { exercise in
                                ExerciseRow(exercise, accessory: { ratingIcons(for: exercise) }) {
                                    EmptyView()
                                }
                            }
                        } header: {
                            if selectedFilter != .all {
                                Text(Format.exerciseCountText(filteredExercises.count))
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onAppear { selectedFilter = ctx.userData.evaluation.favoriteExercises.isEmpty ? .all : .favorites } // Conditionally set selectedFilter based on user data
            .navigationBarTitle("Favorite Exercises").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        showingResetConfirmation = true
                    }
                    .foregroundStyle(emptyLists() ? Color.gray : Color.red)        // make the label red
                    .disabled(emptyLists())       // disable when no items
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
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
    
    private enum ExerciseFilter: String, CaseIterable, Identifiable {
        case favorites = "Favorites"
        case disliked = "Disliked"
        case all = "All Exercises"
        
        var id: String { self.rawValue }
    }
    
    @ViewBuilder
    private func ratingIcons(for exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            let favState = FavoriteState.getState(for: exercise, userData: ctx.userData)
            
            if selectedFilter != .favorites {
                let isDisliked = favState == .disliked
                Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .foregroundStyle(isDisliked ? .blue : .gray)
                    .onTapGesture {
                        modifier.toggleDislike(for: exercise.id, userData: ctx.userData)
                    }
            }
            if selectedFilter != .disliked {
                let isFavorite = favState == .favorite
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .red : .gray)
                    .onTapGesture {
                        modifier.toggleFavorite(for: exercise.id, userData: ctx.userData)
                    }
            }
        }
    }
    
    private func emptyLists() -> Bool {
        return ctx.userData.evaluation.favoriteExercises.isEmpty && ctx.userData.evaluation.dislikedExercises.isEmpty
    }
    
    private func removeAll() {
        ctx.userData.evaluation.favoriteExercises.removeAll()
        ctx.userData.evaluation.dislikedExercises.removeAll()
    }
    
    private var filteredExercises: [Exercise] {
        ctx.exercises.filteredExercises(
            searchText: searchText,
            selectedCategory: .resistanceType(.any),
            favoritesOnly: selectedFilter == .favorites,
            dislikedOnly: selectedFilter == .disliked,
            userData: ctx.userData,
            equipmentData: ctx.equipment
        )
    }
}

