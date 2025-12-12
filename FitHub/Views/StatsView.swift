import SwiftUI


struct StatsView: View {
    @ObservedObject var userData: UserData

    var body: some View {
        let height = screenHeight
        let bmi = userData.currentMeasurementValue(for: .bmi).displayValue
        let calories = userData.currentMeasurementValue(for: .caloricIntake).displayValue
        let carbs = userData.physical.carbs
        let fats = userData.physical.fats
        let proteins = userData.physical.proteins
        let total = carbs + fats + proteins

        ScrollView {
            VStack {
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
                        .frame(height: height * 0.1)
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
                    label: "Caloric Intake",
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
                    value: total == 0 ? total : -1,
                    linkText: "Macro Calculator",
                    destination: {
                        MacroCalculator(userData: userData)
                    }
                )

                macroRow(name: "Carbs", value: carbs)
                macroRow(name: "Fats", value: fats)
                macroRow(name: "Proteins", value: proteins)

                RingView(
                    kcal: calories,
                    carbs: carbs,
                    fats: fats,
                    proteins: proteins
                )
                .padding()
            }
        }
        .padding()
        .navigationTitle("\(userData.profile.displayName(.title))'s Stats")
    }

    private func macroRow(name: String, value: Double) -> Text {
        // build one Text
        let text: Text = {
            let base = Text("\(name): ").bold()
            if value != 0 {
                return base
                    + Text(Format.smartFormat(value))
                    + Text(" g").fontWeight(.light)
            } else {
                return base
                    + Text("N/A").foregroundStyle(.secondary)
            }
        }()

        return text
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
            if value == 0 {
                // label + link, still single line visually
                Text("\(label): ").bold()
                NavigationLink(linkText, destination: LazyDestination { destination() })
                    .foregroundStyle(.blue)
            } else if value == -1 {
                // nothing
                EmptyView()
            } else {
                // build single Text
                let display: Text = {
                    let base = Text("\(label): ").bold()
                    let main = formatted ?? Format.smartFormat(value)

                    if let u = unit {
                        return base
                            + Text(main)
                            + Text(" \(u)").fontWeight(.light)
                    } else {
                        return base + Text(main)
                    }
                }()

                display
            }
        }
    }
}
