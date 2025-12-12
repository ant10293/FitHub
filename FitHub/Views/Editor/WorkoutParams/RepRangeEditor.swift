import SwiftUI

struct RepRangeEditor: View {
    @Binding var reps: RepDistribution
    let allowed: ClosedRange<Int> = 1...30
    let minSpan: Int = 0
    var effort: EffortDistribution

    // Match SetCountEditor’s visibility logic
    private var visibleTypes: [EffortType] {
        RepDistribution.types.filter { effort.percentage(for: $0) > 0 }
    }
    private var hiddenTypes: [EffortType] {
        RepDistribution.types.filter { effort.percentage(for: $0) <= 0 }
    }

    private func binding(for effort: EffortType) -> Binding<ClosedRange<Int>> {
        Binding(
            get: { reps.reps(for: effort) },
            set: { reps.modify(for: effort, with: $0) }
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            // Visible rows only
            ForEach(visibleTypes, id: \.self) { t in
                IntRangeRow(
                    title: t.rawValue,
                    range: binding(for: t),
                    allowed: allowed,
                    minSpan: minSpan
                )
            }

            // Hidden notice (same style/message as SetCountEditor)
            if !hiddenTypes.isEmpty {
                let names = hiddenTypes.map { $0.rawValue }.joined(separator: ", ")
                Text("Hidden: \(names) — \(names.count < 1 ? "each " : "")has 0% effort distribution.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing)
    }

    // Re-usable row (unchanged aside from taking the binding)
    struct IntRangeRow: View {
        let title: String
        @Binding var range: ClosedRange<Int>
        let allowed: ClosedRange<Int>
        let minSpan: Int

        private func clamp(_ v: Int) -> Int {
            min(max(v, allowed.lowerBound), allowed.upperBound)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                // Title + live summary
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.headline)
                    Spacer()
                    Text("\(range.lowerBound)–\(range.upperBound) reps")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                // MIN row
                HStack(spacing: 12) {
                    Text("Min")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(range.lowerBound)")
                        .font(.body)
                        .monospacedDigit()
                    Stepper("", value: Binding(
                        get: { range.lowerBound },
                        set: { newMin in
                            let minV = clamp(newMin)
                            // enforce min span
                            let neededMax = minV + minSpan
                            let newMax = max(range.upperBound, neededMax)
                            range = clamp(minV)...clamp(newMax)
                        }
                    ), in: allowed)
                    .labelsHidden()
                }

                // MAX row
                HStack(spacing: 12) {
                    Text("Max")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(range.upperBound)")
                        .font(.body)
                        .monospacedDigit()
                    Stepper("", value: Binding(
                        get: { range.upperBound },
                        set: { newMax in
                            let maxV = clamp(newMax)
                            // enforce min span
                            let neededMin = maxV - minSpan
                            let newMin = min(range.lowerBound, neededMin)
                            range = clamp(newMin)...clamp(maxV)
                        }
                    ), in: allowed)
                    .labelsHidden()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
