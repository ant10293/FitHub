//
//  MaxRepsTable.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/17/25.
//

import SwiftUI


// MARK: – Max-Reps (body-weight) table
struct MaxRepsTable: View {
    private let percents = Array(stride(from: 100, through: 50, by: -5))
    let maxReps: Int

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 4) {
            ForEach(percents, id: \.self) { pct in
                GridRow {
                    // % column
                    (Text("\(pct)") +
                       Text("%")
                          .textScale(.secondary)
                          .fontWeight(.light))
                          .gridColumnAlignment(.leading)
                    
                    // reps column (or dash if maxReps == 0)
                    Group {
                        if maxReps == 0 {
                            Text("— ") +
                            Text("reps")
                        } else {
                            let r = reps(at: pct)
                            Text("\(r) ") +
                            Text(r == 1 ? "rep" : "reps")
                        }
                    }
                    .fontWeight(.light)
                    .gridColumnAlignment(.trailing)
                }

                // full-width divider
                if pct != percents.last {
                    Divider()
                        .gridCellColumns(2)
                }
            }
        }
    }
    
    private func reps(at percent: Int) -> Int {
        let rir = (100 - percent) / 5 // 0…10
        let est = maxReps - rir
        return max(est, 1)
    }
}
