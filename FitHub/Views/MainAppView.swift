import SwiftUI

struct MainAppView: View {
    @ObservedObject var userData: UserData
    @Binding var showResumeWorkoutOverlay: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
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
            .sheet(item: $userData.premiumFeatureBlocked) { feature in
                FreePlanLimitView(feature: feature)
            }
        }
        .generatingOverlay(userData.isGeneratingWorkout)
    }
}




