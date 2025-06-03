import SwiftUI


struct TrainerView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var equipmentData: EquipmentData
    
    var body: some View {
        VStack {
            if !userData.questionsAnswered {
                Questionnaire(userData: userData)
            } else if !userData.isEquipmentSelected {
                EquipmentSelection(userData: userData, equipmentData: equipmentData)
            } else if !userData.infoCollected {
                AssessmentView()
            } else {
                WorkoutPlan()
            }
        }
        .navigationBarTitle("Trainer")
    }
}







