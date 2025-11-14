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
                    // should also clear passed planned dates and notis
                    // need to do this on a background thread
                    .onAppear {
                        //ctx.exercises.testCSVs(userData: ctx.userData)
                        notifications.requestIfNeeded(onUpdate: { allowed in
                            ctx.userData.settings.allowedNotifications = allowed
                        })
                        NotificationManager.printAllPendingNotifications()
                        ctx.adjustments.loadAllAdjustments(for: ctx.exercises.allExercises, allEquipment: ctx.equipment.allEquipment)
                        if ctx.userData.sessionTracking.activeWorkout != nil { showResumeWorkoutOverlay = true }
                        if ctx.userData.setup.infoCollected { determineStrengthAndSeedMaxes() }
                        ctx.userData.checkAndUpdateAge()
                        generateTemplates()
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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            guard !ctx.userData.isWorkingOut else { return }
            if oldPhase == .active, newPhase == .inactive {
                ctx.userData.saveToFile()
            }
        }
    }
    
    private func generateTemplates() {
        let plannedWorkoutDates = ctx.userData.getAllPlannedWorkoutDates()
        if checkAndResetWorkoutStreak(plannedWorkoutDates: plannedWorkoutDates), ctx.userData.settings.progressiveOverload {
            generateNewWorkoutTemplates(plannedWorkoutDates: plannedWorkoutDates)
       }
    }
    
    private func determineStrengthAndSeedMaxes() {
        let (skipped, oldLvl) = determineUserStrengthLevel()
        // only if strength level changed. already seeded after assessment
        if ctx.userData.evaluation.strengthLevel != oldLvl {
            ctx.exercises.seedEstimatedMaxes(skipped: skipped, userData: ctx.userData)
        }
    }

    //  MARK: - Strength / Weakness Assessment
    // add an option to disable this
    func determineUserStrengthLevel() -> (Set<Exercise.ID>, StrengthLevel?) {
        // --- Guard: run at most once every 30 days -----------------------------
        let now = Date()
        if let last = ctx.userData.evaluation.determineStrengthLevelDate,
           CalendarUtility.shared.daysBetween(last, and: now) < 30 {
            print("⏩ Skipping determination; only \(Int(now.timeIntervalSince(last)/86400)) days since last run.")
            return ([], nil)
        }
        
        let ogLvl: StrengthLevel = ctx.userData.evaluation.strengthLevel

        // --- Pass 1: tally categories -----------------------------------------
        var globalCounts: [StrengthLevel: Int] = [:]
        var muscleCounts: [Muscle: [StrengthLevel: Int]] = [:]
     
        let (basePathAge, basePathBW) = CSVLoader.getBasePaths(gender: ctx.userData.physical.gender)

        var skippedIDs: Set<UUID> = []
        for ex in ctx.exercises.allExercises {
            guard let url = ex.url else { continue }
            guard let maxValue = ctx.exercises.peakMetric(for: ex.id)?.actualValue, maxValue > 0 else {
                print("⚠️ \(ex.name) skipped – no PR recorded")
                skippedIDs.insert(ex.id)
                continue
            }
            
            let level = CSVLoader.calculateFitnessCategory(
                userData: ctx.userData,
                basePathAge: basePathAge + url,
                basePathBW: basePathBW + url,
                maxValue: maxValue
            )

            globalCounts[level, default: 0]  += 1

            if let prime = ex.primaryMuscles.first {
                muscleCounts[prime, default: [:]][level, default: 0] += 1
            }
        }

        // --- Pick overall strength level (mode) -------------------------------
        if let (majorityLevel, _) = globalCounts.max(by: { $0.value < $1.value }) {
            if majorityLevel != ctx.userData.evaluation.strengthLevel {
                ctx.userData.evaluation.strengthLevel = majorityLevel
            }
            print("🏷 Overall strength level → \(majorityLevel)")
        }

        // --- Derive strengths / weaknesses per muscle -------------------------
        var strengthsPerMuscle: [Muscle: StrengthLevel] = [:]
        var weaknessesPerMuscle: [Muscle: StrengthLevel] = [:]

        for (muscle, counts) in muscleCounts {
            // Strength = highest count
            if let top = counts.max(by: { $0.value < $1.value })?.key {
                strengthsPerMuscle[muscle] = top
            }
            // Weakness = lowest count
            if let low = counts.min(by: { $0.value < $1.value })?.key {
                weaknessesPerMuscle[muscle] = low
            }
        }

        // --- Persist ----------------------------------------------------------------
        ctx.userData.evaluation.strengths = strengthsPerMuscle
        ctx.userData.evaluation.weaknesses = weaknessesPerMuscle
        ctx.userData.evaluation.determineStrengthLevelDate = now

        // --- Debug ------------------------------------------------------------------
        print("✓ strengths:", strengthsPerMuscle)
        print("✓ weaknesses:", weaknessesPerMuscle)
        print("✓ next evaluation eligible after 30 days.")
        
        return (skippedIDs, ogLvl)
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
                ctx.userData.generateWorkoutPlan(exerciseData: ctx.exercises, equipmentData: ctx.equipment, keepCurrentExercises: true, nextWeek: true)
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


