import SwiftUI

struct SimilarExercisesView: View {
    @State var currentExercise: Exercise
    let allExercises: [Exercise]
    @State var template: WorkoutTemplate
    var onExerciseReplaced: (Exercise) -> Void
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    
    // Enum for picker options
    enum ExerciseType: String, CaseIterable {
        case similar = "Similar Exercises"
        case other = "Other Exercises"
    }
    
    @State private var selectedExerciseType: ExerciseType = .similar
    
    // List of names of exercises already in the template for quick lookup
    var templateExerciseNames: Set<String> {
        Set(template.exercises.map { $0.name })
    }
    
    // Filter exercises that are in the same category and share at least one secondary category
    var similarExercises: [Exercise] {
        allExercises.filter { exercise in
            exercise.name != currentExercise.name
            && exercise.primaryMuscles == currentExercise.primaryMuscles // or check overlap?
            && !Set(exercise.secondaryMuscles).isDisjoint(with: currentExercise.secondaryMuscles)
            && !templateExerciseNames.contains(exercise.name)
        }
    }
    
    // Filter exercises that are in the same category but don't share secondary categories
    var otherExercises: [Exercise] {
        allExercises.filter { exercise in
            exercise.name != currentExercise.name
            && exercise.primaryMuscles == currentExercise.primaryMuscles
            && Set(exercise.secondaryMuscles).isDisjoint(with: currentExercise.secondaryMuscles)
            && !templateExerciseNames.contains(exercise.name)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current Exercise Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Exercise")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 16) {
                    Image(currentExercise.fullImagePath)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentExercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(musclesTextFormatted(exercise: currentExercise))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            // Picker to select between similar exercises and other exercises
            Picker("Exercise Type", selection: $selectedExerciseType) {
                ForEach(ExerciseType.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .padding(.top, -20)
            .padding(.bottom, -20)
            
            // Conditionally display the list based on the selected picker option
            if selectedExerciseType == .similar {
                if !similarExercises.isEmpty {
                    List(similarExercises) { exercise in
                        SimilarExerciseRowView(exercise: exercise, onReplace: {
                            let oldExercise = currentExercise
                            currentExercise = exercise
                            onExerciseReplaced(exercise)
                            setAlert(newExercise: exercise, oldExercise: oldExercise)
                        })
                    }
                    .listStyle(InsetGroupedListStyle())
                } else {
                    Text("No similar exercises found.")
                        .foregroundColor(.red)
                        .padding()
                }
            } else {
                if !otherExercises.isEmpty {
                    List(otherExercises) { exercise in
                        SimilarExerciseRowView(exercise: exercise, onReplace: {
                            let oldExercise = currentExercise
                            currentExercise = exercise
                            onExerciseReplaced(exercise)
                            setAlert(newExercise: exercise, oldExercise: oldExercise)
                        })
                    }
                    .listStyle(InsetGroupedListStyle())
                } else {
                    List {
                        Text("No other exercises found.")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Similar Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Template updated"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func setAlert(newExercise: Exercise, oldExercise: Exercise) {
        // Provide some feedback or show an alert to the user
        alertMessage = "Replaced '\(currentExercise.name)' with '\(newExercise.name)' in \(template.name)."
        showAlert = true
    }
    
    struct SimilarExerciseRowView: View {
        let exercise: Exercise
        let onReplace: () -> Void
        
        var body: some View {
            HStack(spacing: 16) {
                Image(exercise.fullImagePath)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(musclesTextFormatted(exercise: exercise))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Replace button
                Button(action: onReplace) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
}

func musclesTextFormatted(exercise: Exercise) -> Text {
    // Combine primary and secondary muscle engagements
    let allEngagements = exercise.primaryMuscleEngagements + exercise.secondaryMuscleEngagements
    
    // Map each muscle engagement to a Text object
    let muscleTexts = allEngagements.map { engagement -> Text in
        let muscleName = Text(engagement.muscleWorked.rawValue).bold() // Muscle name bold
        
        // Process submuscles using their simple name instead of rawValue
        let filteredSubMuscles = engagement.allSubMuscles
            .map { $0.simpleName } // Use simpleName instead of rawValue
            .joined(separator: ", ")
        
        if filteredSubMuscles.isEmpty {
            return muscleName // Only the muscle name if no submuscles exist
        } else {
            return muscleName + Text(": \(filteredSubMuscles)") // Bold muscle name with submuscles
        }
    }
    
    // Combine all Text objects into a single multiline Text object without leading newline
    guard let firstMuscleText = muscleTexts.first else { return Text("None") }
    return muscleTexts.dropFirst().reduce(firstMuscleText) { $0 + Text("\n") + $1 }
}
