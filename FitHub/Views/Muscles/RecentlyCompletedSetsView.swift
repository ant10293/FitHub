//
//  RecentlyCompletedSetsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import SwiftUI

struct RecentlyCompletedSetsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userData: UserData
    var muscle: SubMuscles
    var onClose: () -> Void
    
    var recentlyWorkedSets: [ExerciseWithSetDetails] {
        userData.workoutPlans.completedWorkouts.flatMap { workout in
            workout.template.exercises.compactMap { exercise in
                let sets = exercise.setDetails.filter { set in
                    (set.repsCompleted ?? 0) > 0
                    && exercise.allSubMuscles?.contains(muscle) == true
                }
                return sets.isEmpty ? nil : ExerciseWithSetDetails(exerciseName: exercise.name, sets: sets, usesWeight: exercise.type.usesWeight, completionDate: workout.date)
            }
        }.filter { $0.completionDate > Date().addingTimeInterval(-Double(userData.settings.muscleRestDuration) * 60 * 60) }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !recentlyWorkedSets.isEmpty {
                        ForEach(recentlyWorkedSets, id: \.self) { exerciseWithSetDetails in
                            Section {
                                ForEach(exerciseWithSetDetails.sets) { setDetail in
                                    VStack(alignment: .leading) {
                                        Text("Set \(setDetail.setNumber)")
                                            .font(.subheadline)
                                        HStack {
                                            Text("Reps: \(setDetail.repsCompleted ?? 0)")
                                            if exerciseWithSetDetails.usesWeight {
                                                Text("Weight: \(setDetail.weight, specifier: "%.2f") lbs")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.gray)
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
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        Text("No recently worked sets for this submuscle.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("\(muscle.rawValue)", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundColor(.gray)
                            .contentShape(Rectangle())
                    }
                }
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
