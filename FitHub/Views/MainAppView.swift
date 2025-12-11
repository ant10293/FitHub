import SwiftUI

struct MainAppView: View {
    @ObservedObject var userData: UserData
    @Binding var showResumeWorkoutOverlay: Bool
    @State private var selectedTab = 0
    @State private var lockedTab: Int? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                WorkoutsView(showResumeWorkoutOverlay: $showResumeWorkoutOverlay)
                    .tabItem {
                        Label("Workouts", systemImage: "list.dash")
                    }
                    .tag(0)

                HistoryView(userData: userData)
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
                    .tag(1)

                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(2)

                TrainerView()
                    .tabItem {
                        Label("Trainer", systemImage: "person.crop.circle")
                    }
                    .tag(3)

                CalculatorView()
                    .tabItem {
                        Label("Calculator", systemImage: "sum")
                    }
                    .tag(4)
            }
            .sheet(isPresented: $userData.showingChangelog) {
                if let changelog = userData.currentChangelog {
                    WorkoutChangelogView(changelog: changelog)
                }
            }
            .sheet(isPresented: $userData.showingGenerationWarning) {
                if let reductions = userData.workoutChanges, let creation = userData.workoutPlans.workoutsCreationDate {
                    GenerationWarning(workoutChanges: reductions)
                        .id(creation)
                }
            }
            .sheet(isPresented: $userData.showPremiumPrompt) {
                FreePlanLimitView()
            }
            .onChange(of: selectedTab) {
                if userData.disableTabView {
                    selectedTab = lockedTab ?? 0
                } else {
                    lockedTab = selectedTab
                }
            }

            if userData.disableTabView {
                Color.clear
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false) // Let TabView reject tab switches, not this layer
            }
        }
        .generatingOverlay(userData.isGeneratingWorkout)
    }
}




