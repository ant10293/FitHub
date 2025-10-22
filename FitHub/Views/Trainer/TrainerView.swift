import SwiftUI


struct TrainerView: View {
    @EnvironmentObject private var ctx: AppContext

    var body: some View {
        VStack {
            // use an enum instead?
            if !ctx.userData.setup.questionsAnswered {
                Questionnaire()
            } else if !ctx.userData.setup.isEquipmentSelected {
                EquipmentManagement()
            } else if !ctx.userData.setup.infoCollected {
                AssessmentView()
            } else {
                WorkoutPlan()
            }
        }
    }
}






