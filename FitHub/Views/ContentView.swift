import SwiftUI
import Foundation


struct ContentView: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        if userData.setupState == .finished {
            MainAppView()
        } else {
            NavigationStack {
                VStack {
                    if userData.setupState == .welcomeView {
                        WelcomeView(userData: userData)
                    } else if userData.setupState == .healthKitView {
                        HealthKitRequestView(userData: userData)
                    } else if userData.setupState == .detailsView {
                        DetailsView(userData: userData)
                    } else {
                        GoalSelectionView(userData: userData)
                    }
                }
            }
        }
    }
}


