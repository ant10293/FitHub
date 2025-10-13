import SwiftUI

struct SimilarExercises: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @State var currentExercise: Exercise
    @State var template: WorkoutTemplate
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var selectedType: ExerciseType = .similar
    @State private var showDetails = false
    @State private var searchText: String = ""         
    let allExercises: [Exercise]
    var onExerciseReplaced: (Exercise) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(currentExercise.name)
                        .font(.title2).fontWeight(.bold)
                        .minimumScaleFactor(0.5).lineLimit(1)
                    Spacer()
                    Button("Close") { dismiss() }.padding(.horizontal)
                }
                HStack(spacing: 16) {
                    currentExercise.fullImageView(
                        favState: FavoriteState.getState(for: currentExercise, userData: userData)
                    )
                    .frame(width: 100, height: 100)

                     Text("\(currentExercise.musclesTextFormatted)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding()

            // Picker
            Picker("Exercise Type", selection: $selectedType) {
                ForEach(ExerciseType.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Search bar (always visible)
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Decide which dataset to show
            let isSearching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let isShowingSimilar = selectedType == .similar
            let baseList = isSearching ? searchResults : (isShowingSimilar ? similarExercises : otherExercises)
            let emptyMessage = isSearching
                ? "No matches outside the similar/other lists."
                : (isShowingSimilar ? "No similar exercises found." : "No other exercises found.")

            if !baseList.isEmpty {
                List(baseList) { exercise in
                    SimilarExerciseRow(
                        userData: userData,
                        exercise: exercise,
                        baseExercise: currentExercise,
                        onReplace: {
                            let old = currentExercise
                            currentExercise = exercise
                            onExerciseReplaced(exercise)
                            setAlert(newExercise: exercise, oldExercise: old)
                        }
                    )
                }
                .listStyle(.insetGrouped)
            } else {
                List {
                    Text(emptyMessage)
                        .foregroundStyle(.red)
                        .padding()
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationBarTitle("Similar Exercises", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Template updated"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    private enum ExerciseType: String, CaseIterable {
        case similar = "Similar Exercises"
        case other   = "Other Exercises"
    }

    private func setAlert(newExercise: Exercise, oldExercise: Exercise) {
        alertMessage = "Replaced '\(oldExercise.name)' with '\(newExercise.name)' in \(template.name)."
        showAlert = true
    }
    
    // MARK: - Search pool = NOT in similar or other (and not current / not already in template)
    private var excludedPool: [Exercise] {
        let blockedIDs = Set(similarExercises.map(\.id)).union(otherExercises.map(\.id))
        return allExercises.filter { e in
            e.id != currentExercise.id &&
            !template.exerciseNames.contains(e.name) &&
            !blockedIDs.contains(e.id)
        }
    }

    private var searchResults: [Exercise] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return excludedPool.filter { e in
            e.name.lowercased().contains(q)
        }
    }

    private var similarExercises: [Exercise] {
        allExercises.filter { exercise in
            exercise.name != currentExercise.name
            && exercise.primaryMuscles == currentExercise.primaryMuscles
            && !Set(exercise.secondaryMuscles).isDisjoint(with: currentExercise.secondaryMuscles)
            && !template.exerciseNames.contains(exercise.name)
        }
    }

    private var otherExercises: [Exercise] {
        allExercises.filter { exercise in
            exercise.name != currentExercise.name
            && exercise.primaryMuscles == currentExercise.primaryMuscles
            && Set(exercise.secondaryMuscles).isDisjoint(with: currentExercise.secondaryMuscles)
            && !template.exerciseNames.contains(exercise.name)
        }
    }
}
