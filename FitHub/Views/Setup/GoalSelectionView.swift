import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var userData: UserData
    @State private var userGoal: FitnessGoal?
    @State private var bmi: Double = 0
    @State private var alertType: AlertType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if userData.setupState == .goalView {
                Text("Your BMI is: \(String(format: "%.2f", bmi))")
                    .font(.headline)
                
                BMICategoryTable(userBMI: bmi)
                    .frame(height: 60)
                
                Text("  Recommended goal: \(recommendedGoal.name)  ")
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            
            if userData.setupState == .finished {
                Text("  Current goal: \(userData.goal.name)  ")
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Please select a goal:")
                    .font(.callout)
                    .fontWeight(.semibold)
                
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalButton(goal: goal, isSelected: userGoal == goal) {
                        userGoal = goal
                    }
                }
            }
            
            Button(userData.setupState == .finished ? "Update Goal" : "Complete Setup") {
                alertType = userData.setupState == .finished ? .update : .complete
            }
            .disabled(userGoal == nil)
            .padding()
            .foregroundColor(.white)
            .background(userGoal != nil ? Color.blue : Color.gray)
            .cornerRadius(10)
            .centerHorizontally()
        }
        .padding()
        .onAppear {
            if userData.setupState == .goalView {
                let calculatedBMI = calculateBMI(heightInches: userData.heightInches, heightFeet: userData.heightFeet, weight: userData.currentMeasurementValue(for: .weight))
                bmi = calculatedBMI
            }
        }
        .navigationBarTitle("Goal Selection")
        .alert(item: $alertType) { type -> Alert in
            switch type {
            case .complete:
                return Alert(
                    title: Text("Setup Completed!"),
                    message: Text("Your goal has been updated. You can change this anytime in the Menu within the 'Home' Tab."),
                    dismissButton: .default(Text("OK")) {
                        updateUserGoal()
                    }
                )
            case .update:
                return Alert(
                    title: Text("Goal Updated!"),
                    message: Text("Your goal has been updated. You can change this anytime."),
                    dismissButton: .default(Text("OK")) {
                        if let goal = userGoal {
                            userData.goal = goal
                            userData.saveSingleVariableToFile(\.goal, for: .goal)
                        }
                    }
                )
            }
        }
    }
    private enum AlertType: Identifiable {
        case complete
        case update
        
        var id: Int {
            self.hashValue
        }
    }
    private func updateUserGoal() {
        if let goal = userGoal {
            userData.updateMeasurementValue(for: .bmi, with: bmi, shouldSave: false)
            userData.setupState = .finished
            userData.goal = goal
            userData.saveToFile()
        }
    }

    private func calculateBMI(heightInches: Int, heightFeet: Int, weight: Double) -> Double {
        let h = Double(heightInches)
        let f = Double(heightFeet)
        
        let height = (f * 12) + h
        let w = Double(weight)
        
        return (w / (height * height)) * 703
    }
    private var recommendedGoal: FitnessGoal {
        recommendGoalBasedOnBMI(bmi: bmi)
    }
    
    private func recommendGoalBasedOnBMI(bmi: Double) -> FitnessGoal {
        switch bmi {
        case ..<18.5:
            return .buildMuscle
        case 18.5..<25.0:
            return .getStronger
        case 25.0...:
            return .buildMuscleGetStronger
        default:
            return .getStronger
        }
    }
}


struct GoalButton: View {
    var goal: FitnessGoal
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Text(goal.name)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                    .centerHorizontally()
                
                Text(goal.shortDescription)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .blue)
                    .centerHorizontally()
                
                Text(goal.detailDescription)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black : .gray)
                    .centerHorizontally()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
            .cornerRadius(8)
        }
    }
}



