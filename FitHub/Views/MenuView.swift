import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var ctx: AppContext
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: ExerciseView()) {
                    Label("Exercise Database", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(destination: MeasurementsView(userData: ctx.userData)) {
                    Label("Measurements", systemImage: "ruler")
                }
                NavigationLink(destination: TemplateArchives(userData: ctx.userData)) {
                    Label("Archived Templates", systemImage: "archivebox")
                }
            } header: {
                Text("Logging")
            }
            
            Section {
                NavigationLink(destination: EquipmentSelection(selection: ctx.userData.evaluation.equipmentSelected)) {
                    Label("Your Equipment", systemImage: "dumbbell")
                }
                NavigationLink(destination: StatsView(userData: ctx.userData)) {
                    Label("Statistics", systemImage: "chart.bar")
                }
                NavigationLink(destination: GoalSelectionView(userData: ctx.userData)) {
                    Label("Modify Goal", systemImage: "target")
                }
            } header: {
                Text("Setup")
            }
        }
        .listStyle(InsetGroupedListStyle()) // Gives a card-like appearance
        .navigationTitle("Menu")
    }
}
