import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var equipmentData: EquipmentData
    @EnvironmentObject var csvLoader: CSVLoader
    @EnvironmentObject var exerciseData: ExerciseData
    @State private var selectedExercise: Exercise?
    @State private var searchText = ""
    @State private var selectedCategory: CategorySelections = .split(.all)
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @State private var showingFavorites: Bool = false
    @State private var isKeyboardVisible: Bool = false
    @State private var showingDetailView: Bool = false
    
    var filteredExercises: [Exercise] {
        exerciseData.filteredExercises(
            searchText: searchText,
            selectedCategory: selectedCategory,
            favoritesOnly: showingFavorites,
            favoriteList: userData.favoriteExercises
        )
    }
    
    var body: some View {
        VStack {
            SplitCategoryPicker(sortOption: userData.exerciseSortOption, selectedCategory: $selectedCategory, onChange: { sortOption in 
                if userData.exerciseSortOption != sortOption {
                    userData.exerciseSortOption = sortOption
                    userData.saveSingleVariableToFile(\.exerciseSortOption, for: .exerciseSortOption)
                }
            }).padding(.bottom, -5)
            
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search Exercises", text: $searchText)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = "" // Clear the search text
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .frame(alignment: .trailing)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            exerciseListView
        }
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingDetailView) {
            if let selectedExercise = selectedExercise {
                // ExerciseDetailView displayed as an overlay
                ExerciseDetailView(
                    exerciseData: exerciseData,
                    viewingDuringWorkout: false,
                    exercise: selectedExercise,
                    onClose: {
                        self.selectedExercise = nil
                        showingDetailView = false
                    }
                )
            }
        }
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingFavorites.toggle()
                }) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(showingFavorites ? .red : .gray)
                }
            }
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    private var exerciseListView: some View {
        VStack {
            if filteredExercises.isEmpty {
                List {
                    Text("No exercises available in this category.")
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                List(filteredExercises, id: \.self) { exercise in
                    ExerciseRow(exercise: exercise, onSelect: { exercise in
                        selectedExercise = exercise
                        self.showingDetailView = true
                    })
                }
            }
        }
    }
    
    struct ExerciseRow: View {
        @EnvironmentObject var userData: UserData
        @EnvironmentObject var exerciseData: ExerciseData
        var exercise: Exercise
        var onSelect: (Exercise) -> Void
        
        var body: some View {
            HStack {
                ZStack(alignment: .bottomTrailing) {
                    Image(exercise.fullImagePath)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    // Overlay heart icon if exercise is in favorite exercises
                    if userData.favoriteExercises.contains(exercise.name) {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.red)
                            .padding(-15)
                            .padding(.bottom, -22)
                    } else if userData.dislikedExercises.contains(exercise.name) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.blue)
                            .padding(-15)
                            .padding(.bottom, -22)
                    }
                }
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let aliases = exercise.aliases, !aliases.isEmpty {
                        Text(aliases.count == 1 ? "Alias: " : "Aliases: ")
                            .font(.caption)
                            .fontWeight(.semibold)
                        +
                        Text(aliases.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if let maxValue = exerciseData.getMax(for: exercise.name) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 8.5, height: 8.5)
                                .padding(.trailing, -5)
                            Text(exercise.usesWeight ? "1rm: " : "Max Reps: ").bold()
                                .font(.caption2)
                            + Text("\(smartFormat(maxValue))")
                                .font(.caption2)
                        }
                        .padding(.top, -5)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(exercise)
            }
        }
    }
}

