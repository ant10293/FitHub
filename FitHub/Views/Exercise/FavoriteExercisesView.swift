import SwiftUI


struct FavoriteExercisesView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var exerciseData: ExerciseData
    @ObservedObject var userData: UserData
    @State private var searchText = ""
    @State private var selectedFilter: ExerciseFilter = .favorites
    @State private var isKeyboardVisible: Bool = false
    @State private var showingResetConfirmation = false

    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search Exercises", text: $searchText)
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ExerciseFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                if filteredExercises.isEmpty {
                    List {
                        // Display a message if no exercises match the filter
                        Text(selectedFilter == .favorites ? "No favorite exercises yet." : "No disliked exercises yet.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                } else {
                    List(filteredExercises, id: \.self) { exercise in
                        HStack {
                            Image(exercise.fullImagePath)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Text(exercise.name)
                            
                            Spacer()
                            
                            if selectedFilter == .favorites {
                                Image(systemName: userData.favoriteExercises.contains(exercise.name) ? "heart.fill" : "heart")
                                    .foregroundColor(userData.favoriteExercises.contains(exercise.name) ? .red : .gray)
                                    .onTapGesture {
                                        toggleFavorite(for: exercise)
                                    }
                            }
                            else if selectedFilter == .disliked {
                                Image(systemName: userData.dislikedExercises.contains(exercise.name) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .foregroundColor(userData.dislikedExercises.contains(exercise.name) ? .blue : .gray)
                                    .onTapGesture {
                                        toggleDislike(for: exercise)
                                    }
                            }
                            else {
                                Image(systemName: userData.dislikedExercises.contains(exercise.name) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .foregroundColor(userData.dislikedExercises.contains(exercise.name) ? .blue : .gray)
                                    .onTapGesture {
                                        toggleDislike(for: exercise)
                                    }
                                
                                Image(systemName: userData.favoriteExercises.contains(exercise.name) ? "heart.fill" : "heart")
                                    .foregroundColor(userData.favoriteExercises.contains(exercise.name) ? .red : .gray)
                                    .onTapGesture {
                                        toggleFavorite(for: exercise)
                                    }
                            }
                            
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onAppear { selectedFilter = userData.favoriteExercises.isEmpty ? .all : .favorites } // Conditionally set selectedFilter based on user data
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear(perform: removeKeyboardObservers)
            .navigationBarTitle("Favorite Exercises").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(emptyLists() ? Color.gray : Color.red)        // make the label red
                    .disabled(emptyLists())       // disable when no items
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
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
    
    private func emptyLists() -> Bool {
        return userData.favoriteExercises.isEmpty && userData.dislikedExercises.isEmpty
    }
    
    private func removeAll() {
        userData.favoriteExercises.removeAll()
        userData.dislikedExercises.removeAll()
        userData.saveToFile()
    }
    
    private func isExerciseVisible(_ exercise: Exercise) -> Bool {
        // Normalize the search text by removing spaces and converting to lowercase
        let normalizedSearchText = searchText.replacingOccurrences(of: " ", with: "").lowercased()
        
        // Normalize the exercise name and aliases
        let normalizedName = exercise.name.replacingOccurrences(of: " ", with: "").lowercased()
        let normalizedAliases = exercise.aliases?.map { $0.replacingOccurrences(of: " ", with: "").lowercased() } ?? []
        
        // Check if the normalized search text matches the normalized name or any alias
        return searchText.isEmpty ||
        normalizedName.contains(normalizedSearchText) ||
        normalizedAliases.contains(where: { $0.contains(normalizedSearchText) })
    }
    
    var filteredExercises: [Exercise] {
        let exercises: [Exercise]
        switch selectedFilter {
        case .all:
            exercises = exerciseData.allExercises
        case .favorites:
            exercises = exerciseData.allExercises.filter { userData.favoriteExercises.contains($0.name) }
        case .disliked:
            exercises = exerciseData.allExercises.filter { userData.dislikedExercises.contains($0.name) }
        }
        return exercises.filter(isExerciseVisible)
    }
    
    private func toggleFavorite(for exercise: Exercise) {
        if let index = userData.favoriteExercises.firstIndex(of: exercise.name) {
            userData.favoriteExercises.remove(at: index)
        } else {
            // Remove from disliked if it's being favorited
            if let dislikeIndex = userData.dislikedExercises.firstIndex(of: exercise.name) {
                userData.dislikedExercises.remove(at: dislikeIndex)
                userData.saveSingleVariableToFile(\.dislikedExercises, for: .dislikedExercises)
            }
            userData.favoriteExercises.append(exercise.name)
            userData.saveSingleVariableToFile(\.favoriteExercises, for: .favoriteExercises)
        }
    }
    
    private func toggleDislike(for exercise: Exercise) {
        if let index = userData.dislikedExercises.firstIndex(of: exercise.name) {
            userData.dislikedExercises.remove(at: index)
        } else {
            // Remove from favorites if it's being disliked
            if let favoriteIndex = userData.favoriteExercises.firstIndex(of: exercise.name) {
                userData.favoriteExercises.remove(at: favoriteIndex)
                userData.saveSingleVariableToFile(\.favoriteExercises, for: .favoriteExercises)
            }
            userData.dislikedExercises.append(exercise.name)
            userData.saveSingleVariableToFile(\.dislikedExercises,for: .dislikedExercises)
        }
    }
    
    enum ExerciseFilter: String, CaseIterable, Identifiable {
        case favorites = "Favorites"
        case disliked = "Disliked"
        case all = "All Exercises"
        
        var id: String { self.rawValue }
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
}

