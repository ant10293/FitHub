import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct WelcomeView: View {
    @ObservedObject var userData: UserData
   // @EnvironmentObject var userData: UserData
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    private let auth = AuthService()

    var body: some View {
        ZStack {
            // Background color to cover the entire screen
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
                
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150, alignment: .topLeading)
                    .padding(.vertical, 25)
                
                SignInWithAppleButton(.signIn) { req in
                   req.requestedScopes = [.email, .fullName]
                 } onCompletion: { result in
                   auth.signIn(with: result, into: userData) { res in
                     switch res {
                     case .success:
                         handleNavigation(saveSingleVar: true)
                     case .failure(let err):
                       print("Sign-in failed: \(err)")
                     }
                   }
                 }
                .frame(width: 280, height: 50)
                .padding(.vertical, 5)
                
                HStack {
                    Line()
                    Text("or")
                        .bold()
                    Line()
                }
                .frame(width: 280, height: 1)
                .padding(.vertical, 5)
                
                Button("Continue without Account") {
                    userData.allowedCredentials = false
                    handleNavigation(saveSingleVar: false)
                }
                .bold()
                .frame(width: 280, height: 50)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(8)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Welcome")
    }
    
    struct Line: View {
        var body: some View {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.horizontal, 5)
        }
    }
    
    func handleNavigation(saveSingleVar: Bool) {
        userData.setupState = .healthKitView
        if saveSingleVar {
            userData.saveSingleVariableToFile(\.setupState, for: .setupState)
        } else {
            userData.saveToFile()
        }
    }
}
