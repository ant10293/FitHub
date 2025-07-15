import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var userData: UserData
    @State private var userGoal: FitnessGoal?
    @State private var bmi: Double = 0
    @State private var alertType: AlertType?
    
    var body: some View {
        VStack(alignment: .leading) {
            bmiGoalSection()
            selectGoalSection()
            
            ActionButton(title: userData.setup.setupState == .finished ? "Update Goal" : "Complete Setup", enabled: userGoal != nil, action: {
                alertType = userData.setup.setupState == .finished ? .update : .complete
            })
            .clipShape(Capsule())
            .padding(.bottom)
        }
        .padding()
        .onAppear {
            if userData.setup.setupState == .goalView {
                let calculatedBMI = BMI.calculateBMI(heightInches: userData.physical.heightInches, heightFeet: userData.physical.heightFeet, weight: userData.currentMeasurementValue(for: .weight))
                bmi = calculatedBMI
            }
        }
        .navigationTitle("Goal Selection")
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
                            userData.physical.goal = goal
                            userData.saveSingleStructToFile(\.physical, for: .physical)
                        }
                    }
                )
            }
        }
    }
    
    @ViewBuilder private func bmiGoalSection() -> some View {
        if userData.setup.setupState == .goalView {
            Text("Your BMI is: \(String(format: "%.2f", bmi))")
                .font(.headline)
            
            BMICategoryTable(userBMI: bmi)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.1)  // ≈ 1/3 screen

            Text("  Recommended goal: \(recommendedGoal.name)  ")
                .font(.subheadline)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
        } else if userData.setup.setupState == .finished {
            Text("  Current goal: \(userData.physical.goal.name)  ")
                .font(.subheadline)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    @ViewBuilder private func selectGoalSection() -> some View {
        Text("Please select a goal:")
            .font(.callout)
            .fontWeight(.semibold)
            .padding(.top)
        
        ScrollView {
            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                GoalButton(
                    goal: goal,
                    isSelected: userGoal == goal
                ) { userGoal = goal }
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)  // ≈ 1/2 screen
    }
    
    private enum AlertType: Identifiable {
        case complete, update
        
        var id: Int { self.hashValue }
    }
    
    private func updateUserGoal() {
        if let goal = userGoal {
            userData.updateMeasurementValue(for: .bmi, with: bmi, shouldSave: false)
            userData.setup.setupState = .finished
            userData.physical.goal = goal
            userData.saveToFile()
        }
    }
    
    private var recommendedGoal: FitnessGoal { BMI.recommendGoalBasedOnBMI(bmi: bmi) }
    
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}






