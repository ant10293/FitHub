import SwiftUI

struct ExerciseView: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var selectedExercise: Exercise?
    @State private var searchText: String = ""
    @State private var selectedCategory: CategorySelections = .split(.all)
    @State private var showingFavorites: Bool = false
    @State private var showExerciseCreation: Bool = false

    var body: some View {
        VStack {
            SplitCategoryPicker(
                enableSortPicker: ctx.userData.settings.enableSortPicker,
                saveSelectedSort: ctx.userData.settings.saveSelectedSort,
                sortOption: ctx.userData.sessionTracking.exerciseSortOption,
                selectedCategory: $selectedCategory,
                onChange: { sortOption in
                    if ctx.userData.sessionTracking.exerciseSortOption != sortOption, ctx.userData.settings.saveSelectedSort {
                        ctx.userData.sessionTracking.exerciseSortOption = sortOption
                        ctx.userData.saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)
                    }
                }
            ).padding(.bottom, -5)
            
            SearchBar(text: $searchText, placeholder: "Search Exercises")
                .padding(.horizontal)
            
            exerciseListView
        }
        .navigationBarTitle("Exercises", displayMode: .inline)
        .navigationDestination(item: $selectedExercise) { exercise in
            if ctx.exercises.allExercises.contains(where: { $0.id == exercise.id }) {
                ExerciseDetailView(viewingDuringWorkout: false, exercise: exercise, onClose: { selectedExercise = nil })
            } else {
                // exercise got deleted while we were on the detail screen → pop
                Color.clear.onAppear { selectedExercise = nil }
            }
        }
        .overlay(!kbd.isVisible ?
            FloatingButton(
                image: "plus", action: { showExerciseCreation = true }
            ) : nil, alignment: .bottomTrailing
        )
        .sheet(isPresented: $showExerciseCreation) { NewExercise() }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFavorites.toggle() }) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(showingFavorites ? .red : .gray)
                }
            }
        }
    }
    
    private var filteredExercises: [Exercise] {
        ctx.exercises.filteredExercises(
            searchText: searchText,
            selectedCategory: selectedCategory,
            favoritesOnly: showingFavorites,
            userData: ctx.userData,
            equipmentData: ctx.equipment
        )
    }
    
    private var exerciseListView: some View {
        List {
            if filteredExercises.isEmpty {
                Text("No exercises available in this category.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Section {
                    ForEach(filteredExercises, id: \.self) { exercise in
                        let favState: FavoriteState = ctx.userData.evaluation.favoriteExercises.contains(exercise.id)
                        ? .favorite
                        : (ctx.userData.evaluation.dislikedExercises.contains(exercise.id) ? .disliked : .unmarked)
                        
                        ExerciseRow(
                            exercise,
                            heartOverlay: favState != .unmarked,
                            favState: favState,
                            imageSize: 0.2,
                            accessory: { EmptyView() },
                            detail: {
                                VStack(alignment: .leading, spacing: 4) {
                                    // 🔄 Aliases
                                    if let aliases = exercise.aliases, !aliases.isEmpty {
                                        (
                                            Text(aliases.count == 1 ? "Alias: " : "Aliases: ")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            +
                                            Text(aliases.joined(separator: ", "))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                    }
                                    
                                    // 🏆 1RM
                                    if let max = ctx.exercises.getMax(for: exercise.id) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "trophy.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 8.5, height: 8.5)
                                            
                                            Text(exercise.type.usesWeight ? "1rm: " : "Max Reps: ")
                                                .bold()
                                                .font(.caption2)
                                            +
                                            Text(Format.smartFormat(max))
                                                .font(.caption2)
                                        }
                                        .padding(.top, -4)
                                    }
                                }
                            },
                            onTap: {
                                selectedExercise = exercise
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
}

