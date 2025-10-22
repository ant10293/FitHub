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
                let width = UIScreen.main.bounds.width * 0.8
                
                Text("To ensure that your workouts are best tailored to you, please complete one or both of the options below:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(width: width)
                    .padding(.vertical)
                
                VStack(spacing: 16) {
                    if !ctx.userData.setup.maxRepsEntered {
                        NavigationLink(value: ViewOption.enterMaxReps) {
                            RectangularLabel(title: "Enter Max Reps", systemImage: "flame.fill", bgColor: .red, fgColor: .white, bold: true)
                        }
                    }
                    
                    if !ctx.userData.setup.oneRepMaxesEntered {
                        NavigationLink(value: ViewOption.enterOneRepMaxes) {
                            RectangularLabel(title: "Enter One Rep Maxes", systemImage: "dumbbell", bgColor: .blue, fgColor: .white, bold: true)
                        }
                    }
                }
                .padding(.horizontal)
                                
                Spacer(minLength: 24)

                // NEW: warning if neither input was provided
                if needsEstimate {
                    WarningFooter(
                        message: "No 1RM or Max Reps entered. We'll estimate your strength level from your answers; accuracy will be limited.",
                        width: width
                    )
                }
                                
                skipOrContinueButton

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
    
    private var skipOrContinueButton: some View {
        RectangularButton(
            title: (ctx.userData.setup.maxRepsEntered || ctx.userData.setup.oneRepMaxesEntered) ? "Continue" : "Skip",
            bgColor: (ctx.userData.setup.maxRepsEntered || ctx.userData.setup.oneRepMaxesEntered) ? Color.green : Color.gray,
            action: handleCompletion
        )
        .padding(.horizontal)
    }
    
    private var needsEstimate: Bool {
        !ctx.userData.setup.oneRepMaxesEntered && !ctx.userData.setup.maxRepsEntered
    }
    
    private enum ViewOption: Hashable { case enterMaxReps, enterOneRepMaxes }
    
    private func handleCompletion() {
        ctx.userData.setup.infoCollected = true
        if !needsEstimate {
            CSVLoader.estimateStrengthCategories(userData: ctx.userData, exerciseData: ctx.exercises)
        } else {
            calculateFitnessLevel()
        }
        ctx.exercises.seedEstimatedMaxes(userData: ctx.userData)
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
        var score = 0
        
        // Familiarity with gym equipment and techniques
        if let gymFamiliarity = questionAnswers[safe: 0] {
            if gymFamiliarity == "Yes" {
                score += 2
            } else if gymFamiliarity == "Somewhat" {
                score += 1
            } else if gymFamiliarity == "No" {
                score -= 1
            }
        }
        
        // Training Experience
        if let experience = questionAnswers[safe: 1] {
            if experience == "< 3 months" {
                score -= 1
            } else if experience == "3-12 months" {
                score += 1
            } else if experience == "1-3 years" {
                score += 2
            } else if experience == "3-5 years" {
                score += 3
            } else if experience == "5+ years" {
                score += 4
            }
        }
        
        // Currently following a structured workout program
        if let workoutHabit = questionAnswers[safe: 2] {
            if workoutHabit.starts(with: "Yes, I am currently following a structured workout program") {
                score += 3
            } else if workoutHabit.contains("consistently") {
                score += 2
            } else if workoutHabit.contains("occasionally") {
                score += 1
            } else if workoutHabit.contains("No") {
                score -= 1
            }
        }
        
        let isHealthyBMI = bmi > 18.5 && bmi < 25
        let isHealthyBodyFat = (gender == .male && bfPct <= 24) || (gender == .female && bfPct <= 31)
        
        if isHealthyBMI { score += 1 }
        if isHealthyBodyFat, bfPct > 0 { score += 1 }
        
        // Max = 11
        let strengthLvl: StrengthLevel
        switch score {
        case Int.min...1: strengthLvl = .beginner
        case 2...3: strengthLvl = .novice
        case 4...6: strengthLvl = .intermediate
        case 7...9: strengthLvl = .advanced
        default: strengthLvl = .elite
        }
        
        ctx.userData.evaluation.fitnessScore = score
        ctx.userData.evaluation.strengthLevel = strengthLvl
    }
}
