import SwiftUI

/*
// FIXME: MASSIVE Slowdown when typing. WORST performance in whole app
struct SimilarExercises: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State var currentExercise: Exercise
    @State var template: WorkoutTemplate
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var selectedType: ExerciseType = .similar
    @State private var showDetails = false
    @State private var searchText: String = ""
    let onExerciseReplaced: (Exercise) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let width = screenWidth

            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(currentExercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Spacer()
                    Button("Close") { dismiss() }
                }
                HStack(spacing: 16) {
                    currentExercise.fullImageView(
                        favState: FavoriteState.getState(for: currentExercise, userData: ctx.userData)
                    )
                    .frame(width: width * 0.275)

                    Text("\(currentExercise.musclesTextFormatted)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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

            let baseList = isSearching ? searchResults : (isShowingSimilar ? similarList : otherList)
            let emptyMessage = isSearching
              ? "No matches."
              : (isShowingSimilar ? "No similar exercises found." : "No other exercises found.")

            if !baseList.isEmpty {
                List(baseList) { exercise in
                    SimilarExerciseRow(
                        userData: ctx.userData,
                        exercise: exercise,
                        baseExercise: currentExercise,
                        width: width,
                        onReplace: {
                            kbd.dismiss()
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
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
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

    // MARK: - Data sources (now all delegated to ExerciseData)
    private var availableEquipmentIDs: Set<GymEquipment.ID> { ctx.userData.evaluation.availableEquipment }

    /// Search results (global search; not constrained by similarity buckets)
    private var searchResults: [Exercise] {
        ctx.exercises.similarExercises(
            to: currentExercise,
            equipmentData: ctx.equipment,
            availableEquipmentIDs: availableEquipmentIDs,
            existing: template.exercises,
            searchText: searchText
        )
    }

    /// Similar list (no search)
    private var similarList: [Exercise] {
        ctx.exercises.similarExercises(
            to: currentExercise,
            equipmentData: ctx.equipment,
            availableEquipmentIDs: availableEquipmentIDs,
            existing: template.exercises,
            searchText: "" // empty → use similarity tiers
        )
    }
    
    private var otherList: [Exercise] {
        let simIDs = Set(similarList.map(\.id))

        return ctx.exercises.allExercises.filter { exercise in
            !simIDs.contains(exercise.id)
            && exercise.id != currentExercise.id
            && exercise.primaryMuscles == currentExercise.primaryMuscles
            && Set(exercise.secondaryMuscles).isDisjoint(with: currentExercise.secondaryMuscles)
            && !template.exerciseIDs.contains(exercise.id)
        }
    }
}

private struct SimilarExerciseRow: View {
    @State private var showDetails = false
    let userData: UserData
    let exercise: Exercise
    let baseExercise: Exercise          // used only for %-match math
    let width: CGFloat
    let onReplace: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ── top line ───────────────────────────────────────────────
            HStack(spacing: 12) {
                exercise.fullImageView(favState: FavoriteState.getState(for: exercise, userData: userData))
                    .frame(width: width * 0.125)
                
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
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)                // don’t steal tap-area from row
            }
            
            // ── expanded details ───────────────────────────────────────
            if showDetails {
                Text("\(exercise.musclesTextFormatted)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .transition(.opacity.combined(with: .slide))
            }
            
            // “View more / Hide details” toggle
            Button(showDetails ? "Hide details" : "View more") {
                withAnimation { showDetails.toggle() }
            }
            .font(.caption)
            .foregroundStyle(.blue)
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
*/
