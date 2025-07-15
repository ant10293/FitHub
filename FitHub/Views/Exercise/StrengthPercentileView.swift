import SwiftUI

struct StrengthPercentileView: View {
    var maxValue: Double
    var age: Int
    var weight: Double
    var gender: Gender
    var exercise: Exercise
    var maxValuesAge: [String: Double]
    var maxValuesBW: [String: Double]
    var percentile: Int
    
    
    var body: some View {
        VStack {
            headerView
            if exercise.type.usesWeight {
                maxView(usesWeight: true)
            } else {
                maxView(usesWeight: false)
            }
            Text(getTitle())
                .font(.headline)
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
    
    private func maxView(usesWeight: Bool) -> some View {
        if maxValue == 0 {
            return AnyView(
                Text(usesWeight ? "No one rep max available for this exercise." : "No max reps available for this exercise.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            )
        } else {
            return AnyView(
                VStack {
                    Text(usesWeight ? "Your one rep max of " : "Your max of ") +
                    Text("\(Format.smartFormat(maxValue)) \(usesWeight ? "lbs" : "reps")").bold() +
                    Text(" makes you stronger than ") +
                    Text("\(percentile)%").bold() +
                    Text(" of \(gender)s in your weight and age range.")
                }
                .padding(.horizontal)
            )
        }
    }
    
    private var statsViews: some View {
        VStack(spacing: 24) {
            ageBasedStats
            weightBasedStats
        }
    }
    
    private var ageBasedStats: some View {
        VStack(alignment: .leading) {
            Text("Based on Age") + Text(" (\(age) years)").foregroundColor(.gray)
            Divider()
            HorizontalTableView(values: get1RMValues(key: "Age"), oneRepMax: maxValue)
        }
        .font(.headline)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var weightBasedStats: some View {
        VStack(alignment: .leading) {
            Text("Based on Body Weight") + Text(" (\(weight, specifier: "%.0f") lbs)").foregroundColor(.gray)
            Divider()
            HorizontalTableView(values: get1RMValues(key: "BW"), oneRepMax: maxValue)
        }
        .font(.headline)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helper Methods
    
    private func getTitle() -> String {
        return exercise.type.usesWeight ? "1RM Values for \(exercise.name):" : "Max Reps for \(exercise.name):"
    }
    
    private func get1RMValues(key: String) -> [(key: String, value: Double)] {
        var values: [String: Double] = [:]
        if key == "Age" {
            values = maxValuesAge
        } else if key == "BW" {
            values = maxValuesBW
        }
        return values.filter { ["BW", "Age", "Beg.", "Nov.", "Int.", "Adv.", "Elite"].contains($0.key) }
            .sorted { lhs, rhs in
                let order = ["BW", "Age", "Beg.", "Nov.", "Int.", "Adv.", "Elite"]
                return order.firstIndex(of: lhs.key)! < order.firstIndex(of: rhs.key)!
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
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }
        }
        
        private func isAge_BW(category: String) -> Bool { return category == "Age" || category == "BW" }
        
        private func findUserCategory(_ oneRepMax: Double, values: [(key: String, value: Double)]) -> String {
            let rounded1RM     = round(oneRepMax)

            // Look up the threshold numbers by enum instead of raw strings
            let threshold: [StrengthLevel: Double] =
                Dictionary(uniqueKeysWithValues: values.compactMap { row in
                    guard let lvl = StrengthLevel(rawValue: row.key) else { return nil }
                    return (lvl, row.value)
                })

            // Walk the enum from top to bottom; the first hit wins
            for level in StrengthLevel.allCases.reversed() {
                if isUser(in: level, oneRepMax: rounded1RM, threshold: threshold) {
                    return level.rawValue
                }
            }
            return StrengthLevel.beginner.rawValue         // should never fall through
        }

        /// Decide whether `oneRepMax` belongs inside the given `level`,
        /// based on the surrounding threshold table.
        private func isUser(in level: StrengthLevel, oneRepMax: Double, threshold: [StrengthLevel: Double]) -> Bool {
            // Helper to grab a threshold safely
            func t(_ lvl: StrengthLevel) -> Double { threshold[lvl] ?? 0 }

            // Figure out lower / upper bounds for this level
            let all  = StrengthLevel.allCases
            guard let idx = all.firstIndex(of: level) else { return false }

            let lower: Double
            let upper: Double

            switch level {

            case .beginner:
                lower = 0
                upper = (idx + 1 < all.count) ? t(all[idx + 1]) - 1 : .greatestFiniteMagnitude

            case .elite:
                lower = t(.elite)
                upper = lower * 1.25          // ← your “elite buffer”

            default:
                lower = t(level)
                upper = (idx + 1 < all.count) ? t(all[idx + 1]) - 1 : .greatestFiniteMagnitude
            }

            return (lower ... upper).contains(oneRepMax)
        }
    }
}


