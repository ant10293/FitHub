import SwiftUI


struct TrainerView: View {
    @EnvironmentObject private var ctx: AppContext

    var body: some View {
        VStack {
            if !ctx.userData.setup.questionsAnswered {
                Questionnaire()
            } else if !ctx.userData.setup.isEquipmentSelected {
                EquipmentSelection(selection: ctx.userData.evaluation.equipmentSelected)
            } else if !ctx.userData.setup.infoCollected {
                AssessmentView()
            } else {
                WorkoutPlan()
            }
        }
    }
}







