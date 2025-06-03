import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("Strength")) {
                        NavigationLink(destination: RMCalculator(userData: userData, exerciseData: exerciseData)) {
                            CalculatorRow(title: "1 Rep Max Calculator", systemImageName: "scalemass")
                        }
                        // premium only
                        NavigationLink(destination: TemplateSelection()) {
                            CalculatorRow(title: "Progressive Overload Calculator", systemImageName: "chart.line.uptrend.xyaxis")
                        }
                    }
                    Section(header: Text("Health")) {
                        NavigationLink(destination: BMICalculator(userData: userData)) {
                            CalculatorRow(title: "BMI Calculator", systemImageName: "heart.text.square")
                        }
                        NavigationLink(destination: KcalCalculator(userData: userData)) {
                            CalculatorRow(title: "Daily Caloric Intake Calculator", systemImageName: "flame")
                        }
                        NavigationLink(destination: BFCalculator(userData: userData)) {
                            CalculatorRow(title: "Body Fat Calculator", systemImageName: "percent")
                        }
                        NavigationLink(destination: MacroCalculator(userData: userData)) {
                            CalculatorRow(title: "Macronutrient Calculator", systemImageName: "fork.knife.circle")
                        }
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












