import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var ctx: AppContext

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        NavigationLink(destination: OneRMCalculator()) {
                            CalculatorRow(title: "1 Rep Max Calculator", systemImageName: "scalemass")
                        }
                        // premium only
                        NavigationLink(destination: TemplateSelection(userTemplates: ctx.userData.workoutPlans.userTemplates, trainerTemplates: ctx.userData.workoutPlans.trainerTemplates)) {
                            CalculatorRow(title: "Progressive Overload Calculator", systemImageName: "chart.line.uptrend.xyaxis")
                        }
                    } header: {
                        Text("Strength")
                    }
                    
                    Section {
                        NavigationLink(destination: BMICalculator(userData: ctx.userData)) {
                            CalculatorRow(title: "BMI Calculator", systemImageName: "heart.text.square")
                        }
                        NavigationLink(destination: KcalCalculator(userData: ctx.userData)) {
                            CalculatorRow(title: "Daily Caloric Intake Calculator", systemImageName: "flame")
                        }
                        NavigationLink(destination: BFCalculator(userData: ctx.userData)) {
                            CalculatorRow(title: "Body Fat Calculator", systemImageName: "percent")
                        }
                        NavigationLink(destination: MacroCalculator(userData: ctx.userData)) {
                            CalculatorRow(title: "Macronutrient Calculator", systemImageName: "fork.knife.circle")
                        }
                    } header: {
                        Text("Health")
                    }
                    .listStyle(GroupedListStyle())
                }
            }
            .navigationTitle("Calculators")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .padding()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MenuView()) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
        }
    }
    struct CalculatorRow: View {
        var title: String
        var systemImageName: String
        
        var body: some View {
            HStack {
                Image(systemName: systemImageName)
                    .foregroundColor(.blue)
                    .imageScale(.large)
                Text(title)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
    }
}












