//
//  MaxTable.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/15/25.
//

import SwiftUI

struct MaxTable: View {
    let peak: PeakMetric

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 4) {
            ForEach(percents, id: \.self) { pct in
                ThreeColumnRow(
                    left: {
                        // LEFT: percent
                        (Text("\(pct)") + Text("%").textScale(.secondary).fontWeight(.light))
                    },
                    center: {
                        // MIDDLE: weight / time / empty, depending on mode
                        switch peak {
                        case .oneRepMax(let oneRM):
                            let weight = oneRM.displayValue * Double(pct) / 100.0
                            (Text(weight > 0 ? Format.smartFormat(weight) : "—")
                             + Text(" \(UnitSystem.current.weightUnit)").fontWeight(.light))

                        case .maxHold(let span):
                            let secs = Int((Double(span.inSeconds) * Double(pct) / 100.0).rounded())
                            Text(secs > 0 ? TimeSpan(seconds: secs).displayStringCompact : "—")
                                .fontWeight(.light)

                        default:
                            // keep column, just no content
                            Text(" ")
                        }
                    },
                    right: {
                        // RIGHT: reps / load / whatever
                        switch peak {
                        case .oneRepMax:
                            let reps = oneRMReps[pct] ?? 1
                            (Text("\(reps) ") + Text(reps == 1 ? "rep" : "reps").fontWeight(.light))

                        case .maxReps(let maxReps):
                            let r = repsFromPercent(pct, maxReps: maxReps)
                            (Text(maxReps > 0 ? "\(r) " : "— ")
                             + Text(maxReps > 0 ? (r == 1 ? "rep" : "reps") : "reps"))
                                .fontWeight(.light)

                        case .hold30sLoad(let l30):
                            let load = l30.displayValue * Double(pct) / 100.0
                            (Text(load > 0 ? Format.smartFormat(load) : "—")
                             + Text(" \(UnitSystem.current.weightUnit)").fontWeight(.light))

                        default:
                            Text(" ")
                        }
                    }
                )

                if pct != percents.last {
                    Divider().gridCellColumns(3)
                }
            }
        }
    }
    
    // Rendered percent steps (shared across all modes)
    private let percents = Array(stride(from: 100, through: 50, by: -5))

    // Standard 1RM % → reps mapping
    private let oneRMReps: [Int: Int] = [
        100: 1, 95: 2, 90: 4, 85: 6, 80: 8,
        75: 10, 70: 12, 65: 16, 60: 20, 55: 24, 50: 30
    ]
    /// For max-reps: each –5% ≈ +1 RIR ⇒ reps = maxReps – ((100–pct)/5), clamped at 1.
    private func repsFromPercent(_ pct: Int, maxReps: Int) -> Int {
        let rir = max(0, (100 - pct) / 5)
        return max(1, maxReps - rir)
    }
}


private struct ThreeColumnRow<Left: View, Center: View, Right: View>: View {
    private let left: Left
    private let center: Center
    private let right: Right

    init(
        @ViewBuilder left: () -> Left,
        @ViewBuilder center: () -> Center,
        @ViewBuilder right: () -> Right
    ) {
        self.left = left()
        self.center = center()
        self.right = right()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            left
                .frame(maxWidth: .infinity, alignment: .leading)

            center
                .frame(maxWidth: .infinity, alignment: .center)

            right
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}


