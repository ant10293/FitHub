import SwiftUI
import HealthKit


struct HealthKitRequestView: View {
    @AppStorage(UnitSystem.storageKey) var unit: UnitSystem = .metric
    @ObservedObject var userData: UserData
    @StateObject private var healthKit = HealthKitManager()
    @State var userName: String = ""
    @State private var localUserName: String = ""
    @State private var updatedDOB: Bool = false
    @State private var updatedWeight: Bool = false

    var body: some View {
        VStack {
            if allowedCredentials {
                Text("Loading...")
                    .font(.headline)
            }
            
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.5)  // ≈ 1/2 screen

            if !allowedCredentials  {
                TextField("Enter your name here", text: $userName)
                    .padding()
                    .roundedBackground(cornerRadius: 10, color: Color(UIColor.secondarySystemBackground))
                    .padding()
                
                RectangularButton(title: "Get Started", enabled: !userName.isEmpty, width: .fit, action: {
                    userData.profile.userName = userName
                    healthKit.requestAuthorization(userData: userData)
                })
                .clipShape(Capsule())
            }
        }
        .navigationBarBackButtonHidden(true) // Hiding the back button
        .onAppear {
            if allowedCredentials {
                unit = UnitSystem.preferredUnitSystem()
                healthKit.requestAuthorization(userData: userData)
            } else {
                userName = userData.profile.userName
            }
        }
    }
    
    private var allowedCredentials: Bool { userData.settings.allowedCredentials }
}







