//
//  WorkoutPlan.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct WorkoutPlan: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @EnvironmentObject private var ctx: AppContext
    @State private var selectedWorkoutTemplate: WorkoutTemplate?
    @State private var isNavigationActive: Bool = false
    @State private var showingAlert: Bool = false
    @State private var showingSaveConfirmation: Bool = false
    @State private var showingTemplateChoice: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // MARK: - SubscriptionView
                //NavigationLink(destination: SubscriptionView()) {
                
                VStack(alignment: .leading) {
                    Text("This Week's Workouts")
                        .font(.headline)
                        .padding(.leading)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(WeekWorkoutView(userData: ctx.userData))
                        .padding(.horizontal)
                        .overlay(
                            WeekLegendView()
                                .padding(.top, 150)
                        ).frame(alignment: .center)
                }
                
                NavigationLink(destination: ViewMusclesView(userData: ctx.userData)) {
                    HStack {
                        Text("View Muscle Groups")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.headline)
                            .fontWeight(.medium)
                        //Image(systemName: "figure.strengthtraining.traditional")
                        Image(systemName: "figure.wave")
                            .foregroundColor(.gray)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 5)
                }
                .padding(.horizontal)
                
                if !ctx.userData.workoutPlans.trainerTemplates.isEmpty {
                    NavigationLink(destination: WorkoutGeneration()) {
                        HStack {
                            Text("Workout Generation")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.headline)
                                .fontWeight(.medium)
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                if ctx.userData.workoutPlans.trainerTemplates.isEmpty {
                    Button(action: {
                        ctx.userData.generateWorkoutPlan(exerciseData: ctx.exercises, equipmentData: ctx.equipment, keepCurrentExercises: false, nextWeek: false)
                        showingSaveConfirmation = true
                    }) {
                        HStack {
                            Text("Generate Workout Plan")
                                .foregroundColor(.white)
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.white)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                } else {
                    // Button to start today's workout
                    Button(action: startWorkoutForDay) {
                        HStack {
                            Text("Start Today's Workout")
                                .foregroundColor(.white)
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(.white)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(shouldDisableWorkoutButton() ? Color.gray : Color.blue)
                        .clipShape(Capsule())
                    }
                    .disabled(shouldDisableWorkoutButton())
                    .navigationDestination(isPresented: $isNavigationActive) {
                        if let selectedTemplate = selectedWorkoutTemplate {
                            StartedWorkoutView(viewModel: WorkoutVM(template: selectedTemplate))
                        }
                    }
                }
                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Trainer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .padding()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MenuView()) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
            .alert(isPresented: $showingSaveConfirmation) {
                Alert(
                    title: Text("Workout Plan Generated!"),
                    message: Text("These templates can be edited in the 'Workouts' Tab."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("No Workouts Today"),
                    message: Text("There are no workouts planned for today."),
                    dismissButton: .default(Text("Okay"))
                )
            }
            .alert("Multiple Workouts Found for Today", isPresented: $showingTemplateChoice) {
                Button("User Template", action: {
                    selectedWorkoutTemplate = ctx.userData.workoutPlans.userTemplates.first { template in
                        if let date = template.date {
                            return Calendar.current.isDate(date, inSameDayAs: Date())
                        }
                        return false
                    }
                    proceedToWorkout()
                })
                Button("Trainer Template", action: {
                    selectedWorkoutTemplate = ctx.userData.workoutPlans.trainerTemplates.first { template in
                        if let date = template.date {
                            return Calendar.current.isDate(date, inSameDayAs: Date())
                        }
                        return false
                    }
                    proceedToWorkout()
                })
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    private func shouldDisableWorkoutButton() -> Bool {
        return ctx.userData.isWorkingOut || ctx.userData.sessionTracking.activeWorkout != nil
    }
    
    private func startWorkoutForDay() {
        let today = Date()
        let calendar = Calendar.current
                
        // Find templates where `date` is not nil and matches today
        let userTemplate = ctx.userData.workoutPlans.userTemplates.first { template in
            if let date = template.date {
                if WorkoutTemplate.shouldDisableTemplate(template: template) {
                    return false
                } else {
                    return calendar.isDate(date, inSameDayAs: today)
                }
            }
            return false
        }
        
        let trainerTemplate = ctx.userData.workoutPlans.trainerTemplates.first { template in
            if let date = template.date {
                if WorkoutTemplate.shouldDisableTemplate(template: template) {
                    return false
                } else {
                    return calendar.isDate(date, inSameDayAs: today)
                }
            }
            return false
        }
        
        // Handle different cases based on whether templates are found
        switch (userTemplate, trainerTemplate) {
        case (let user?, nil):
            selectedWorkoutTemplate = user
            proceedToWorkout()
        case (nil, let trainer?):
            selectedWorkoutTemplate = trainer
            proceedToWorkout()
        case (_?, _?):
            showingTemplateChoice = true // Triggers the alert for choosing the template
        case (nil, nil):
            // Handle the case when there are no workouts
            selectedWorkoutTemplate = nil
            showingAlert = true
        }
    }
    
    private func proceedToWorkout() {
        isNavigationActive = true
        print("Starting workout for template: \(selectedWorkoutTemplate?.name ?? "Unknown")")
    }
}
