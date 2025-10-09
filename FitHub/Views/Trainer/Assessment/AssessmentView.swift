//
//  AssessmentView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct AssessmentView: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var navPath: [ViewOption] = []

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
                        NavigationLink(value: ViewOption.enterMaxReps) {
                            Label("Enter Max Reps", systemImage: "flame.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .font(.headline)
                        }
                    }
                    
                    if !ctx.userData.setup.oneRepMaxesEntered {
                        NavigationLink(value: ViewOption.enterOneRepMaxes) {
                            Label("Enter One Rep Maxes", systemImage: "dumbbell")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .font(.headline)
                        }
                    }
                }
                .padding([.leading, .trailing], 20)
                                
                Spacer(minLength: 75)
                
                /*
                Text("Enter max reps and/or one rep maxes to continue")
                    .font(.caption)
                    .foregroundStyle(.red)
                */
                
                skipOrContinueButton
                    .disabled(!ctx.userData.setup.oneRepMaxesEntered && !ctx.userData.setup.maxRepsEntered)
                
                Spacer()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .navigationTitle("Tailor Your Workouts")
            .navigationBarBackButtonHidden()
            .onAppear(perform: checkCompletion)
            .navigationDestination(for: ViewOption.self) { route in
                switch route {
                case .enterMaxReps:
                    EnterMaxReps(userData: ctx.userData, exerciseData: ctx.exercises, onFinish: { navPath.removeLast() })
                case .enterOneRepMaxes:
                    EnterOneRepMaxes(userData: ctx.userData, exerciseData: ctx.exercises, onFinish: { navPath.removeLast() })
                }
            }
        }
    }
    
    private enum ViewOption: Hashable { case enterMaxReps, enterOneRepMaxes }
    
    private func handleCompletion() {
        ctx.userData.setup.infoCollected = true
        //ctx.userData.saveSingleStructToFile(\.setup, for: .setup)
        CSVLoader.estimateStrengthCategories(userData: ctx.userData, exerciseData: ctx.exercises)
        calculateFitnessLevel()
    }
    
    private var skipOrContinueButton: some View {
        Button(action: {
            handleCompletion()
        }) {
            Text(ctx.userData.setup.maxRepsEntered || ctx.userData.setup.oneRepMaxesEntered ? "Continue" : "Skip")
                .foregroundStyle(.white)
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
        let bmi = ctx.userData.currentMeasurementValue(for: .bmi).displayValue
        let bfPct = ctx.userData.currentMeasurementValue(for: .bodyFatPercentage).displayValue
        let gender = ctx.userData.physical.gender
        let questionAnswers = ctx.userData.setup.questionAnswers
        
        // Reset fitness level score
        var fitnessLevelScore = 0
        
        // Evaluate questionnaire answers
        // Familiarity with gym equipment and techniques
        if let gymFamiliarity = questionAnswers[safe: 0], gymFamiliarity == "Yes" {
            fitnessLevelScore += 2
        } else if let gymFamiliarity = questionAnswers[safe: 0], gymFamiliarity == "Somewhat" {
            fitnessLevelScore += 1
        }
        
        // Currently following a structured workout program
        if let workoutHabit = questionAnswers[safe: 1], workoutHabit.starts(with: "Yes, I am currently following a structured workout program") {
            fitnessLevelScore += 3
        } else if let workoutConsistency = questionAnswers[safe: 1], workoutConsistency.contains("consistently") {
            fitnessLevelScore += 2
        } else if let workoutConsistency = questionAnswers[safe: 1], workoutConsistency.contains("occassionally") {
            fitnessLevelScore += 1
        }
        
        let isHealthyBMI = bmi > 18.5 && bmi < 25
        let isHealthyBodyFat = (gender == .male && bfPct <= 24) || (gender == .female && bfPct <= 31)
        
        if isHealthyBMI {
            fitnessLevelScore += 1
        }
        if isHealthyBodyFat {
            fitnessLevelScore += 1
        }
        
        ctx.userData.evaluation.fitnessScore = fitnessLevelScore
        //ctx.userData.saveSingleStructToFile(\.evaluation, for: .evaluation)
    }
}
