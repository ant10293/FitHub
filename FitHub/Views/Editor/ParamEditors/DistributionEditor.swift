import SwiftUI

struct DistributionEditor: View {
    @Binding var distribution: ExerciseDistribution

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            // ── Editable rows ────────────────────────────────────────────
            ForEach(EffortType.allCases, id: \.self) { effort in
                HStack {
                    Text(effort.rawValue)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Slider(
                        value: sliderBinding(for: effort),
                        in: 0...100,
                        step: 1
                    )

                    Text("\(distribution.displayPct(for: effort)) %")
                        .monospacedDigit()
                        .lineLimit(1)
                        .layoutPriority(1)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }

            // ── Total read-out ───────────────────────────────────────────
            HStack {
                Text("Total: \(totalPct) %")
                if totalPct != 100 {
                    Text("[sum must equal 100 %]").italic()
                }
            }
            .font(.footnote)
            .foregroundStyle(totalPct == 100 ? Color.secondary : Color.red)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: helpers
    private var total: Double { distribution.total }
    private var totalPct: Int { Int((total * 100).rounded()) }
    
    private func sliderBinding(for effort: EffortType) -> Binding<Double> {
        Binding(
            get: { distribution.percentage(for: effort) * 100 },
            set: { newPct in applyChange(for: effort, newPct: newPct) }
        )
    }

    /// Keep your original “room left” behavior, just routed through ExerciseDistribution.
    private func applyChange(for effort: EffortType, newPct: Double) {
        let proposed   = max(0, min(newPct, 100)) / 100            // → 0…1
        let currentVal = distribution.percentage(for: effort)
        let remainder  = max(0, total - currentVal)                 // sum of OTHER sliders
        let roomLeft   = max(0, 1.0 - remainder)                    // available headroom to keep sum ≤ 1
        distribution.modify(for: effort, with: min(proposed, roomLeft))
    }
}
