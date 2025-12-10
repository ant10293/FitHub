//
//  Questionnaire.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct Questionnaire: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var currentQuestionIndex: Int = 0
    @State private var answers: [String] = ["", "", "", "", ""]
    @State private var showingPopup: Bool = false
    
    let questions = [
        "Are you familiar with gym equipment and exercise techniques?",
        "How long have you been training (consistently)?",
        "Are you currently following a structured workout program?",
        "How many days per week do you plan on exercising?",
        "What equipment do you have access to?"
    ]
    
    let options = [
        ["Yes", "Somewhat", "No"],
        ["< 3 months", "3–12 months", "1–3 years", "3–5 years", "5+ years"],
        ["Yes, I am currently following a structured workout program", "I work out consistently but without a structured plan", "I work out occasionally but without a structured plan", "No, I do not work out at all"],
        ["3", "4", "5", "6"],
        ["All (Gym Membership)", "Some (Home Gym)", "None (Bodyweight Only)"]
    ]
    
    var body: some View {
        VStack {
            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                .font(.headline)
            Text(questions[currentQuestionIndex])
                .font(.title)
                .padding()
                .multilineTextAlignment(.center)
            
            ForEach(options[currentQuestionIndex], id: \.self) { option in
                Button(action: {
                    answers[currentQuestionIndex] = option
                }) {
                    HStack {
                        Text(option)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Spacer()
                        if answers[currentQuestionIndex] == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            HStack {
                Button(action: {
                    if currentQuestionIndex > 0 {
                        currentQuestionIndex -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Previous")
                    }
                }
                .disabled(currentQuestionIndex == 0)
                
                Spacer()
                Button(action: {
                    if currentQuestionIndex < questions.count - 1 {
                        // Before moving to the next question, save answers if needed
                        switch currentQuestionIndex {
                            case 0: // "Are you familiar with gym equipment and exercise techniques?"
                            if let firstAnswer = answers.first {
                                ctx.userData.evaluation.isFamiliarWithGym = firstAnswer == "Yes"
                            }
                            
                            case 3: // "How many days per week do you plan on exercising?"
                                if answers.count > 3, let workoutDays = Int(answers[3]) {
                                    ctx.userData.workoutPrefs.workoutDaysPerWeek = workoutDays
                                }
                            default:
                                break
                            }
                            // Then, proceed to the next question
                            currentQuestionIndex += 1
                    } else {
                        // Last question answered, proceed to equipment selection or final processing
                        updateSelectedEquipment()
                        ctx.userData.setup.questionAnswers = answers
                        showingPopup = true
                    }
                }) {
                    HStack {
                        Text(currentQuestionIndex != questions.count - 1 ? "Next" : "Select Equipment")
                        Image(systemName: "arrow.right")
                    }
                }
                .disabled(answers[currentQuestionIndex].isEmpty) // Disable button if no answer is selected
                
            }
            .padding()
        }
        .padding()
        .onAppear(perform: initializeQuestions)
        .sheet(isPresented: $showingPopup) {            
            EquipmentPopupView(
                selectedEquipment: ctx.equipment.equipmentObjects(for: ctx.userData.evaluation.availableEquipment),
                onClose: {
                    showingPopup = false
                },
                onContinue: {
                    showingPopup = false
                    ctx.userData.setup.isEquipmentSelected = true
                    handleNavigation()
                },
                onEdit: {
                    showingPopup = false
                    handleNavigation()
                }
            )
        }
    }
    
    private func initializeQuestions() {
        // already answered
        if ctx.userData.setup.questionAnswers.count == questions.count {
            currentQuestionIndex = questions.count - 1
            answers = ctx.userData.setup.questionAnswers
            updateSelectedEquipment()
            showingPopup = true
        }
    }
    
    private func updateSelectedEquipment() {
        if answers.count > 4 {
            let equipment = ctx.equipment.selectEquipment(basedOn: answers[4])
            ctx.userData.evaluation.availableEquipment = Set(equipment.map(\.id))
        }
    }
    
    private func handleNavigation() {
        ctx.userData.setup.questionsAnswered = true
        ctx.userData.saveToFile()
    }
}


