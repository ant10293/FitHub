import SwiftUI

struct StrengthPercentileView: View {
    @ObservedObject var csvLoader: CSVLoader
    @ObservedObject var userData: UserData
    @ObservedObject var exerciseData: ExerciseData
    @State private var maxValue: Double = 0.0
    var exercise: Exercise
    
    init(csvLoader: CSVLoader, userData: UserData, exerciseData: ExerciseData, exercise: Exercise) {
        self.csvLoader = csvLoader
        self.userData = userData
        self.exerciseData = exerciseData
        self.exercise = exercise
        
        _maxValue = State(initialValue: exerciseData.getMax(for: exercise.name) ?? 0)
    }
    
    var body: some View {
        VStack {
            headerView
            if exercise.usesWeight {
                oneRepMaxView
            } else {
                maxRepsView
            }
            Text(getTitle())
                .font(.subheadline)
                .padding(.top, 15)
            
            statsViews
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        Text("Strength Standards")
            .font(.title2)
            .padding(.bottom, 10)
    }
    
    private var oneRepMaxView: some View {
        //if oneRepMax == 0 {
        if maxValue == 0 {
            return AnyView(
                Text("No one rep max available for this exercise.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            )
        } else {
            let percentile = calculateExercisePercentile(userData: userData, exercise: exercise)
            return AnyView(
                VStack {
                    Text("Your one rep max of ") +
                    //Text("\(String(format: "%.0f", oneRepMax)) lbs").bold() +
                    Text("\(String(format: "%.0f", maxValue)) lbs").bold() +
                    Text(" makes you stronger than ") +
                    Text("\(percentile)%").bold() +
                    Text(" of \(userData.gender)s in your weight and age range.")
                }
                    .padding(.horizontal)
            )
        }
    }
    
    private var maxRepsView: some View {
        //if maxReps == 0 {
        if maxValue == 0 {
            return AnyView(
                Text("No max reps available for this exercise.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            )
        } else {
            let percentile = calculateExercisePercentile(userData: userData, exercise: exercise)
            return AnyView(
                VStack {
                    Text("Your maximum reps of ") +
                    //  Text("\(maxReps) reps").bold() +
                    Text("\(maxValue) reps").bold() +
                    Text(" makes you stronger than ") +
                    Text("\(percentile)%").bold() +
                    Text(" of \(userData.gender)s in your weight and age range.")
                }
                    .padding(.horizontal)
            )
        }
    }
    
    private var statsViews: some View {
        VStack(spacing: 16) {
            ageBasedStats
            weightBasedStats
        }
    }
    
    private var ageBasedStats: some View {
        VStack(alignment: .leading) {
            Text("Based on Age (\(userData.age) years)")
                .font(.headline)
            Divider()
            HorizontalTableView(values: get1RMValues(key: "Age"), oneRepMax: maxValue)
        }
        .padding()
    }
    
    private var weightBasedStats: some View {
        VStack(alignment: .leading) {
            Text("Based on Body Weight (\(userData.currentMeasurementValue(for: .weight), specifier: "%.0f") lbs)")
                .font(.headline)
            Divider()
            HorizontalTableView(values: get1RMValues(key: "BW"), oneRepMax: maxValue)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func calculateExercisePercentile(userData: UserData, exercise: Exercise) -> Int {
        let value = exerciseData.getMax(for: exercise.name) ?? 0
        return csvLoader.calculateExercisePercentile(userData: userData, exercise: exercise, maxValue: value)
    }
    
    private func getTitle() -> String {
        return exercise.usesWeight
        ? "1RM Values for \(exercise.name):"
        : "Max Reps for \(exercise.name):"
    }
    
    private func get1RMValues(key: String) -> [(key: String, value: Double)] {
        let values = csvLoader.get1RMValues(for: exercise.url, key: key, value: key == "Age" ? Double(userData.age) : userData.currentMeasurementValue(for: .weight), userData: userData)
        return values.filter { ["BW", "Age", "Beg.", "Nov.", "Int.", "Adv.", "Elite"].contains($0.key) }
            .sorted { lhs, rhs in
                let order = ["BW", "Age", "Beg.", "Nov.", "Int.", "Adv.", "Elite"]
                return order.firstIndex(of: lhs.key)! < order.firstIndex(of: rhs.key)!
            }
    }
}


struct HorizontalTableView: View {
    var values: [(key: String, value: Double)]
    var oneRepMax: Double
    
    var body: some View {
        let userCategory = oneRepMax > 0 ? findUserCategory(oneRepMax, values: values) : nil
        
        HStack {
            ForEach(values, id: \.key) { category, value in
                VStack {
                    let isAgeBW = isAge_BW(category: category)
                    Text(category)
                        .font(.subheadline)
                        .bold(isAgeBW)
                    Divider().bold()
                    Text("\(Int(value))")
                        .font(.body)
                        .bold(isAgeBW)
                        .padding(4)
                        .background(category == userCategory ? Color.yellow.opacity(0.4) : Color.clear)
                        .cornerRadius(5)
                }
            }
        }
    }
    private func isAge_BW(category: String) -> Bool {
        return category == "Age" || category == "BW"
    }
    
    private func findUserCategory(_ oneRepMax: Double, values: [(key: String, value: Double)]) -> String {
        let categories = ["Beg.", "Nov.", "Int.", "Adv.", "Elite"]
        var userCategory: String = "Beg."
        
        let oneRepMax = round(oneRepMax)
        
        for cat in categories.reversed() {
            if isUserInCategory(cat, oneRepMax: oneRepMax, values: values) {
                userCategory = cat
                break
            }
        }
        
        return userCategory
    }
    
    private func isUserInCategory(_ category: String, oneRepMax: Double, values: [(key: String, value: Double)]) -> Bool {
        let categories = ["Beg.", "Nov.", "Int.", "Adv.", "Elite"]
        
        guard let index = categories.firstIndex(of: category) else {
            print("Error: Category \(category) not found in predefined categories.")
            return false
        }
        
        var maxForCategory: Double = 0.0
        var minForCategory: Double = 0.0
        
        if category == "Beg." {
            let nextCategory = index < categories.count - 1 ? categories[index + 1] : nil
            minForCategory = 0
            //minForCategory = values.first { $0.key == category }?.value ?? 0.0
            maxForCategory = nextCategory != nil ? (values.first { $0.key == nextCategory }?.value ?? Double.greatestFiniteMagnitude) - 1 : Double.greatestFiniteMagnitude
        }
        if category == "Elite" {
            minForCategory = values.first { $0.key == category }?.value ?? 0.0
            maxForCategory = (values.first { $0.key == category }?.value ?? Double.greatestFiniteMagnitude) * 1.25
        }
        if category != "Elite" && category != "Beg."{
            let nextCategory = index < categories.count - 1 ? categories[index + 1] : nil
            //let prevCategory = index > 0 ? categories[index - 1] : nil
            // minForCategory = prevCategory != nil ? (values.first { $0.key == prevCategory }?.value ?? 0.0) + 1 : 0.0
            minForCategory = values.first { $0.key == category }?.value ?? 0.0
            maxForCategory = nextCategory != nil ? (values.first { $0.key == nextCategory }?.value ?? Double.greatestFiniteMagnitude) - 1 : Double.greatestFiniteMagnitude
        }
        
        print("Category: \(category)")
        print("One Rep Max: \(oneRepMax)")
        print("Min for Category: \(minForCategory)")
        print("Max for Category: \(maxForCategory)")
        
        let result = oneRepMax >= minForCategory && oneRepMax <= maxForCategory
        print("Is User in Category: \(result)")
        
        return result
    }
}
