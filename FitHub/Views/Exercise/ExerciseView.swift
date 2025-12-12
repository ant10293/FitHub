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
                ExerciseDetailView(exercise: exercise)
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
                            detail: {
                                ExerciseRowDetails(
                                    exercise: exercise,
                                    peak: ctx.exercises.peakMetric(for: exercise.id),
                                    showAliases: true
                                )
                            },
                            onTap: {
                                kbd.dismiss()
                                selectedExerciseId = exercise.id
                                viewDetail = true
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
}
