import SwiftUI

struct SetCountEditor: View {
    @Binding var sets: SetDistribution
    let allowed: ClosedRange<Int> = 1...10
    var effort: EffortDistribution

    private var visibleTypes: [EffortType] {
        EffortType.strengthTypes.filter { effort.percentage(for: $0) > 0 }
    }

    private var hiddenTypes: [EffortType] {
        EffortType.strengthTypes.filter { effort.percentage(for: $0) <= 0 }
    }

    private func binding(for type: EffortType) -> Binding<Int> {
        Binding(
            get: { sets.sets(for: type) },
            set: { sets.modify(for: type, with: $0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Visible rows only
            ForEach(visibleTypes, id: \.self) { t in
                CountRow(
                    title: t.rawValue,
                    value: binding(for: t),
                    allowed: allowed
                )
            }

            // Hidden notice
            if !hiddenTypes.isEmpty {
                let names = hiddenTypes.map { $0.rawValue }.joined(separator: ", ")
                Text("Hidden: \(names) — \(names.count < 1 ? "each " : "")has 0% effort distribution.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.trailing)
    }

    struct CountRow: View {
        let title: String
        @Binding var value: Int
        let allowed: ClosedRange<Int>

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                // Title + % + live summary
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text("\(Format.countText(value, base: "set"))")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                // Stepper row
                HStack(spacing: 12) {
                    Text("Count")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(value)")
                        .font(.body)
                        .monospacedDigit()
                    Stepper("", value: $value, in: allowed)
                        .labelsHidden()
                }
            }
        }
    }
}
