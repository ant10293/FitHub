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
    let allExercises: [Exercise]
    var onExerciseReplaced: (Exercise) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current Exercise Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(currentExercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 16) {
                    currentExercise.fullImageView(favState: FavoriteState.getState(for: currentExercise, userData: userData))
                        .frame(width: 100, height: 100)

                    Text("\(currentExercise.musclesTextFormatted)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding()
            
            // Picker to select between similar exercises and other exercises
            Picker("Exercise Type", selection: $selectedType) {
                ForEach(ExerciseType.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            let isShowingSimilar = selectedType == .similar
            let exercisesToShow = isShowingSimilar ? similarExercises : otherExercises
            let emptyMessage = isShowingSimilar ? "No similar exercises found." : "No other exercises found."
            
            if !exercisesToShow.isEmpty {
                List(exercisesToShow) { exercise in
                    SimilarExerciseRow(
                        userData: userData,
                        exercise: exercise,
                        baseExercise: currentExercise,
                        onReplace: {
                            let oldExercise = currentExercise
                            currentExercise = exercise
                            onExerciseReplaced(exercise)
                            setAlert(newExercise: exercise, oldExercise: oldExercise)
                        }
                    )
                }
                .listStyle(InsetGroupedListStyle())
            } else {
                List {
                    Text(emptyMessage)
                        .foregroundStyle(.red)
                        .padding()
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationBarTitle("Similar Exercises", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Template updated"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func similarityPercent(_ a: Exercise, comparedTo b: Exercise) -> Int {
        let sharedPrimaries = a.primaryMuscles == b.primaryMuscles
            ? b.primaryMuscles.count : 0
        let sharedSecondaries = Set(a.secondaryMuscles)
            .intersection(b.secondaryMuscles).count
        let shared = sharedPrimaries + sharedSecondaries
        let union = Set(a.primaryMuscles + a.secondaryMuscles + b.primaryMuscles + b.secondaryMuscles).count

        return union == 0 ? 0 : Int((Double(shared) / Double(union)) * 100.0)
    }
    
    private enum ExerciseType: String, CaseIterable { case similar = "Similar Exercises", other = "Other Exercises" }
    
    private func setAlert(newExercise: Exercise, oldExercise: Exercise) {
        // Provide some feedback or show an alert to the user
        alertMessage = "Replaced '\(oldExercise.name)' with '\(newExercise.name)' in \(template.name)."
        showAlert = true
    }
    
    // Filter exercises that are in the same category and share at least one secondary category
    private var similarExercises: [Exercise] {
        allExercises.filter { exercise in
            exercise.name != currentExercise.name
            && exercise.primaryMuscles == currentExercise.primaryMuscles // or check overlap?
            && !Set(exercise.secondaryMuscles).isDisjoint(with: currentExercise.secondaryMuscles)
            && !template.exerciseNames.contains(exercise.name)
        }
    }
    
    // Filter exercises that are in the same category but don't share secondary categories
    private var otherExercises: [Exercise] {
        allExercises.filter { exercise in
            exercise.name != currentExercise.name
            && exercise.primaryMuscles == currentExercise.primaryMuscles
            && Set(exercise.secondaryMuscles).isDisjoint(with: currentExercise.secondaryMuscles)
            && !template.exerciseNames.contains(exercise.name)
        }
    }
}



