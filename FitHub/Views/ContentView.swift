import SwiftUI
import Foundation


struct ContentView: View {
    @EnvironmentObject private var ctx: AppContext
    @ObservedObject var notifications = NotificationManager.shared
    @State private var showResumeWorkoutOverlay: Bool = false
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        Group {
            if ctx.userData.setup.setupState == .finished {
                MainAppView(userData: ctx.userData, showResumeWorkoutOverlay: $showResumeWorkoutOverlay)
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        guard !ctx.userData.isWorkingOut else { return }
                        if oldPhase == .active, newPhase == .inactive {
                            ctx.userData.saveToFile()
                        }
                    }
                    // should also clear passed planned dates and notis
                    // need to do this on a background thread
                    .onAppear {
                       // ctx.exercises.testCSVs(userData: ctx.userData)
                        notifications.requestIfNeeded(onUpdate: { allowed in
                            ctx.userData.settings.workoutReminders = allowed
                        })
                        NotificationManager.printAllPendingNotifications()
                        ctx.adjustments.loadAllAdjustments(for: ctx.exercises.allExercises, equipment: ctx.equipment, availableEquipment: ctx.userData.evaluation.availableEquipment)
                        if ctx.userData.sessionTracking.activeWorkout != nil { showResumeWorkoutOverlay = true }
                        ctx.userData.checkAndUpdateAge()
                        generateTemplates()
                        ctx.userData.saveToFile()
                    }
            } else {
                NavigationStack {
                    if ctx.userData.setup.setupState == .welcomeView {
                        WelcomeView()
                    } else if ctx.userData.setup.setupState == .healthKitView {
                        HealthKitRequestView(userData: ctx.userData)
                    } else if ctx.userData.setup.setupState == .detailsView {
                        DetailsView(userData: ctx.userData)
                    } else {
                        GoalSelectionView(userData: ctx.userData)
                    }
                }
            }
        }
    }

    private func generateTemplates() {
        let plannedWorkoutDates = ctx.userData.getAllPlannedWorkoutDates()
        if checkAndResetWorkoutStreak(plannedWorkoutDates: plannedWorkoutDates), ctx.userData.settings.progressiveOverload {
            generateNewWorkoutTemplates(plannedWorkoutDates: plannedWorkoutDates)
       }
    }

    private func generateNewWorkoutTemplates(plannedWorkoutDates: [Date]) {
        let currentDate = Date()

        // Ensure all planned workout dates are past, considering the end of the day
        let allDatesArePast = plannedWorkoutDates.allSatisfy { plannedDate in
            if let endOfDay = CalendarUtility.shared.date(bySettingHour: 23, minute: 59, second: 59, of: plannedDate) {
                return endOfDay < currentDate
            }
            return false
        }

        if allDatesArePast {
            // only generate if we are updating existing templates
            if !ctx.userData.workoutPlans.trainerTemplates.isEmpty {
                ctx.userData.generateWorkoutPlan(
                    exerciseData: ctx.exercises,
                    equipmentData: ctx.equipment,
                    keepCurrentExercises: true,
                    nextWeek: true,
                    shouldSave: false,
                    generationDisabled: ctx.disableCreatePlan
                )
            }
        } else {
            print("No past dates found. No need to generate a new workout plan.")
        }
    }

    private func checkAndResetWorkoutStreak(plannedWorkoutDates: [Date]) -> Bool {
        print("Checking population Date...")
        guard let populatedDate = ctx.userData.workoutPlans.workoutsCreationDate else {
            print("No populated date found. Exiting check.")
            return false
        }
        let currentDate = Date()
        print("Current Date: \(currentDate)")
        print("Populated Date: \(populatedDate)")

        let filteredPlannedWorkoutDates = plannedWorkoutDates.filter { $0 >= populatedDate }

        for plannedDate in filteredPlannedWorkoutDates {
            print("Checking planned date: \(plannedDate)")
            if plannedDate < currentDate && !CalendarUtility.shared.isDateInToday(plannedDate) {
                print("Resetting workout streak to 0.")
                ctx.userData.sessionTracking.workoutStreak = 0
                return true
            }
        }
       print("No reset needed.")
       return true
    }
}
