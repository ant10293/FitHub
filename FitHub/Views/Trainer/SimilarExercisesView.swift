import SwiftUI

struct SimilarExercisesView: View {
    @Environment(\.presentationMode) var presentationMode
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
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 16) {
                    currentExercise.fullImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                    Text("\(currentExercise.musclesTextFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    SimilarExerciseRowView(
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
                        .foregroundColor(.red)
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
    
    struct SimilarExerciseRowView: View {
        @State private var showDetails = false
        let exercise: Exercise
        let baseExercise: Exercise          // used only for %-match math
        let onReplace: () -> Void           // 🔵 arrow button only!
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // ── top line ───────────────────────────────────────────────
                HStack(spacing: 12) {
                    exercise.fullImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .minimumScaleFactor(0.75)
                        
                        // %-similar badge
                        Text("\(similarityPercent)% similarity")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Button(action: onReplace) {              // <-- ONLY this triggers replace
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)                // don’t steal tap-area from row
                }
                
                // ── expanded details ───────────────────────────────────────
                if showDetails {
                    Text("\(exercise.musclesTextFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .transition(.opacity.combined(with: .slide))
                }
                
                // “View more / Hide details” toggle
                Button(showDetails ? "Hide details" : "View more") {
                    withAnimation { showDetails.toggle() }
                }
                .font(.caption)
                .foregroundColor(.blue)
                .buttonStyle(.plain)                         // keeps entire row passive
            }
            .padding(.vertical, 4)
        }
        
        // quick similarity heuristic: (# shared muscles) / (# union) × 100
        private var similarityPercent: Int {
            let sharedPrimaries   = exercise.primaryMuscles == baseExercise.primaryMuscles
                ? baseExercise.primaryMuscles.count : 0
            let sharedSecondaries = Set(exercise.secondaryMuscles).intersection(baseExercise.secondaryMuscles).count
            let shared  = sharedPrimaries + sharedSecondaries
            let union   = Set(exercise.primaryMuscles + exercise.secondaryMuscles
                            + baseExercise.primaryMuscles + baseExercise.secondaryMuscles).count
            
            return union == 0 ? 0 : Int((Double(shared) / Double(union)) * 100.0)
        }
    }
}



