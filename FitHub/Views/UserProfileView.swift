import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct UserProfileView: View {
    @ObservedObject var userData: UserData
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil
    @State private var showSignInWithApple = false
    @State private var isKeyboardVisible: Bool = false
    private let auth = AuthService()
    
    var body: some View {
        ZStack {
            Color(isUserLoggedIn ? UIColor.clear : UIColor.secondarySystemBackground)
                .ignoresSafeArea()
            
            VStack {
                if isUserLoggedIn {
                    Form {
                        Section(header: Text("FitHub Username")) {
                            TextField("Enter username", text: $userData.userName)
                        }
                        
                        Section(header: Text("Personal Information")) {
                            TextField("First Name", text: $userData.firstName)
                            TextField("Last Name", text: $userData.lastName)
                        }
                        
                        if userData.allowedCredentials {
                            Section(header: Text("Email")) {
                                Text(userData.email)
                            }
                        }
                    }.scrollDisabled(true)
                    
                    if let creationDate = userData.accountCreationDate {
                        Text("Account Created: \(formatDate(creationDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                    }
                    
                    Button(action: { logOut() }) {
                        if !isKeyboardVisible {
                            Text(userData.allowedCredentials ? "Logout" : "Login")
                                .frame(maxWidth: 300)
                                .padding()
                                .background(userData.allowedCredentials ? Color.red : Color.green)
                                .foregroundColor(Color.white)
                                .cornerRadius(10)
                                .font(.headline)
                                .centerHorizontally()
                                .padding(.bottom, 100)
                        }
                    }
                    .onDisappear {
                        updateProfile()
                    }
                } else {
                    VStack {
                        Text("Please sign in to continue")
                            .font(.title)
                            .padding()
                        
                        SignInWithAppleButton(.signIn) { req in
                            req.requestedScopes = [.email, .fullName]
                          } onCompletion: { result in
                            auth.signIn(with: result, into: userData) { res in
                              switch res {
                              case .success:
                                self.isUserLoggedIn = true
                                updateProfile()
                                // copy any @State fields if needed
                              case .failure(let err):
                                print("Sign-in failed: \(err)")
                              }
                            }
                          }
                        .frame(width: 280, height: 50)
                        .padding()
                    }
                }
            }
            // Custom Alert View
            if showingAlert {
                CustomAlertView(message: alertMessage, isPresented: $showingAlert)
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: updateProfile) {
                    Text("Save")
                }
            }
        }
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func updateProfile() {
        UIApplication.shared.endEditing()
        // Update the user's profile information
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        let firstName: String = userData.firstName
        let lastName: String = userData.lastName

        changeRequest?.displayName = "\(firstName) \(lastName)"
        changeRequest?.commitChanges { error in
            if let error = error {
                alertMessage = "Failed to update profile: \(error.localizedDescription)"
            } else {
                alertMessage = "Profile updated successfully."
            }
            showingAlert = true
        }
    }
    
    private func logOut() {
        do {
            try Auth.auth().signOut()
            //userData.allowedCredentials = false
            userData.accountCreationDate = nil
            userData.firstName = ""
            userData.lastName = ""
            userData.email = ""
            userData.saveToFile()
            self.isUserLoggedIn = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

// Custom Alert View
struct CustomAlertView: View {
    var message: String
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    
    var body: some View {
        VStack {
            Text("Profile Update")
                .font(.headline)
                .padding()
            Text(message)
                .padding()
            
            Button(action: {
                isPresented = false
                
            }) {
                Text("OK")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 250)
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

