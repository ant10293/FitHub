import SwiftUI

struct ExerciseSelection: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    @State var selectedExercises: [Exercise] = []
    @State private var searchText = ""
    @State private var selectedCategory: CategorySelections = .split(.all)
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var isKeyboardVisible: Bool = false
    @State private var showingFavorites = false
    var templateCategories: [SplitCategory]?
    var onDone: ([Exercise]) -> Void     /// Called when the user finishes selection.
    var forPerformanceView: Bool = false     /// If true, we hide checkboxes and pick one exercise immediately, dismissing the view.
    
    var filteredExercises: [Exercise] {
        // Start with the base filtered list from your existing method
        let base = exerciseData.filteredExercises(
            searchText: searchText,
            selectedCategory: selectedCategory,
            templateCategories: templateCategories,
            favoritesOnly: showingFavorites,
            favoriteList: userData.favoriteExercises
        )
        
        // If `forPerformanceView` is true, filter out exercises with no performance or maxValue <= 0
        if forPerformanceView {
            return base
                .compactMap { exercise in
                    if let performance = exerciseData.allExercisePerformance[exercise.name],
                       let maxVal = performance.maxValue,
                       maxVal > 0 {
                        return (exercise, performance.currentMaxDate ?? .distantPast)
                    } else {
                        return nil
                    }
                }
                .sorted(by: { $0.1 > $1.1 }) // Sort by most recent date
                .map { $0.0 } // Return only the exercises
        } else {
            return base
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Category selector (e.g. all/upper/lower/cardio)
                SplitCategoryPicker(sortOption: userData.exerciseSortOption, selectedCategory: $selectedCategory, templateCategories: templateCategories, onChange: { sortOption in
                    if userData.exerciseSortOption != sortOption {
                        userData.exerciseSortOption = sortOption
                        userData.saveSingleVariableToFile(\.exerciseSortOption, for: .exerciseSortOption)
                    }
                }).padding(.bottom, -5)
               
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search Exercises", text: $searchText)
                    
                    // Clear search button
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .frame(alignment: .trailing)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // The List of Exercises
                List {
                    if filteredExercises.isEmpty {
                        Text("No exercises found.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(filteredExercises, id: \.self) { exercise in
                            // Tappable row
                            Button(action: {
                                if forPerformanceView {
                                    // In performance mode, pick one exercise and dismiss
                                    onDone([exercise])
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    // Normal multi-selection mode
                                    if let index = selectedExercises.firstIndex(where: { $0.name == exercise.name }) {
                                        selectedExercises.remove(at: index)
                                    } else {
                                        selectedExercises.append(exercise)
                                    }
                                }
                            }) {
                                rowContent(for: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Select \(forPerformanceView ? "Exercise" : "Exercises")")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear(perform: removeKeyboardObservers)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Favorites toggle
                    Button(action: {
                        showingFavorites.toggle()
                    }) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(showingFavorites ? .red : .gray)
                            .padding(10)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDone(selectedExercises)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(forPerformanceView ? "Close" : "Done")
                            .padding(10)
                    }
                }
            }
        }
    }
    
    // MARK: - Row Content
    @ViewBuilder
    private func rowContent(for exercise: Exercise) -> some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                // Exercise image
                Image(exercise.fullImagePath)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Overlay heart icon if it's a favorite
                if userData.favoriteExercises.contains(exercise.name) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.red)
                        .padding(-10)
                        .padding(.bottom, -20)
                } else if userData.dislikedExercises.contains(exercise.name) {
                    Image(systemName: "hand.thumbsdown.fill")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.blue)
                        .padding(-10)
                        .padding(.bottom, -20)
                }
            }
            
            Text(exercise.name)
            
            Spacer()
            
            if forPerformanceView {
                // Show a chevron in place of the checkboxes
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray) // "gray out" as requested
            } else {
                // Show checkboxes if not in performance mode
                Image(systemName: selectedExercises.contains(where: { $0.name == exercise.name })
                      ? "checkmark.square.fill"
                      : "square")
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .contentShape(Rectangle()) // Entire row is tappable
    }
    
    // MARK: - Keyboard Observers
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
}


