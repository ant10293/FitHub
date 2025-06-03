//
//  AssessmentView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct AssessmentView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var csvLoader: CSVLoader
    @EnvironmentObject var exerciseData: ExerciseData
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
                    
                    if !userData.maxRepsEntered {
                        NavigationLink(value: "EnterMaxReps") {
                            Label("Enter Max Reps", systemImage: "flame.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.headline)
                        }
                    }
                    
                    if !userData.oneRepMaxesEntered {
                        NavigationLink(value: "EnterOneRepMaxes") {
                            Label("Enter One Rep Maxes", systemImage: "dumbbell")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.headline)
                        }
                    }
                }
                .padding([.leading, .trailing], 20)
                                
                Spacer(minLength: 75)
                skipOrContinueButton
                    .disabled(!userData.oneRepMaxesEntered && !userData.maxRepsEntered)
                Spacer()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .navigationTitle("Tailor Your Workouts")
            .navigationBarBackButtonHidden()
            .onAppear {
                checkCompletion()
            }
            .navigationDestination(for: String.self) { route in
                switch route {
                case "EnterMaxReps":
                    EnterMaxReps(userData: userData, exerciseData: exerciseData, onFinish: {
                            navPath.removeLast()
                        }
                    )
                case "EnterOneRepMaxes":
                    EnterOneRepMaxes(userData: userData, exerciseData: exerciseData, onFinish: {
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
        userData.infoCollected = true
        userData.saveSingleVariableToFile(\.infoCollected, for: .infoCollected)
        _ = csvLoader.estimateStrengthCategories(userData: userData, exerciseData: exerciseData)
        calculateFitnessLevel()
    }
    
    private var skipOrContinueButton: some View {
        Button(action: {
            handleCompletion()
        }) {
            Text(userData.maxRepsEntered || userData.oneRepMaxesEntered ? "Continue" : "Skip")
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(userData.maxRepsEntered || userData.oneRepMaxesEntered ? Color.green : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding([.leading, .trailing], 40)
        .padding(.bottom, 20)
    }
    
    private func checkCompletion() {
        if userData.oneRepMaxesEntered && userData.maxRepsEntered {
            handleCompletion()
        }
    }
    
    func calculateFitnessLevel() {
        // Reset fitness level score
        var fitnessLevelScore = 0
        
        // Evaluate questionnaire answers
        // Familiarity with gym equipment and techniques
        if let gymFamiliarity = userData.questionAnswers[safe: 0], gymFamiliarity == "Yes" {
            fitnessLevelScore += 2
        } else if let gymFamiliarity = userData.questionAnswers[safe: 0], gymFamiliarity == "Somewhat" {
            fitnessLevelScore += 1
        }
        
        // Currently following a structured workout program
        if let workoutHabit = userData.questionAnswers[safe: 1], workoutHabit.starts(with: "Yes, I am currently following a structured workout program") {
            fitnessLevelScore += 3
        } else if let workoutConsistency = userData.questionAnswers[safe: 1], workoutConsistency.contains("consistently") {
            fitnessLevelScore += 2
        } else if let workoutConsistency = userData.questionAnswers[safe: 1], workoutConsistency.contains("occassionally") {
            fitnessLevelScore += 1
        }
        
        let isHealthyBMI = userData.currentMeasurementValue(for: .bmi) > 18.5 && userData.currentMeasurementValue(for: .bmi) < 25
        let isHealthyBodyFat = (userData.gender == .male && userData.currentMeasurementValue(for: .bodyFatPercentage) <= 24) || (userData.gender == .female && userData.currentMeasurementValue(for: .bodyFatPercentage) <= 31)
        
        if isHealthyBMI {
            fitnessLevelScore += 1
        }
        if isHealthyBodyFat {
            fitnessLevelScore += 1
        }
        
        /*// fix accuracy
         if userData.oneRepMaxesEntered {
         let oneRepMaxTotal = userData.oneRepMaxBench + userData.oneRepMaxSquat + userData.oneRepMaxDeadlift
         if oneRepMaxTotal > 0 {
         fitnessLevelScore += 2
         }
         }
        // fix accuracy
        if userData.physicalAssessmentCompleted {
            // Evaluate physical assessment
            let assessmentTotal = userData.sitUpReps + userData.squatReps + userData.pushUpReps
            if assessmentTotal > 0 {
                fitnessLevelScore += 2
            }
        }*/
        userData.fitnessScore = fitnessLevelScore
        userData.saveSingleVariableToFile(\.fitnessScore, for: .fitnessScore)
    }
}
