//
//  CompletedWorkouts.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct CompletedWorkouts: View {
    @ObservedObject var userData: UserData
    @State private var isEditing: Bool = false
    @State private var showingSortPicker: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var selectedSortOption: CompletedWorkoutSortOption = .mostRecent
    @State private var workoutToDelete: CompletedWorkout?
    
    var body: some View {
        VStack(spacing: 0) {
            if sortedWorkouts.isEmpty {
                emptyWorkoutsView
            } else {
                HStack {
                    Text("Sort by").bold()
                        .padding(.trailing)
                    Picker("", selection: $selectedSortOption) {
                        ForEach(CompletedWorkoutSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.trailing)
                    .disabled(sortedWorkouts.isEmpty)
                }
                .padding(.top)
                .zIndex(0)
                
                List {
                    ForEach(sortedWorkouts) { workout in
                        if !workout.template.exercises.isEmpty {
                            let categories = SplitCategory.concatenateCategories(for: workout.template.categories)
                            HStack {
                                NavigationLink(destination: LazyDestination { CompletedDetails(workout: workout, categories: categories) }) {
                                    if isEditing {
                                        Button(action: {
                                            workoutToDelete = workout
                                            showingDeleteConfirmation = true
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(workout.name)
                                            .font(.headline)
                                        if !categories.isEmpty {
                                            Text(categories)
                                        }
                                        Text("Date: \(Format.formatDate(workout.date, dateStyle: .medium, timeStyle: .none))")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                        Text("Duration: \(Format.formatDuration(workout.duration, roundSeconds: true))")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                    }
                                    .padding(.vertical, 5)
                                }
                                
                            }
                        }
                    }
                }
                .confirmationDialog(
                    "Are you sure you want to delete this workout?",
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        if let workout = workoutToDelete {
                            deleteWorkout(workout)
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        workoutToDelete = nil
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("Completed Workouts", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "Done" : "Edit")
                }
                .disabled(sortedWorkouts.isEmpty)
            }
        }
    }
    
    // MARK: – Empty state
    private var emptyWorkoutsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .symbolRenderingMode(.hierarchical)
                .font(.system(.largeTitle, weight: .regular))
                .foregroundStyle(.secondary)

            Text("No completed workouts yet...")
                .font(.title3.weight(.semibold))

            Text("Start your FitHub journey today!")
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var sortedWorkouts: [CompletedWorkout] {
        let workouts: [CompletedWorkout]
        
        switch selectedSortOption {
        case .mostRecent:
            workouts = userData.workoutPlans.completedWorkouts.sorted { $0.date > $1.date }
            
        case .leastRecent:
            workouts = userData.workoutPlans.completedWorkouts.sorted { $0.date < $1.date }
            
        case .thisMonth:
            let currentMonth = CalendarUtility.shared.month(from: Date())
            workouts = userData.workoutPlans.completedWorkouts.filter {
                CalendarUtility.shared.month(from: $0.date) == currentMonth
            }
            
        case .longestDuration:
            workouts = userData.workoutPlans.completedWorkouts.sorted { $0.duration > $1.duration }
            
        case .shortestDuration:
            workouts = userData.workoutPlans.completedWorkouts.sorted { $0.duration < $1.duration }
        }
        
        return workouts.filter { !$0.template.exercises.isEmpty }
    }
    
    private func deleteWorkout(_ workout: CompletedWorkout) {
        if let index = userData.workoutPlans.completedWorkouts.firstIndex(where: { $0.id == workout.id}) {
            print("Removing workout: \(workout.name)")
            // remove the exercises instead of the entire completed workout, since we need the data in CompletedWorkouts for reference
            userData.workoutPlans.completedWorkouts[index].template.exercises = []
            print("Workout Deleted!")
            userData.saveSingleStructToFile(\.workoutPlans, for: .workoutPlans)
        }
    }
}
