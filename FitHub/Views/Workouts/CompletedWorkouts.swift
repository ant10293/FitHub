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
    @State private var selectedSortOption: CompletedWorkoutSortOption = .mostRecent
    @State private var showingSortPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var workoutToDelete: CompletedWorkout?
    
    var body: some View {
        Group {
            if userData.completedWorkouts.isEmpty {
                VStack {
                    Image(systemName: "figure.walk")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    Text("No completed workouts yet...")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    
                    Text("Start your fitness journey today!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                VStack {
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
                    }
                    .padding(.bottom, -10)
                    .padding(.top)
                    .zIndex(0)
                    
                    List {
                        ForEach(sortedWorkouts) { workout in
                            let categories = SplitCategory.concatenateCategories(for: workout.template.categories)
                            HStack {
                                NavigationLink(
                                    destination: CompletedDetails(workout: workout, categories: categories)
                                ) {
                                    if isEditing {
                                        Button(action: {
                                            // deleteWorkout(workout)
                                            workoutToDelete = workout
                                            showingDeleteConfirmation = true
                                        }) {
                                            Image(
                                                systemName: "minus.circle.fill"
                                            )
                                            .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(workout.name)
                                            .font(.headline)
                                        if !categories.isEmpty {
                                            Text(categories)
                                        }
                                        Text("Date: \(workout.date, formatter: dateFormatter)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text(
                                            "Duration: \(workout.duration / 60) minutes"
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .confirmationDialog(
                    "Are you sure you want to delete this workout?",
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        if let workout = workoutToDelete {
                            deleteWorkout(workout)
                        }
                        //isEditing = false
                    }
                    Button("Cancel", role: .cancel) {
                        workoutToDelete = nil
                    }
                }
            }
        }
        .navigationTitle("Completed Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "Done" : "Edit")
                }
                .disabled(sortedWorkouts.isEmpty)
            }
        }
    }
    
    private var sortedWorkouts: [CompletedWorkout] {
        switch selectedSortOption {
        case .mostRecent:
            return userData.completedWorkouts.sorted { $0.date > $1.date }
        case .leastRecent:
            return userData.completedWorkouts.sorted { $0.date < $1.date }
        case .thisMonth:
            let currentMonth = Calendar.current.component(.month, from: Date())
            return userData.completedWorkouts.filter {
                Calendar.current
                    .component(.month, from: $0.date) == currentMonth
            }
        case .longestDuration:
            return userData.completedWorkouts
                .sorted { $0.duration > $1.duration }
        case .shortestDuration:
            return userData.completedWorkouts
                .sorted { $0.duration < $1.duration }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        //  formatter.dateStyle = .full
        return formatter
    }
    
    private func deleteWorkout(_ workout: CompletedWorkout) {
        if let index = userData.completedWorkouts.firstIndex(
            where: { $0.id == workout.id
            }) {
            print("Removing workout: \(workout.name)")
            userData.completedWorkouts.remove(at: index)
        }
        print("Workout Deleted!")
        userData.saveSingleVariableToFile(\.completedWorkouts, for: .completedWorkouts)
    }
}
