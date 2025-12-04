import SwiftUI
import HealthKit


struct HealthKitRequestView: View {
    @AppStorage(UnitSystem.storageKey) var unit: UnitSystem = .metric
    @ObservedObject var userData: UserData
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
            unit = UnitSystem.preferredUnitSystem()
            healthKit.requestAuthorization(userData: userData)
        }
    }
}
