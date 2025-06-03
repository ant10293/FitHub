//
//  WorkoutPlan.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct WorkoutPlan: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var equipment: EquipmentData
    @EnvironmentObject var csvLoader: CSVLoader
    @EnvironmentObject var exerciseData: ExerciseData
    @EnvironmentObject var equipmentData: EquipmentData
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedWorkoutTemplate: WorkoutTemplate?
    @State private var isNavigationActive: Bool = false
    @State private var showingAlert: Bool = false
    @State private var showingSaveConfirmation: Bool = false
    @State private var progressiveOverload: Bool = false
    @State private var showingProgressiveOverloadInfo: Bool = false // State for showing the info view
    @State private var showingTemplateChoice: Bool = false
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    
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
                        .cornerRadius(8)
                        .overlay(WeekWorkoutView(userData: userData))
                        .padding(.horizontal)
                        .overlay(
                            WeekLegendView()
                                .padding(.top, 150)
                        ).frame(alignment: .center)
                }
                
                NavigationLink(destination: ViewMusclesView(userData: userData)) {
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
                    .cornerRadius(8)
                    .shadow(radius: 5)
                }
                .padding(.horizontal)
                
                if !userData.trainerTemplates.isEmpty {
                    NavigationLink(destination: WorkoutGeneration(userData: userData, exerciseData: exerciseData, equipmentData: equipmentData, csvLoader: csvLoader)) {
                        HStack {
                            Text("Workout Generation")
                            // .foregroundColor(.black)
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
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                if userData.trainerTemplates.isEmpty {
                    // Button to generate workout plan
                    Button(action: {
                        userData.generateWorkoutPlan(exerciseData: exerciseData, equipmentData: equipmentData, csvLoader: csvLoader, keepCurrentExercises: false, selectedExerciseType: userData.exerciseType, nextWeek: false)
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
                    Button(action: {
                        startWorkoutForDay()
                    }) {
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
                            StartedWorkoutView(viewModel: WorkoutViewModel(template: selectedTemplate))
                        }
                    }
                }
                Spacer()
            }
            .blur(radius: showingProgressiveOverloadInfo ? 5 : 0)
            .disabled(showingProgressiveOverloadInfo)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Trainer")
            .onAppear {
                progressiveOverload = userData.progressiveOverload
            }
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
            .sheet(isPresented: $showingProgressiveOverloadInfo, content: {
                infoView
            })
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
                    selectedWorkoutTemplate = userData.userTemplates.first { template in
                        if let date = template.date {
                            return Calendar.current.isDate(date, inSameDayAs: Date())
                        }
                        return false
                    }
                    proceedToWorkout()
                })
                Button("Trainer Template", action: {
                    selectedWorkoutTemplate = userData.trainerTemplates.first { template in
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
        return timerManager.timerIsActive || userData.activeWorkout != nil
    }
    
    private func startWorkoutForDay() {
        let today = Date()
        let calendar = Calendar.current
                
        // Find templates where `date` is not nil and matches today
        let userTemplate = userData.userTemplates.first { template in
            if let date = template.date {
                if WorkoutTemplate.shouldDisableTemplate(template: template) {
                    return false
                } else {
                    return calendar.isDate(date, inSameDayAs: today)
                }
            }
            return false
        }
        
        let trainerTemplate = userData.trainerTemplates.first { template in
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
    
    private var infoView: some View {
        VStack {
            Text("Progressive Overload")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 10)
            
            Text("Progressive overload is the gradual increase of stress placed upon the body during exercise training. This principle is essential for improving physical fitness, strength, and muscle mass.")
            //.font(.body)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
            
            
            Text("Enabling this feature allows your workout templates to be adjusted weekly in order to accommodate your changing strength levels.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
            
            
            Button(action: {
                showingProgressiveOverloadInfo = false
            }) {
                Text("Got it")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(width: 375)
    }
}
