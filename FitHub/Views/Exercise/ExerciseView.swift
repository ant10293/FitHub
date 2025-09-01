import SwiftUI

struct ExerciseView: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var viewDetail: Bool = false
    @State private var selectedExerciseId: UUID?
    @State private var searchText: String = ""
    @State private var selectedCategory: CategorySelections = .split(.all)
    @State private var showingFavorites: Bool = false
    @State private var showExerciseCreation: Bool = false

    var body: some View {
        VStack {
            SplitCategoryPicker(userData: ctx.userData, selectedCategory: $selectedCategory)
                .padding(.bottom, -5)
            
            SearchBar(text: $searchText, placeholder: "Search Exercises")
                .padding(.horizontal)
            
            exerciseListView
        }
        .navigationBarTitle("Exercises", displayMode: .inline)
        .navigationDestination(isPresented: $viewDetail) {
            if let exerciseId = selectedExerciseId, let exercise = ctx.exercises.exercise(for: exerciseId) {
                ExerciseDetailView(viewingDuringWorkout: false, exercise: exercise)
            } else {
                // exercise got deleted while we were on the detail screen → pop
                Color.clear.onAppear { selectedExerciseId = nil; viewDetail = false }
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
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingFavorites.toggle() }) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(showingFavorites ? .red : .gray)
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
                    .foregroundStyle(.gray)
                    .padding()
            } else {
                Section {
                    ForEach(filteredExercises, id: \.self) { exercise in
                        let favState = FavoriteState.getState(for: exercise, userData: ctx.userData)
                        
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
                                                .foregroundStyle(.gray)
                                        )
                                    }
                                    
                                    // 🏆 1RM
                                    if let max = ctx.exercises.peakMetric(for: exercise.id) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "trophy.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 8.5, height: 8.5)
                                            
                                            Text(exercise.type.usesWeight ? "1rm: " : (exercise.effort.usesReps ? "Max: " : "Time: "))
                                                .bold()
                                                .font(.caption2)
                                            +
                                            max.labeledText
                                                .font(.caption2)
                                        }
                                    }
                                }
                            },
                            onTap: {
                                selectedExerciseId = exercise.id
                                viewDetail = true
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

