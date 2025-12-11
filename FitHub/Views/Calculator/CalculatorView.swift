import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                Section(header: Text("Strength")) {
                    Button {
                        navPath.append(CalculatorRoute.oneRepMax)
                    } label: {
                        CalculatorRow(title: "1 Rep Max Calculator", systemName: "scalemass")
                    }

                    Button {
                        navPath.append(CalculatorRoute.progressiveOverload)
                    } label: {
                        CalculatorRow(title: "Progressive Overload Calculator", systemName: "chart.line.uptrend.xyaxis")
                    }
                    // MARK: premium feature only
                    .disabled(ctx.store.membershipType != .free)
                }

                Section(header: Text("Health")) {
                    Button {
                        navPath.append(CalculatorRoute.bmi)
                    } label: {
                        CalculatorRow(title: "BMI Calculator", systemName: "heart.text.square")
                    }

                    Button {
                        navPath.append(CalculatorRoute.kcal)
                    } label: {
                        CalculatorRow(title: "Daily Caloric Intake Calculator", systemName: "flame")
                    }

                    Button {
                        navPath.append(CalculatorRoute.bodyFat)
                    } label: {
                        CalculatorRow(title: "Body Fat Calculator", systemName: "percent")
                    }

                    Button {
                        navPath.append(CalculatorRoute.macros)
                    } label: {
                        CalculatorRow(title: "Macronutrient Calculator", systemName: "fork.knife.circle")
                    }
                }
            }
            .navigationTitle("Calculators")
            .customToolbar(
                settingsDestination: { AnyView(SettingsView()) },
                menuDestination: { AnyView(MenuView()) }
            )
            .navigationDestination(for: CalculatorRoute.self) { route in
                switch route {
                case .oneRepMax:
                    OneRMCalculator()
                case .progressiveOverload:
                    TemplateSelection(
                        userTemplates: ctx.userData.workoutPlans.userTemplates,
                        trainerTemplates: ctx.userData.workoutPlans.trainerTemplates
                    )
                case .bmi:
                    BMICalculator(userData: ctx.userData)
                case .kcal:
                    KcalCalculator(userData: ctx.userData)
                case .bodyFat:
                    BFCalculator(userData: ctx.userData)
                case .macros:
                    MacroCalculator(userData: ctx.userData)
                }
            }
        }
    }
    
    private enum CalculatorRoute: Hashable {
        case oneRepMax, progressiveOverload, bmi, kcal, bodyFat, macros
    }

    private func CalculatorRow(title: String, systemName: String) -> some View {
        HStack {
            Image(systemName: systemName)
                .foregroundStyle(.blue)
                .imageScale(.large)
            Text(title)
                .foregroundStyle(Color.primary)
        }
        .padding(.vertical, 8)
    }
}










