//
//  OneRMTable.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


// MARK: – One-RM percentage table
struct OneRMTable: View {
    let oneRepMax: Double

    private let rows: [(pct: Int, reps: Int)] = [
        (100, 1), (95, 2), (90, 4), (85, 6), (80, 8),
        (75, 10), (70, 12), (65, 16), (60, 20), (55, 24), (50, 30)
    ]

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 4) {
            ForEach(rows, id: \.pct) { row in
                GridRow {
                    // % column
                    (Text("\(row.pct)") +
                     Text("%")
                        .textScale(.secondary)
                        .fontWeight(.light))
                        .gridColumnAlignment(.leading)

                    // weight column
                    let weight = oneRepMax * Double(row.pct) / 100
                    (Text(weight > 0 ? String(format: "%.0f", weight) : "—") +
                     Text(" lbs").fontWeight(.light))
                        .gridColumnAlignment(.center)

                    // reps column
                    (Text("\(row.reps) ") +
                     Text(row.reps == 1 ? "rep" : "reps")
                        .fontWeight(.light))
                        .gridColumnAlignment(.trailing)
                }

                if row.pct != rows.last?.pct {
                    Divider()
                        .gridCellColumns(3)
                }
            }
        }
    }
}
