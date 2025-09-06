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
                                
                WeekView(userData: ctx.userData)
                
                /*
                 NavigationLink(destination: ViewMusclesView(userData: ctx.userData)) {
                    HStack {
                        Text("View Muscle Groups")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .font(.headline)
                            .fontWeight(.medium)
                        //Image(systemName: "figure.strengthtraining.traditional")
                        Image(systemName: "figure.wave")
                            .foregroundStyle(.gray)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 5)
                }
                .padding(.horizontal)
                */
                
                if !ctx.userData.workoutPlans.trainerTemplates.isEmpty {
                    NavigationLink(destination: LazyDestination { WorkoutGeneration() }) {
                        HStack {
                            Text("Workout Generation")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .font(.headline)
                                .fontWeight(.medium)
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.gray)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
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
                    RectangularButton(
                        title: "Generate Workout Plan",
                        systemImage: "square.and.pencil",
                        enabled: !ctx.userData.isWorkingOut,
                        width: .fit,
                        iconPosition: .trailing,
                        action: {
                            ctx.userData.generateWorkoutPlan(
                                exerciseData: ctx.exercises,
                                equipmentData: ctx.equipment,
                                keepCurrentExercises: false,
                                nextWeek: false,
                                onDone: {
                                    showingSaveConfirmation = true
                                }
                            )
                        }
                    )
                    .clipShape(Capsule())
                } else {
                    RectangularButton(
                        title: "Start Today's Workout",
                        systemImage: "dumbbell.fill",
                        enabled: !disableWorkoutButton,
                        width: .fit,
                        iconPosition: .trailing,
                        action: startWorkoutForDay
                    )
                    .clipShape(Capsule())
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
            .customToolbar(
                settingsDestination: { AnyView(SettingsView()) },
                menuDestination: { AnyView(MenuView()) }
            )
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
                            return CalendarUtility.shared.isDate(date, inSameDayAs: Date())
                        }
                        return false
                    }
                    proceedToWorkout()
                })
                Button("Trainer Template", action: {
                    selectedWorkoutTemplate = ctx.userData.workoutPlans.trainerTemplates.first { template in
                        if let date = template.date {
                            return CalendarUtility.shared.isDate(date, inSameDayAs: Date())
                        }
                        return false
                    }
                    proceedToWorkout()
                })
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    private var disableWorkoutButton: Bool {
        return ctx.userData.isWorkingOut || ctx.userData.sessionTracking.activeWorkout != nil
    }
    
    private func startWorkoutForDay() {
        let today = Date()
                
        // Find templates where `date` is not nil and matches today
        let userTemplate = ctx.userData.workoutPlans.userTemplates.first { template in
            if let date = template.date {
                if template.shouldDisableTemplate {
                    return false
                } else {
                    return CalendarUtility.shared.isDate(date, inSameDayAs: today)
                }
            }
            return false
        }
        
        let trainerTemplate = ctx.userData.workoutPlans.trainerTemplates.first { template in
            if let date = template.date {
                if template.shouldDisableTemplate {
                    return false
                } else {
                    return CalendarUtility.shared.isDate(date, inSameDayAs: today)
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
