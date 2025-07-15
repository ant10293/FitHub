import SwiftUI



struct MainAppView: View {
    @ObservedObject var userData: UserData
    @Binding var showResumeWorkoutOverlay: Bool
    
    var body: some View {
        TabView {
            WorkoutsView(showResumeWorkoutOverlay: $showResumeWorkoutOverlay)
                .tabItem {
                    Label("Workouts", systemImage: "list.dash")
                }
            HistoryView(userData: userData)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            TrainerView()
                .tabItem {
                    Label("Trainer", systemImage: "person.crop.circle")
                }
            CalculatorView()
                .tabItem {
                    Label("Calculator", systemImage: "sum")
                }
        }
    }
}






