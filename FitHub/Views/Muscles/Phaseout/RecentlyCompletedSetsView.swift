//
//  RecentlyCompletedSetsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//
/*
import SwiftUI

struct RecentlyCompletedSetsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    var muscle: SubMuscles
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !recentlyWorkedSets.isEmpty {
                        ForEach(recentlyWorkedSets, id: \.self) { exerciseWithSetDetails in
                            Section {
                                ForEach(exerciseWithSetDetails.sets) { setDetail in
                                    VStack(alignment: .leading) {
                                        setDetail.formattedCompletedText(usesWeight: exerciseWithSetDetails.usesWeight)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 5)
                                }
                            } header: {
                                VStack(alignment: .leading) {
                                    Text(exerciseWithSetDetails.exerciseName)
                                        .font(.headline)
                                        .padding(.vertical, 5)
                                    Text("Completed on: \(Format.formatDate(exerciseWithSetDetails.completionDate, dateStyle: .short, timeStyle: .short))")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                    } else {
                        Text("No recently worked sets for this submuscle.")
                            .foregroundStyle(.gray)
                            .padding()
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("\(muscle.rawValue)", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(.gray)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
    
    private var recentlyWorkedSets: [ExerciseWithSetDetails] {
        let cutoff = Date().addingTimeInterval(-Double(userData.settings.muscleRestDuration) * 3600)

        return userData.workoutPlans.completedWorkouts
            .filter { $0.date > cutoff }
            .flatMap { workout in
                workout.template.exercises.compactMap { exercise in
                    // only exercises that hit this muscle
                    guard exercise.allSubMuscles?.contains(muscle) == true else { return nil }

                    // only sets with a non-zero completion
                    let sets = exercise.setDetails.filter { set in
                        guard let c = set.completed else { return false }
                        switch c {
                        case .reps(let r): return r > 0
                        case .hold(let t): return t.inSeconds > 0
                        }
                    }

                    return sets.isEmpty
                        ? nil
                        : ExerciseWithSetDetails(
                            exerciseName: exercise.name,
                            sets: sets,
                            usesWeight: exercise.type.usesWeight,
                            completionDate: workout.date
                        )
                }
            }
    }

    
    // for filtering rest calculation
    struct ExerciseWithSetDetails: Identifiable, Hashable {
        var id = UUID()
        var exerciseName: String
        var sets: [SetDetail]
        var usesWeight: Bool
        var completionDate: Date
    }
}
*/
