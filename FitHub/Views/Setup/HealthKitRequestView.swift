import SwiftUI
import HealthKit


struct HealthKitRequestView: View {
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var healthKit = HealthKitManager()

    var body: some View {
        VStack {
            Text("Loading...")
                .font(.headline)

            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: screenWidth * 0.5)  // ≈ 1/2 screen
        }
        .navigationBarBackButtonHidden(true) // Hiding the back button
        .onAppear {
            ctx.unitSystem = UnitSystem.preferredUnitSystem()
            healthKit.requestAuthorization(userData: ctx.userData)
        }
    }
}
