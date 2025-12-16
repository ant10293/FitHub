import SwiftUI

struct StrengthPercentileView: View {
    let maxValue: PeakMetric
    let age: Int
    let bodyweight: Mass
    let gender: Gender
    let exercise: Exercise
    let maxValuesAge: [String: PeakMetric]
    let maxValuesBW: [String: PeakMetric]
    let percentile: Int?

    var body: some View {
        VStack {
            Text("Strength Standards")
                .font(.title2)
                .padding(.vertical)

            // dont have any strength standards for isometric or cardio exercises
            maxView

            Text(exercise.performanceTitle(includeInstruction: true))
                .font(.headline)
                .padding(.top)
            
            ageBasedStats
                .padding(.bottom)
            weightBasedStats
        }
    }

    // MARK: - Subviews
    private var maxView: some View {
        let performanceTitle = exercise.performanceTitle(includeInstruction: false)
        if maxValue.actualValue <= 0 {
            return AnyView(
                Text("No \(performanceTitle) available for this exercise.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
            )
        } else {
            return AnyView(
                VStack {
                    if let percentile = percentile {
                        (Text("Your \(performanceTitle) of ")
                         + maxValue.labeledText.bold()
                         + Text(" makes you stronger than ")
                         + Text("\(percentile)%").bold()
                         + Text(" of \(gender)s in your weight and age range."))
                    } else {
                        Text("No percentile data available for this exercise.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .padding(.bottom)
                    }
                }
                .padding(.horizontal)
            )
        }
    }

    // NOTE: Titles were already correct; these sections just show the table and a gray detail.
    private var ageBasedStats: some View {
        statSection(
            title: "Based on Body Weight",
            key: .bodyweight,
            detail:
                (Text(" (")
                + bodyweight.formattedText(asInteger: true)
                + Text(")"))
                .foregroundStyle(.gray)
        )
    }

    private var weightBasedStats: some View {
        statSection(
            title: "Based on Age",
            key: .age,
            detail:
                (Text(" (\(age) ")
                + Text("years").fontWeight(.light)
                + Text(")"))
                .foregroundStyle(.gray)
        )
    }

    private func statSection(title: String, key: CSVColumn, detail: Text? = nil) -> some View {
        VStack(alignment: .leading) {
            // Header
            let header: Text = {
                if let detail { return Text(title).font(.headline) + detail }
                return Text(title)
            }()
            header

            Divider()

            if let values = get1RMValues(key: key) {
                HorizontalTableView(values: values, maxValue: maxValue.actualValue)
            } else {
                Text("No data available for \(key).")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding()
            }
        }
        .cardContainer(cornerRadius: 8, backgroundColor: Color(UIColor.secondarySystemBackground))
    }

    // MARK: - Helper Methods
    
    // Return only the *category* thresholds as PeakMetric, in display order.
    private func get1RMValues(key: CSVColumn) -> [(key: String, value: PeakMetric)]? {
        var values: [String: PeakMetric] = [:]

        switch key {
        case .age: values = maxValuesAge
        case .bodyweight: values = maxValuesBW
        }

        if values.isEmpty { return nil }

        // Only include strength categories (no "Age"/"BW" cells in the table)
        let wanted = ["Beg.", "Nov.", "Int.", "Adv.", "Elite"]
        let filtered = values.filter { wanted.contains($0.key) }
        if filtered.isEmpty { return nil }

        // Stable sort by our explicit order
        return filtered
            .map { ($0.key, $0.value) }
            .sorted { lhs, rhs in
                (wanted.firstIndex(of: lhs.0) ?? .max) < (wanted.firstIndex(of: rhs.0) ?? .max)
            }
    }

    private struct HorizontalTableView: View {
        var values: [(key: String, value: PeakMetric)]
        var maxValue: Double

        var body: some View {
            let userCategory = maxValue > 0 ? findUserCategory(maxValue, values: values) : nil

            HStack {
                ForEach(values, id: \.key) { category, metric in
                    VStack {
                        Text(category)
                            .font(.subheadline)
                        Divider().bold()
                        // PeakMetric handles unit rendering (e.g., "120 kg" or "18 reps")
                        Text("\(Int(round(metric.displayValue)))")
                            .font(.body)
                            .cardContainer(
                                cornerRadius: 5,
                                padding: 4,
                                backgroundColor: category == userCategory ? Color.yellow.opacity(0.4) : Color.clear
                            )
                    }
                }
            }
        }

        private func findUserCategory(_ maxValue: Double, values: [(key: String, value: PeakMetric)]) -> String {
            let rm = round(maxValue)

            // Map raw keys → enum and compare on numeric thresholds
            let thresholds: [StrengthLevel: Double] = Dictionary(
                uniqueKeysWithValues: values.compactMap { row in
                    guard let lvl = StrengthLevel(rawValue: row.key) else { return nil }
                    return (lvl, row.value.actualValue)
                }
            )

            // Iterate in the enum's natural order; pick the highest level you meet
            var winner = StrengthLevel.beginner.rawValue
            for level in StrengthLevel.allCases {
                if let t = thresholds[level], rm >= t {
                    winner = level.rawValue
                }
            }
            return winner
        }
    }
}
