//
//  Questionnaire.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct Questionnaire: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var equipmentData: EquipmentData
    @State private var currentQuestionIndex: Int = 0
    @State private var answers: [String] = ["", "", "", ""]
    @State private var isPresenting: Bool = false
    @State private var showingPopup: Bool = false
    
    init(userData: UserData) {
        self.userData = userData
        
        if userData.questionAnswers.count == questions.count {
            _currentQuestionIndex = State(initialValue: questions.count-1)
            _answers = State(initialValue: userData.questionAnswers)
            _showingPopup = State(initialValue: true)
        }
    }
    
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
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                        
                        Spacer()
                        if answers[currentQuestionIndex] == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background(Color.blue)
                .cornerRadius(10)
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
                                userData.isFamiliarWithGym = answers[0] == "Yes"
                            userData.saveSingleVariableToFile(\.isFamiliarWithGym, for: .isFamiliarWithGym)
                            
                            case 2: // "How many days per week do you plan on exercising?"
                                if let workoutDays = Int(answers[2]) {
                                    userData.workoutDaysPerWeek = workoutDays
                                    userData.saveSingleVariableToFile(\.workoutDaysPerWeek, for: .workoutDaysPerWeek)
                                }
                            default:
                                break
                            }
                            // Then, proceed to the next question
                            currentQuestionIndex += 1
                    } else {
                        // Last question answered, proceed to equipment selection or final processing
                        equipmentData.selectEquipment(basedOn: answers[3]) // Assuming this is how you want to process the last answer
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
        .sheet(isPresented: $showingPopup) {
            EquipmentPopupView(onClose: {
                showingPopup = false
            }, onContinue: {
                showingPopup = false
                handleNavigation()
                EquipmentSelection(userData: userData, equipmentData: equipmentData).saveEquipment()
            }, onEdit: {
                showingPopup = false
                handleNavigation()
            })
        }.onAppear {
            if userData.questionAnswers.count == questions.count {
                equipmentData.selectEquipment(basedOn: answers[3]) // Assuming this is how you want to process the last answer
            }
        }
    }
    
    func handleNavigation() {
        userData.questionsAnswered = true
        userData.saveSingleVariableToFile(\.questionsAnswered, for: .questionsAnswered)
    }
    
    func processAnswers() {
        userData.questionAnswers = answers
        userData.saveSingleVariableToFile(\.questionAnswers, for: .questionAnswers)
        // determine the best split for the user based on goal and workoutDaysPerWeek
    }
}


