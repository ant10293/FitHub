import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var ctx: AppContext
    @ObservedObject var notifications = NotificationManager.shared
    @State private var isNotificationsExpanded = false
    
    var body: some View {
        List {
            generalSettingsSection()
            advancedWorkoutSection()
            //healthSection()
            legalSection()
        }
        .navigationTitle("Settings")
    }
    
    private func generalSettingsSection() -> some View {
        Section {
            navigationLink("timer", "Rest Timer") { RestTimerSettings(userData: ctx.userData) }
            navigationLink("arrow.up.arrow.down", "Exercise Sorting") { SortSettings(userData: ctx.userData) }
            // navigationLink("calendar", "Start Week On") { StartWeekOn() }
            //navigationLink("globe", "Change Language") { ChangeLanguage(userData: ctx.userData) }
            navigationLink("ruler", "Imperial / Metric") { UnitSelection(userData: ctx.userData) }
            //navigationLink("paintbrush", "Change Theme") { ChangeTheme(userData: ctx.userData) }
            
            DisclosureGroup(isExpanded: $isNotificationsExpanded) {
                VStack {
                    Toggle("Workout Reminders", isOn: Binding<Bool>(
                        get: { ctx.userData.settings.allowedNotifications },
                        set: { newValue in
                            ctx.userData.settings.allowedNotifications = newValue
                            if newValue == false {
                                NotificationManager.removeAllPending()
                            }
                        }
                    ))
                    if !notifications.isAuthorized, ctx.userData.settings.allowedNotifications {
                        WarningFooter(message: "Must allow Notifications in Device Settings.")
                    }
                }               
            }
            label: {
                HStack {
                    Image(systemName: "bell")
                    Text("Push Notifications")
                }
            }
            .accentColor(Color(UIColor.secondaryLabel)) // This ensures the chevron arrow is gray
        } header: {
            Text("General")
        }
    }
 
    private func advancedWorkoutSection() -> some View {
        Section {
            navigationLink("gearshape.2", "Workout Generation") { WorkoutCustomization() }
            navigationLink("plusminus.circle", "Weight Rounding") { WeightIncrementation() }
            navigationLink("scalemass", "Available Weight Plates") { PlateSelection(userData: ctx.userData) }
            navigationLink("chart.bar", "Progressive Overload") { OverloadSettings(userData: ctx.userData) }
            navigationLink("slider.horizontal.3", "Volume Deloading") { DeloadSettings(userData: ctx.userData) }
            //navigationLink("figure.walk", "Muscle Rest Duration") { MuscleRest(userData: ctx.userData) }
            navigationLink("clock", "Planned Workout Time") { PlannedWorkoutTime(userData: ctx.userData) }
            navigationLink("switch.2", "SetDetail Entry") { SetDetailSettings(userData: ctx.userData) }
        } header: {
            Text("Workout")
        }
    }
    
    /*
    private func healthSection() -> some View {
        Section {
            navigationLink("heart", "HealthKit", HealthKitSettings())
        } header: {
            Text("Health")
        }
    }
    */
    
    private func legalSection() -> some View {
         Section {
             navigationLink("shield", "Privacy Policy") { PrivacyPolicy() }
             navigationLink("doc.text", "Terms of Service") { TermsOfService() }
         } header: {
             Text("Legal")
         }
     }
    
    // need to use LazyDestination
    private func navigationLink<Destination: View>(
        _ imageName: String,
        _ label: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            LazyDestination { destination() }
                .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack {
                Image(systemName: imageName)
                Text(label)
            }
        }
    }
}
















