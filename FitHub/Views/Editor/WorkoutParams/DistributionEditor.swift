import SwiftUI

struct DistributionEditor: View {
    @Binding var distribution: EffortDistribution

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            // ── Editable rows ────────────────────────────────────────────
            ForEach(EffortType.strengthTypes, id: \.self) { effort in
                let pctInt = distribution.displayPct(for: effort)

                VStack {
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
                        
                        Text("\(pctInt) %")
                            .monospacedDigit()
                            .lineLimit(1)
                            .layoutPriority(1)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    
                    if let recPct = effort.recommenedPct {
                        if pctInt > recPct.upperBound {
                            // Over the recommended cap → show max only
                            WarningFooter(message: "\(effort.rawValue) is high (\(pctInt)%). Keep ≤ \(recPct.upperBound)%")
                        } else if pctInt < recPct.lowerBound {
                            // Under the recommended floor → show min only
                            WarningFooter(message: "\(effort.rawValue) is low (\(pctInt)%). Aim ≥ \(recPct.lowerBound)%")
                        }
                    }
                }
            }

            // ── Total read-out ───────────────────────────────────────────
            HStack {
                Text("Total: \(totalPct) %")
                if totalPct != 100 {
                    Text("(sum must equal 100 %)").italic()
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

    /// Keep your original “room left” behavior, just routed through EffortDistribution.
    private func applyChange(for effort: EffortType, newPct: Double) {
        let proposed   = max(0, min(newPct, 100)) / 100            // → 0…1
        let currentVal = distribution.percentage(for: effort)
        let remainder  = max(0, total - currentVal)                 // sum of OTHER sliders
        let roomLeft   = max(0, 1.0 - remainder)                    // available headroom to keep sum ≤ 1
        distribution.modify(for: effort, with: min(proposed, roomLeft))
    }
}
