import SwiftUI
import HealthKit


struct HealthKitRequestView: View {
    @ObservedObject var userData: UserData
   // @EnvironmentObject var userData: UserData
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.colorScheme) var colorScheme
    @State var userName: String = ""
    @State private var localUserName: String = ""
    @State private var isPrimaryColor: Bool = true


    init(userData: UserData) {
        self.userData = userData
        _userName = State(initialValue: userData.userName)
    }

    var body: some View {
        VStack {
            if userData.allowedCredentials {
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
                .frame(width: 150, height: 150, alignment: .topLeading)
            
            if !userData.allowedCredentials  {
                TextField("Enter your name here", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Get Started") {
                    userData.userName = userName
                    userData.saveSingleVariableToFile(\.userName, for: .userName)
                    requestAuth()
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
            if userData.allowedCredentials {
                requestAuth()
            }
        }
    }
    
    func isDataAvailable() -> Bool {
        return userData.heightFeet > 0 && userData.currentMeasurementValue(for: .weight) > 0
    }
    
    var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    func requestAuth() {
        healthKitManager.requestAuthorization {
            // start polling on the main thread
            DispatchQueue.main.async {
                self.pollForHeight()
            }
        }
    }

    private func pollForHeight() {
        let totalInches = healthKitManager.totalInches

        // Make sure we have both a height & a DOB before proceeding
        guard totalInches > 0,
              let dob = healthKitManager.dob
        else {
            // Not ready yet → retry in 0.5 s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pollForHeight()
            }
            return
        }

        // ✅ We’ve got valid data—process it once and stop polling
        let feet   = totalInches / 12
        let inches = totalInches % 12
        
        userData.dob          = dob
        userData.heightFeet   = Int(feet)
        userData.heightInches = Int(inches)

        userData.updateMeasurementValue(for: .weight, with: Double(healthKitManager.weight), shouldSave: false)
        userData.setupState = .detailsView
        userData.saveToFile()
    }

    func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation {
                isPrimaryColor.toggle()
            }
        }
    }
}







