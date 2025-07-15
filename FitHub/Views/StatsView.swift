import SwiftUI


struct StatsView: View {
    @ObservedObject var userData: UserData
    
    var body: some View {
        VStack {
            metricRow(
                label: "BMI",
                value: userData.currentMeasurementValue(for: .bmi),
                linkText: "BMI Calculator",
                destination: {
                    BMICalculator(userData: userData)
                }
            )
            
            if userData.currentMeasurementValue(for: .bmi) != 0 {
                BMICategoryTable(userBMI: userData.currentMeasurementValue(for: .bmi))
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.1)  // ≈ 1/3 screen
            }
            
            metricRow(
                label: "Body Fat",
                value: userData.currentMeasurementValue(for: .bodyFatPercentage),
                unit: "%",
                linkText: "Body Fat Calculator",
                destination: {
                    BFCalculator(userData: userData)
                }
            )

            metricRow(
                label: "Daily Caloric Intake",
                value: userData.currentMeasurementValue(for: .caloricIntake),
                formatted: String(format: "%.0f", userData.currentMeasurementValue(for: .caloricIntake)),
                unit: "kcal",
                linkText: "Calorie Calculator",
                destination: {
                    KcalCalculator(userData: userData)
                }
            )

            metricRow(
                label: "Daily Macronutrients",
                value: Double(userData.physical.carbs),
                linkText: "Macro Calculator",
                destination: {
                    MacroCalculator(userData: userData)
                }
            )
            
            macroRow(name: "Carbs", value: userData.physical.carbs)
            macroRow(name: "Fats", value: userData.physical.fats)
            macroRow(name: "Proteins", value: userData.physical.proteins)
            
            RingView(
                dailyCaloricIntake: userData.currentMeasurementValue(for: .caloricIntake),
                carbs: userData.physical.carbs,
                fats: userData.physical.fats,
                proteins: userData.physical.proteins
            )
            .padding()
        }
        .padding()
        .navigationTitle("\(getTitleName())'s Stats")
    }
    
    private func getTitleName() -> String {
        var name: String
        
        if userData.profile.firstName.isEmpty {
            // Split userName and take the first part as the first name.
            let nameComponents = userData.profile.userName.split(separator: " ")
            name = nameComponents.first.map(String.init) ?? userData.profile.userName
        } else {
            name = userData.profile.firstName
        }
        return name
    }
    
    private func macroRow(name: String, value: Double) -> some View {
        HStack {
            Text("\(name): ").bold()
            if value != 0 {
                Text("\(Format.smartFormat(value))")
                + Text(" g").fontWeight(.light)
            } else {
                Text("N/A").foregroundColor(.secondary)
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
                NavigationLink(linkText, destination: destination())
                    .foregroundColor(.blue)
            } else {
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



