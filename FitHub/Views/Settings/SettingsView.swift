import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    @EnvironmentObject var equipment: EquipmentData
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var isNotificationsExpanded = false
    
    var body: some View {
        List {
            generalSettingsSection()
            advancedWorkoutSection()
            healthSection()
            legalSection()
        }
        .navigationTitle("Settings")
        .listStyle(InsetGroupedListStyle())
    }
    
    private func generalSettingsSection() -> some View {
        Section(header: Text("General Settings")) {
            navigationLink("timer", "Rest Timer", RestTimerSettings(userData: userData))
           // navigationLink("calendar", "Start Week On", StartWeekOn())
            navigationLink("globe", "Change Language", ChangeLanguage())
            navigationLink("ruler", "US/Metric Selection", UnitSelection())
            navigationLink("paintbrush", "Change Theme", ChangeTheme())
            
            DisclosureGroup(isExpanded: $isNotificationsExpanded) {
                Toggle(isOn: $userData.allowedNotifications) {
                    Text("Enable Notifications")
                }
                .onChange(of: userData.allowedNotifications) { oldValue, newValue in
                    if newValue {
                        requestNotificationPermissionIfNeeded()
                    } else {
                        // Handle the case when notifications are turned off.
                        print("User turned off notifications")
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }
                /*.onChange(of: userData.allowedNotifications) { _, newValue in
                        Task { @MainActor in
                            if newValue {
                                await notifier.requestAuthorization()
                                if !notifier.isAuthorized {          // user hit “Don’t Allow”
                                    userData.allowedNotifications = false   // snap toggle back
                                }
                            } else {
                                await notifier.cancelAll()
                            }
                            userData.saveSingleVariableToFile(\.allowedNotifications, for: .allowedNotifications)
                        }
                    }*/
            }
            label: {
                HStack {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
            }
            .accentColor(Color(UIColor.darkGray)) // This ensures the chevron arrow is gray
        }
    }
    
    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                requestNotificationPermission()
            } else {
                DispatchQueue.main.async {
                    userData.allowedNotifications = settings.authorizationStatus == .authorized
                    userData.saveSingleVariableToFile(\.allowedNotifications, for: .allowedNotifications)
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                userData.allowedNotifications = granted
                userData.saveSingleVariableToFile(\.allowedNotifications, for: .allowedNotifications)
            }
            if let error = error {
                print("Error requesting notifications permission: \(error.localizedDescription)")
            } else {
                print(granted ? "Notification permission granted" : "Notification permission denied")
            }
        }
    }
    
    private func advancedWorkoutSection() -> some View {
        Section(header: Text("Advanced Workout Generation")) {
            navigationLink("scalemass", "Adjust Weight Incrementation", WeightIncrementation(userData: userData))
            navigationLink("chart.bar", "Progressive Overload", OverloadStyle())
            navigationLink("figure.walk", "Muscle Rest Duration", MuscleRest())
            navigationLink("clock", "Planned Workout Time", PlannedWorkoutTime(userData: userData))
        }
    }
    
    private func healthSection() -> some View {
        Section(header: Text("Health")) {
            navigationLink("heart", "HealthKit", HealthKitSettings(healthKitManager: healthKitManager))
        }
    }
    
    private func legalSection() -> some View {
        Section(header: Text("Legal")) {
            navigationLink("shield", "Privacy Policy", PrivacyPolicy())
            navigationLink("doc.text", "Terms of Service", TermsOfService())
        }
    }
    
    
    private func navigationLink<Destination: View>(_ imageName: String, _ label: String, _ destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: imageName)
                Text(label)
            }
        }
    }
}
















