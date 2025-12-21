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
        FilterableExerciseList(
            exercises: ctx.exercises,
            userData: ctx.userData,
            equipment: ctx.equipment,
            searchText: $searchText,
            selectedCategory: $selectedCategory,
            showingFavorites: $showingFavorites,
            dislikedOnly: .constant(false),
            emptyMessage: "No exercises available in this category.",
            pickerContent: {
                SplitCategoryPicker(userData: ctx.userData, selectedCategory: $selectedCategory)
            },
            exerciseRow: { exercise in
                AnyView(
                    ExerciseRow(
                        exercise,
                        heartOverlay: true,
                        favState: FavoriteState.getState(for: exercise, userData: ctx.userData),
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
                )
            }
        )
        .onAppear(perform: initializeSelection)
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
    
    private func initializeSelection() {
        selectedCategory = ctx.userData.sessionTracking.exerciseSortOption.getDefaultSelection()
    }
}
