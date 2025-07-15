//
//  AssessmentView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct AssessmentView: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(alignment: .center, spacing: 20) {
                Text("To ensure that your workouts are best tailored to you, please complete one or both of the options below:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing], 40)
                    .padding(.vertical)
                
                VStack(spacing: 16) {
                    
                    if !ctx.userData.setup.maxRepsEntered {
                        NavigationLink(value: "EnterMaxReps") {
                            Label("Enter Max Reps", systemImage: "flame.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .font(.headline)
                        }
                    }
                    
                    if !ctx.userData.setup.oneRepMaxesEntered {
                        NavigationLink(value: "EnterOneRepMaxes") {
                            Label("Enter One Rep Maxes", systemImage: "dumbbell")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .font(.headline)
                        }
                    }
                }
                .padding([.leading, .trailing], 20)
                                
                Spacer(minLength: 75)
                skipOrContinueButton
                    .disabled(!ctx.userData.setup.oneRepMaxesEntered && !ctx.userData.setup.maxRepsEntered)
                Spacer()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .navigationTitle("Tailor Your Workouts")
            .navigationBarBackButtonHidden()
            .onAppear(perform: checkCompletion)
            .navigationDestination(for: String.self) { route in
                switch route {
                case "EnterMaxReps":
                    EnterMaxReps(userData: ctx.userData, exerciseData: ctx.exercises, onFinish: {
                            navPath.removeLast()
                        }
                    )
                case "EnterOneRepMaxes":
                    EnterOneRepMaxes(userData: ctx.userData, exerciseData: ctx.exercises, onFinish: {
                            navPath.removeLast()
                        }
                    )
                default:
                    EmptyView()
                }
            }
        }
    }
    private func handleCompletion() {
        ctx.userData.setup.infoCollected = true
        ctx.userData.saveSingleStructToFile(\.setup, for: .setup)
        CSVLoader.estimateStrengthCategories(userData: ctx.userData, exerciseData: ctx.exercises)
        calculateFitnessLevel()
    }
    
    private var skipOrContinueButton: some View {
        Button(action: {
            handleCompletion()
        }) {
            Text(ctx.userData.setup.maxRepsEntered || ctx.userData.setup.oneRepMaxesEntered ? "Continue" : "Skip")
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(ctx.userData.setup.maxRepsEntered || ctx.userData.setup.oneRepMaxesEntered ? Color.green : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding([.leading, .trailing], 40)
        .padding(.bottom, 20)
    }
    
    private func checkCompletion() {
        if ctx.userData.setup.oneRepMaxesEntered && ctx.userData.setup.maxRepsEntered {
            handleCompletion()
        }
    }
    
    func calculateFitnessLevel() {
        // Reset fitness level score
        var fitnessLevelScore = 0
        
        // Evaluate questionnaire answers
        // Familiarity with gym equipment and techniques
        if let gymFamiliarity = ctx.userData.setup.questionAnswers[safe: 0], gymFamiliarity == "Yes" {
            fitnessLevelScore += 2
        } else if let gymFamiliarity = ctx.userData.setup.questionAnswers[safe: 0], gymFamiliarity == "Somewhat" {
            fitnessLevelScore += 1
        }
        
        // Currently following a structured workout program
        if let workoutHabit = ctx.userData.setup.questionAnswers[safe: 1], workoutHabit.starts(with: "Yes, I am currently following a structured workout program") {
            fitnessLevelScore += 3
        } else if let workoutConsistency = ctx.userData.setup.questionAnswers[safe: 1], workoutConsistency.contains("consistently") {
            fitnessLevelScore += 2
        } else if let workoutConsistency = ctx.userData.setup.questionAnswers[safe: 1], workoutConsistency.contains("occassionally") {
            fitnessLevelScore += 1
        }
        
        let isHealthyBMI = ctx.userData.currentMeasurementValue(for: .bmi) > 18.5 && ctx.userData.currentMeasurementValue(for: .bmi) < 25
        let isHealthyBodyFat = (ctx.userData.physical.gender == .male && ctx.userData.currentMeasurementValue(for: .bodyFatPercentage) <= 24) || (ctx.userData.physical.gender == .female && ctx.userData.currentMeasurementValue(for: .bodyFatPercentage) <= 31)
        
        if isHealthyBMI {
            fitnessLevelScore += 1
        }
        if isHealthyBodyFat {
            fitnessLevelScore += 1
        }
        
        /*// fix accuracy
         if ctx.userData.setup.oneRepMaxesEntered {
         let oneRepMaxTotal = ctx.userData.oneRepMaxBench + ctx.userData.oneRepMaxSquat + ctx.userData.oneRepMaxDeadlift
         if oneRepMaxTotal > 0 {
         fitnessLevelScore += 2
         }
         }
        // fix accuracy
        if ctx.userData.physicalAssessmentCompleted {
            // Evaluate physical assessment
            let assessmentTotal = ctx.userData.sitUpReps + ctx.userData.squatReps + ctx.userData.pushUpReps
            if assessmentTotal > 0 {
                fitnessLevelScore += 2
            }
        }*/
        ctx.userData.evaluation.fitnessScore = fitnessLevelScore
        ctx.userData.saveSingleStructToFile(\.evaluation, for: .evaluation)
    }
}
