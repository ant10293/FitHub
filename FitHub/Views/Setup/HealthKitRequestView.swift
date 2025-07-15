import SwiftUI
import HealthKit


struct HealthKitRequestView: View {
    @Environment(\.colorScheme) var colorScheme
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
                    .foregroundColor(isPrimaryColor ? primaryColor : secondaryColor)
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
                
                Button("Get Started") {
                    userData.profile.userName = userName
                    userData.saveSingleStructToFile(\.profile, for: .profile)
                    healthKit.requestAuthorization(userData: userData)
                }
                .foregroundColor(.white)
                .padding()
                .background(userName.isEmpty ? Color.gray : Color.black) // Disable the visual of the button when userName is empty
                .disabled(userName.isEmpty) // Disable the button when userName is empty
                .clipShape(Capsule())
            }
        }
        .navigationBarBackButtonHidden(true) // Hiding the back button
        .onAppear {
            if userData.settings.allowedCredentials {
                healthKit.requestAuthorization(userData: userData)
            } else {
                userName = userData.profile.userName
            }
        }
    }
    
    var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryColor: Color {
        colorScheme == .dark ? .black : .white
    }

    func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation {
                isPrimaryColor.toggle()
            }
        }
    }
}







