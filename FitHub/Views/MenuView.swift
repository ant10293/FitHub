import SwiftUI

struct MenuView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var equipmentData: EquipmentData
    
    var body: some View {
        List {
            NavigationLink(destination: ExerciseView()) {
                Label("Exercise Database", systemImage: "list.bullet.rectangle")
            }
            NavigationLink(destination: EquipmentSelection(userData: userData, equipmentData: equipmentData)) {
                Label("Your Equipment", systemImage: "dumbbell")
            }
            NavigationLink(destination: GoalSelectionView(userData: userData)) {
                Label("Modify Goal", systemImage: "target")
            }
            NavigationLink(destination: MeasurementsView()) {
                Label("Measurements", systemImage: "ruler")
            }
            NavigationLink(destination: StatsView()) {
                Label("Statistics", systemImage: "chart.bar")
            }
            
        }
        .listStyle(InsetGroupedListStyle()) // Gives a card-like appearance
        .navigationTitle("Menu")
    }
}
