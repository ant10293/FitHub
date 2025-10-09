import SwiftUI
import HealthKit


struct HealthKitRequestView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage(UnitSystem.storageKey) var unit: UnitSystem = .metric
    @ObservedObject var userData: UserData
    @StateObject private var healthKit = HealthKitManager()
    @State var userName: String = ""
    @State private var localUserName: String = ""
    @State private var isPrimaryColor: Bool = true
    @State private var updatedDOB: Bool = false
    @State private var updatedWeight: Bool = false

    var body: some View {
        VStack {
            if userData.settings.allowedCredentials {
                Text("Loading...")
                    .font(.headline)
                    .foregroundStyle(isPrimaryColor ? primaryColor : secondaryColor)
                    .onAppear {
                        startBlinking()
                    }
            }
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.5)  // ≈ 1/2 screen

            if !userData.settings.allowedCredentials  {
                TextField("Enter your name here", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                RectangularButton(title: "Get Started", enabled: !userName.isEmpty, action: {
                    userData.profile.userName = userName
                    //userData.saveSingleStructToFile(\.profile, for: .profile)
                    healthKit.requestAuthorization(userData: userData)
                })
                .clipShape(Capsule())
            }
        }
        .navigationBarBackButtonHidden(true) // Hiding the back button
        .onAppear {
            if userData.settings.allowedCredentials {
                unit = UnitSystem.preferredUnitSystem()
                healthKit.requestAuthorization(userData: userData)
            } else {
                userName = userData.profile.userName
            }
        }
    }
    
    private var primaryColor: Color { colorScheme == .dark ? .white : .black }
    
    private var secondaryColor: Color { colorScheme == .dark ? .black : .white }

    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation {
                isPrimaryColor.toggle()
            }
        }
    }
}







