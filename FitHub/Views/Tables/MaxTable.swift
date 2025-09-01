//
//  MaxTable.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/15/25.
//

import SwiftUI

struct MaxTable: View {
    let peak: PeakMetric

    // Rendered percent steps (shared across all modes)
    private let percents = Array(stride(from: 100, through: 50, by: -5))

    // Standard 1RM % → reps mapping
    private let oneRMReps: [Int: Int] = [
        100: 1, 95: 2, 90: 4, 85: 6, 80: 8,
        75: 10, 70: 12, 65: 16, 60: 20, 55: 24, 50: 30
    ]

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 4) {
            ForEach(percents, id: \.self) { pct in
                GridRow {
                    // ── Col 1: percent label (always shown)
                    (Text("\(pct)") + Text("%").textScale(.secondary).fontWeight(.light))
                        .gridColumnAlignment(.leading)

                    // ── Col 2 & Col 3: depend on metric type
                    switch peak {
                    case .oneRepMax(let oneRM):
                        // Col 2: weight at %
                        let weight = oneRM.displayValue * Double(pct) / 100.0
                        (Text(weight > 0 ? Format.smartFormat(weight) : "—")
                         + Text(" \(UnitSystem.current.weightUnit)").fontWeight(.light))
                            .gridColumnAlignment(.center)

                        // Col 3: reps at % (from the mapping)
                        let reps = oneRMReps[pct] ?? 1
                        (Text("\(reps) ") + Text(reps == 1 ? "rep" : "reps").fontWeight(.light))
                            .gridColumnAlignment(.trailing)

                    case .maxReps(let maxReps):
                        // Col 3: empty to keep grid structure consistent
                        Text(" ").hidden()
                            .gridColumnAlignment(.center)
                        
                        // Col 2: reps estimate via RIR-style rule
                        let r = repsFromPercent(pct, maxReps: maxReps)
                        (Text(maxReps > 0 ? "\(r) " : "— ")
                         + Text(maxReps > 0 ? (r == 1 ? "rep" : "reps") : "reps"))
                            .fontWeight(.light)
                            .gridColumnAlignment(.trailing)

                    case .maxHold(let span):
                        // Col 3: empty to keep grid structure consistent
                        Text(" ").hidden()
                            .gridColumnAlignment(.center)
                        
                        // Col 2: time scaled by %
                        let secs = Int((Double(span.inSeconds) * Double(pct) / 100.0).rounded())
                        Text(secs > 0 ? TimeSpan.fromSeconds(secs).displayStringCompact : "—")
                            .fontWeight(.light)
                            .gridColumnAlignment(.trailing)
                    }
                }

                if pct != percents.last {
                    Divider().gridCellColumns(3)
                }
            }
        }
    }

    // MARK: - Helpers

    /// For max-reps: each –5% ≈ +1 RIR ⇒ reps = maxReps – ((100–pct)/5), clamped at 1.
    private func repsFromPercent(_ pct: Int, maxReps: Int) -> Int {
        let rir = max(0, (100 - pct) / 5)
        return max(1, maxReps - rir)
    }
}
