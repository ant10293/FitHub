import SwiftUI

struct StatsView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    
    var body: some View {
        VStack {
            HStack {
                Text("BMI:")
                    .bold()
                if userData.currentMeasurementValue(for: .bmi) == 0 {
                    NavigationLink(destination: BMICalculator(userData: userData)) {
                        Text("BMI Calculator")
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("\(userData.currentMeasurementValue(for: .bmi), specifier: "%.2f")")
                }
            }
            
            if userData.currentMeasurementValue(for: .bmi) != 0 {
                BMICategoryTable(userBMI: userData.currentMeasurementValue(for: .bmi))
                    .frame(height: 60)
            }
            
            HStack {
                Text("Body Fat:")
                    .bold()
                if userData.currentMeasurementValue(for: .bodyFatPercentage) == 0 {
                    NavigationLink(destination: BFCalculator(userData: userData)) {
                        Text("Body Fat Calculator")
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("\(userData.currentMeasurementValue(for: .bodyFatPercentage), specifier: "%.2f") %")
                }
            }
            
            HStack {
                Text("Daily Caloric Intake:")
                    .bold()
                if userData.currentMeasurementValue(for: .caloricIntake) == 0 {
                    
                    NavigationLink(destination: KcalCalculator(userData: userData)) {
                        Text("Calorie Calculator")
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("\(userData.currentMeasurementValue(for: .caloricIntake), specifier: "%.f") kcal")
                }
            }
            
            HStack {
                Text("Daily Macronutrients:")
                    .bold()
                if userData.carbs == 0 {
                    NavigationLink(destination: MacroCalculator(userData: userData)) {
                        Text("Macro Calculator")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            HStack {
                Text("Carbs:")
                    .bold()
                if userData.carbs != 0 {
                    Text("\(userData.carbs, specifier: "%.2f") g")
                }
                else {
                    Text("N/A")
                }
            }
            
            HStack {
                Text("Fats:")
                    .bold()
                if userData.fats != 0 {
                    Text("\(userData.fats, specifier: "%.2f") g")
                }
                else {
                    Text("N/A")
                }
            }
            HStack {
                Text("Proteins:")
                    .bold()
                if userData.proteins != 0 {
                    Text("\(userData.proteins, specifier: "%.2f") g")
                }
                else {
                    Text("N/A")
                }
            }
            
            
            RingView(dailyCaloricIntake: userData.currentMeasurementValue(for: .caloricIntake),
                     carbs: userData.carbs,
                     fats: userData.fats,
                     proteins: userData.proteins)
            .padding()
        }
        .padding()
        .navigationTitle("\(getTitleName())'s Stats")
        //.navigationTitle("Stats")
    }
    func getTitleName() -> String {
        var name: String
        
        if userData.firstName.isEmpty {
            print("No first name available.")
            // Split userName and take the first part as the first name.
            let nameComponents = userData.userName.split(separator: " ")
            name = nameComponents.first.map(String.init) ?? userData.userName
        }
        else {
            name = userData.firstName
        }
        return name
    }
}

struct RingView: View {
    var dailyCaloricIntake: Double
    var carbs: Double
    var fats: Double
    var proteins: Double
    
    private var carbsCalories: Double {
        return carbs * 4
    }
    
    private var fatsCalories: Double {
        return fats * 9
    }
    
    private var proteinsCalories: Double {
        return proteins * 4
    }
    
    private var carbsRatio: Double {
        return carbsCalories / dailyCaloricIntake
    }
    
    private var fatsRatio: Double {
        return fatsCalories / dailyCaloricIntake
    }
    
    private var proteinsRatio: Double {
        return proteinsCalories / dailyCaloricIntake
    }
    
    var body: some View {
        VStack {
            ZStack {
                //    if dailyCaloricIntake == 0 {
                if carbs == 0 && fats == 0 && proteins == 0 {
                    Circle()
                        .stroke(Color.gray, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    VStack {
                        if dailyCaloricIntake == 0 {
                            //Text("0")
                            Text("N/A")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        else {
                            Text("\(Int(dailyCaloricIntake))")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("kcal")
                                .font(.subheadline)
                        }
                    }
                } else {
                    Circle()
                        .trim(from: 0, to: CGFloat(carbsRatio))
                        .stroke(Color.blue, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: CGFloat(carbsRatio), to: CGFloat(carbsRatio + fatsRatio))
                        .stroke(Color.yellow, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: CGFloat(carbsRatio + fatsRatio), to: 1)
                        .stroke(Color.red, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    VStack {
                        Text("\(Int(dailyCaloricIntake))")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("kcal")
                            .font(.subheadline)
                    }
                }
            }
            .frame(width: 200, height: 200)
            
            HStack {
                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                    Text("Carbs")
                        .font(.caption)
                }
                VStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 20, height: 20)
                    Text("Fats")
                        .font(.caption)
                }
                VStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    Text("Proteins")
                        .font(.caption)
                }
            }
            .padding(.top, 10)
        }
    }
}

struct BMICategoryTable: View {
    let userBMI: Double
    
    // Define BMI categories, ranges, and colors
    let categories: [(name: String, displayRange: String, color: Color)] = [
        ("Underweight", "<18.5", .blue),
        ("Normal Weight", "18.5 - 24.9", .green),
        ("Overweight\n", "25.0 - 29.9", .yellow),
        ("Obese\n", "30.0 - 34.9", .orange),
        ("Extremely Obese", "35<", .red)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(categories, id: \.name) { category in
                    VStack {
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        Text(category.displayRange)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: geometry.size.width / CGFloat(categories.count), height: geometry.size.height)
                    .background(category.color)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                GeometryReader { innerGeometry in
                    let categoryIndex = getBMICategoryIndex()
                    let columnWidth = innerGeometry.size.width / CGFloat(categories.count)
                    
                    // Gray overlay for user's category
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: columnWidth + 5, height: innerGeometry.size.height + 5)
                        .position(x: columnWidth * (CGFloat(categoryIndex) + 0.5), y: innerGeometry.size.height / 2)
                }
            )
        }
    }
    // Function to determine which BMI category the user belongs to
    private func getBMICategoryIndex() -> Int {
        if userBMI < 18.5 {
            return 0 // Underweight
        } else if userBMI < 25.0 {
            return 1 // Normal Weight
        } else if userBMI < 30.0 {
            return 2 // Overweight
        } else if userBMI < 35.0 {
            return 3 // Obese
        } else {
            return 4 // Extremely Obese
        }
    }
}
