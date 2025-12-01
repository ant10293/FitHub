//
//  ProgressiveOverloadView.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/5/24.
//

import SwiftUI

struct OverloadCalculator: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var selectedWeek: Int = 1
    @State private var weekExerciseMap: [Int: [Exercise]] = [:] // Map weeks to processed exercises
    let template: WorkoutTemplate

    var body: some View {
        ZStack {
              Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
                
            VStack {
                // Week Picker
                HStack {
                    Text("Week")
                        .fontWeight(.semibold)
                        .font(.subheadline)
                        .padding(.leading)
                    
                    Picker("Select Week", selection: $selectedWeek) {
                        ForEach(1...ctx.userData.settings.progressiveOverloadPeriod, id: \.self) { week in
                            Text("\(week)")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .onChange(of: selectedWeek) { updateProcessedExercises() }
                    .onChange(of: ctx.userData.settings) { updateProcessedExercises(changed: true) }
                    .onChange(of: ctx.userData.workoutPlans) { updateProcessedExercises(changed: true) }
                }
                
                if let processedExercises = weekExerciseMap[selectedWeek] {
                    let previousWeekExercises = weekExerciseMap[selectedWeek - 1] ?? [] // Safely fetch previous week
                    TemplateOverload(processedExercises: processedExercises, previousWeekExercises: previousWeekExercises, templateName: template.name)
                }
            }
        }
        .onAppear { updateProcessedExercises() }
        .navigationBarTitle("Progressive Overload", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: LazyDestination { OverloadSettingsView(userData: ctx.userData, fromCalculator: true) }) {
                    Image(systemName: "slider.horizontal.3")
                        .imageScale(.large)
                        .padding()
                }
            }
        }
    }
    
    private func updateProcessedExercises(changed: Bool = false) {
        if changed { weekExerciseMap.removeAll() }
        // Initialize week 0 with the base exercises if it hasn't been initialized yet
        if weekExerciseMap[0] == nil {
            weekExerciseMap[0] = template.exercises.map { exercise in
                var baseExercise = exercise
                baseExercise.overloadProgress = 0
                baseExercise.setDetails = exercise.setDetails // Original details are preserved here
                return baseExercise
            }
        }
        
        // Process all weeks up to the selected week
        for week in 1...selectedWeek {
            //print("\nDebug: Processing week \(week)")
            
            // Only process if not already cached
            if weekExerciseMap[week] == nil {
                //print("Debug: No cached data for week \(week), processing...")
                
                //weekExerciseMap[week] = template.exercises.map { exercise in
                if let weekZeroExercises = weekExerciseMap[0] {
                    weekExerciseMap[week] = weekZeroExercises.map { exercise in
                    var newExercise = exercise
                                                        
                    // Update overload progress based on the week
                    newExercise.overloadProgress = week
                    //print("Debug: Updated overloadProgress for exercise \(exercise.name) to \(week)")
                    
                    // Apply progressive overload to set details
                    _ = newExercise.applyProgressiveOverload(
                        equipmentData: ctx.equipment,
                        period:   ctx.userData.settings.progressiveOverloadPeriod,
                        style:    ctx.userData.settings.progressiveOverloadStyle,
                        rounding: ctx.userData.settings.roundingPreference,
                        overloadFactor: ctx.userData.settings.customOverloadFactor ?? 1.0
                    )
                    //print("Debug: Applied progressive overload to \(exercise.name), new set details: \(newExercise.setDetails)")
                    
                    return newExercise
                    }
                }
            } else {
                //print("Debug: Using cached data for week \(week)")
            }
        }
    }
}
