import SwiftUI


enum Tab: Hashable {
    case workouts, history, home, trainer, calculator
}


struct MainAppView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    @EnvironmentObject var equipmentData: EquipmentData
    @EnvironmentObject var csvLoader: CSVLoader
    @EnvironmentObject var adjustmentsViewModel: AdjustmentsViewModel
    @State private var showResumeWorkoutOverlay = false


    var body: some View {
        TabView {
            WorkoutsView(showResumeWorkoutOverlay: $showResumeWorkoutOverlay)
                .tabItem {
                    Label("Workouts", systemImage: "list.dash")
                }
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            HomeView(userData: userData)
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
        // should also clear passed planned dates and notis
        .onAppear {
            requestNotificationPermissionIfNeeded()
            loadAdjustments()
            resumeOverlay()
            shouldDetermineStrengthLevel()
            userData.checkAndUpdateAge()
            templateGeneration()
            userData.saveToFile()
        }
    }
    
    func loadAdjustments() {
        print("Loading adjustments...")
        adjustmentsViewModel.loadAllAdjustments(for: exerciseData.allExercises, equipmentData: equipmentData)
    }
   
    func resumeOverlay() {
        if checkForWorkoutInProgress() {
            print("Found workout in progress")
            showResumeWorkoutOverlay = true
        }
    }
    func templateGeneration() {
        let plannedWorkoutDates = userData.getAllPlannedWorkoutDates()
        if checkAndResetWorkoutStreak(userData: userData, plannedWorkoutDates: plannedWorkoutDates) {
            if userData.progressiveOverload {
                generateNewWorkoutTemplates(userData: userData, exerciseData: exerciseData, equipmentData: equipmentData, csvLoader: csvLoader, plannedWorkoutDates: plannedWorkoutDates)
           }
       }
    }

    func shouldDetermineStrengthLevel() {
        if userData.infoCollected {
            determineUserStrengthLevel(exerciseData: exerciseData, userData: userData, csvLoader: csvLoader)
        }
    }

    //  MARK: - Strength / Weakness Assessment
    func determineUserStrengthLevel(exerciseData: ExerciseData, userData: UserData,csvLoader: CSVLoader) {
        // --- Guard: run at most once every 30 days -----------------------------
        let now = Date()
        if let last = userData.determineStrengthLevelDate,
           Calendar.current.dateComponents([.day], from: last, to: now).day ?? 0 < 30 {
            print("⏩ Skipping determination; only \(Int(now.timeIntervalSince(last)/86400)) days since last run.")
            return
        }

        // --- Pass 1: tally categories -----------------------------------------
        var globalCounts: [StrengthLevel: Int] = [:]
        var muscleCounts: [Muscle: [StrengthLevel: Int]] = [:]

        for ex in exerciseData.allExercises {
            guard let maxValue = exerciseData.getMax(for: ex.name), maxValue > 0 else {
                print("⚠️ \(ex.name) skipped – no PR recorded"); continue
            }

            let levelRaw = csvLoader.calculateFitnessCategory(
                userData: userData,
                basePathAge: "\(ex.url)_by_age-\(userData.gender)",
                basePathBW:  "\(ex.url)_by_bodyweight-\(userData.gender)",
                maxValue: maxValue
            )

            guard let level = StrengthLevel(rawValue: levelRaw) else { continue }
            globalCounts[level, default: 0]  += 1

            if let prime = ex.primaryMuscles.first {
                muscleCounts[prime, default: [:]][level, default: 0] += 1
            }
        }

        // --- Pick overall strength level (mode) -------------------------------
        if let (majorityLevel, _) = globalCounts.max(by: { $0.value < $1.value }) {
            if majorityLevel != userData.strengthLevel {
                userData.strengthLevel = majorityLevel
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
        userData.strengths = strengthsPerMuscle
        userData.weaknesses = weaknessesPerMuscle
        userData.determineStrengthLevelDate = now

        // --- Debug ------------------------------------------------------------------
        print("✓ strengths:", strengthsPerMuscle)
        print("✓ weaknesses:", weaknessesPerMuscle)
        print("✓ next evaluation eligible after 30 days.")
    }
    
    private func generateNewWorkoutTemplates(userData: UserData, exerciseData: ExerciseData, equipmentData: EquipmentData, csvLoader: CSVLoader, plannedWorkoutDates: [Date]) {
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Set the first day of the week to Monday (1 is Sunday, 2 is Monday)

        // Ensure all planned workout dates are past, considering the end of the day
        let allDatesArePast = plannedWorkoutDates.allSatisfy { plannedDate in
            if let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: plannedDate) {
                return endOfDay < currentDate
            }
            return false
        }

        if allDatesArePast {
            // Get the start of the current week
            let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!

            // Get the start of the week for the last planned workout date
            if let lastPlannedDate = plannedWorkoutDates.last {
                let lastWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastPlannedDate))!

                // Only generate a new workout plan if the current week is different from the last workout week's start date
                if currentWeekStart > lastWeekStart {
                    // Generate new workout plan
                    userData.generateWorkoutPlan(exerciseData: exerciseData, equipmentData: equipmentData, csvLoader: csvLoader, keepCurrentExercises: true, selectedExerciseType: userData.exerciseType, nextWeek: true, shouldSave: false)

                    print("New workout plan generated.")
                } else {
                    print("The current week is not different from the last workout week. No need to generate a new workout plan.")
                }
            }
        } else {
            print("No past dates found. No need to generate a new workout plan.")
        }
    }

    private func requestNotificationPermissionIfNeeded() {
       // Check if notifications are already allowed before requesting
       UNUserNotificationCenter.current().getNotificationSettings { settings in
           if settings.authorizationStatus == .notDetermined {
               // If the user has not yet made a choice regarding notifications, request permission
               requestNotificationPermission()
           } else {
               // settings.authorizationStatus has been determined
               DispatchQueue.main.async {
                   userData.allowedNotifications = settings.authorizationStatus == .authorized
               }
           }
       }
   }

   private func requestNotificationPermission() {
       UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
           DispatchQueue.main.async {
               userData.allowedNotifications = granted
           }
           if let error = error {
               print("Error requesting notifications permission: \(error.localizedDescription)")
           } else {
               print(granted ? "Notification permission granted" : "Notification permission denied")
           }
       }
  }
    
  private func checkForWorkoutInProgress() -> Bool {
      return userData.activeWorkout != nil
  }
   
  private func checkAndResetWorkoutStreak(userData: UserData, plannedWorkoutDates: [Date]) -> Bool {
      print("Checking population Date...")
      guard let populatedDate = userData.workoutsCreationDate else {
          print("No populated date found. Exiting check.")
          return false
      }
     let currentDate = Date()
     print("Current Date: \(currentDate)")
     print("Populated Date: \(populatedDate)")

     let filteredPlannedWorkoutDates = plannedWorkoutDates.filter { $0 >= populatedDate }
    
     for plannedDate in filteredPlannedWorkoutDates {
         print("Checking planned date: \(plannedDate)")
         if plannedDate < currentDate && !Calendar.current.isDateInToday(plannedDate) {
             print("Resetting workout streak to 0.")
             userData.workoutStreak = 0
             return true
            }
      }
      print("No reset needed.")
      return true
   }
    
    struct MainAppButton: View {
        var text: String
        
        var body: some View {
            Text(text)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .font(.headline)
        }
    }
}






