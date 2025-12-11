import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var ctx: AppContext
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
        } header: {
            Text("General")
        }
    }
 
    private func advancedWorkoutSection() -> some View {
        Section {
            navigationLink("gearshape.2", "Workout Generation") { WorkoutCustomization() }
            navigationLink("scalemass", "Available Weight Plates") { PlateSelection(userData: ctx.userData) }
            navigationLink("chart.bar", "Progressive Overload") { OverloadSettingsView(userData: ctx.userData) }
            navigationLink("slider.horizontal.3", "Volume Deloading") { DeloadSettingsView(userData: ctx.userData) }
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
             navigationLink("shield", LegalURL.privacyPolicy.title) { PrivacyPolicy() }
             navigationLink("doc.text", LegalURL.termsOfService.title) { TermsOfService() }
             // MARK: Affiliate System guard
             if useAffiliateSystem {
                 navigationLink("checkmark.shield", LegalURL.affiliateTerms.title) { AffiliateTermsView() }
             }
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
















