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
    @State private var answers: [String] = ["", "", "", ""]
    @State private var isPresenting: Bool = false
    @State private var showingPopup: Bool = false
    
    let questions = [
        "Are you familiar with gym equipment and exercise techniques?",
        "Are you currently following a structured workout program?",
        "How many days per week do you plan on exercising?",
        "What equipment do you have access to?"
    ]
    
    let options = [
        ["Yes", "Somewhat", "No"],
        ["Yes, I am currently following a structured workout program", "No, I do not workout at all", "I workout consistently but without a structured plan", "I workout occasionally but without a structured plan"],
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
                                //ctx.userData.saveSingleStructToFile(\.evaluation, for: .evaluation)
                            }
                            
                            case 2: // "How many days per week do you plan on exercising?"
                                if answers.count > 2, let workoutDays = Int(answers[2]) {
                                    ctx.userData.workoutPrefs.workoutDaysPerWeek = workoutDays
                                    //ctx.userData.saveSingleStructToFile(\.workoutPrefs, for: .workoutPrefs)
                                }
                            default:
                                break
                            }
                            // Then, proceed to the next question
                            currentQuestionIndex += 1
                    } else {
                        // Last question answered, proceed to equipment selection or final processing
                        updateSelectedEquipment()
                        processAnswers()
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
                selectedEquipment: ctx.equipment.equipmentObjects(for: ctx.userData.evaluation.equipmentSelected),
                onClose: {
                    showingPopup = false
                },
                onContinue: {
                    showingPopup = false
                    ctx.userData.setup.isEquipmentSelected = true
                    //ctx.userData.saveToFile()
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
        if ctx.userData.setup.questionAnswers.count == questions.count {
            currentQuestionIndex = questions.count - 1
            answers = ctx.userData.setup.questionAnswers
            updateSelectedEquipment()
            showingPopup = true
        }
    }
    
    private func updateSelectedEquipment() {
        if answers.count > 3 {
            let equipment = ctx.equipment.selectEquipment(basedOn: answers[3])
            ctx.userData.evaluation.equipmentSelected = equipment.map(\.id)
        }
    }
    
    private func handleNavigation() {
        ctx.userData.setup.questionsAnswered = true
       // ctx.userData.saveSingleStructToFile(\.setup, for: .setup)
    }
    
    private func processAnswers() {
        ctx.userData.setup.questionAnswers = answers
        //ctx.userData.saveSingleStructToFile(\.setup, for: .setup)
    }
}


