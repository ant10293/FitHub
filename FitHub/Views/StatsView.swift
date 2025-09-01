import SwiftUI


struct StatsView: View {
    @ObservedObject var userData: UserData
    
    var body: some View {
        VStack {
            let bmi = userData.currentMeasurementValue(for: .bmi).displayValue
            let calories = userData.currentMeasurementValue(for: .caloricIntake).displayValue
            let carbs = userData.physical.carbs
            let fats = userData.physical.fats
            let proteins = userData.physical.proteins
        
            Text("Strength Level: \(userData.evaluation.strengthLevel)")
            
            metricRow(
                label: "BMI",
                value: bmi,
                linkText: "BMI Calculator",
                destination: {
                    BMICalculator(userData: userData)
                }
            )
            
            if bmi > 0 {
                BMICategoryTable(userBMI: bmi)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.1)  // ≈ 1/3 screen
            }
                        
            metricRow(
                label: "Body Fat",
                value: userData.currentMeasurementValue(for: .bodyFatPercentage).displayValue,
                unit: "%",
                linkText: "Body Fat Calculator",
                destination: {
                    BFCalculator(userData: userData)
                }
            )

            metricRow(
                label: "Daily Caloric Intake",
                value: calories,
                formatted: String(format: "%.0f", calories),
                unit: "kcal",
                linkText: "Calorie Calculator",
                destination: {
                    KcalCalculator(userData: userData)
                }
            )

            metricRow(
                label: "Daily Macronutrients",
                value: carbs == 0 ? carbs : -1,
                linkText: "Macro Calculator",
                destination: {
                    MacroCalculator(userData: userData)
                }
            )
            
            macroRow(name: "Carbs", value: carbs)
            macroRow(name: "Fats", value: fats)
            macroRow(name: "Proteins", value: proteins)
            
            RingView(
                dailyCaloricIntake: calories,
                carbs: carbs,
                fats: fats,
                proteins: proteins
            )
            .padding()
        }
        .padding()
        .navigationTitle("\(getTitleName)'s Stats")
    }
    
    private var getTitleName: String {
        if userData.profile.firstName.isEmpty {
            // Split userName and take the first part as the first name.
            let nameComponents = userData.profile.userName.split(separator: " ")
            return nameComponents.first.map(String.init) ?? userData.profile.userName
        } else {
            return userData.profile.firstName
        }
    }
    
    private func macroRow(name: String, value: Double) -> some View {
        HStack {
            Text("\(name): ").bold()
            if value != 0 {
                Text("\(Format.smartFormat(value))")
                + Text(" g").fontWeight(.light)
            } else {
                Text("N/A").foregroundStyle(.secondary)
            }
        }
    }
    
    private func metricRow<Destination: View>(
        label: String,
        value: Double,
        formatted: String? = nil,
        unit: String? = nil,
        linkText: String,
        destination: @escaping () -> Destination
    ) -> some View {
        
        HStack {
            Text("\(label):").bold()
            
            if value == 0 {
                NavigationLink(linkText, destination: LazyDestination { destination() })
                    .foregroundStyle(.blue)
            } else if value == -1 {
                EmptyView()
            }
            else {
                // number → string
                let main = formatted ?? Format.smartFormat(value)
                
                // build Text without force-unwrapping
                let display: Text = {
                    if let u = unit {
                        return Text(main) + Text(" \(u)").fontWeight(.light)
                    } else {
                        return Text(main)
                    }
                }()
                
                display
            }
        }
    }
}



