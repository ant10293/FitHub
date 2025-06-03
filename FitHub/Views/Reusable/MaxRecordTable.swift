//
//  MaxRecordTable.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct MaxRecordTable: View {
    let oneRepMax: Double
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    
    var body: some View {
        let percentages: [(percentage: Double, reps: Int)] = [
            (100, 1), (95, 2), (90, 4), (85, 6), (80, 8),
            (75, 10), (70, 12), (65, 16), (60, 20), (55, 24), (50, 30)
        ]
        
        return VStack(spacing: 0) {
            ForEach(percentages.indices, id: \.self) { index in
                let entry = percentages[index]
                let weight = oneRepMax * (entry.percentage / 100)
                
                HStack {
                    Text("\(Int(entry.percentage))%")
                        .frame(width: 80, alignment: .leading) // Fixed width for consistent alignment
                    Spacer()
                    if weight == 0 {
                        Text("— lbs")
                            .frame(width: 80, alignment: .trailing) // Fixed width for consistent alignment
                    } else {
                        Text("\(weight, specifier: "%.1f") lbs")
                            .frame(width: 80, alignment: .trailing) // Fixed width for consistent alignment
                    }
                    Spacer()
                    Text("\(entry.reps) reps")
                        .frame(width: 100, alignment: .trailing) // Fixed width for consistent alignment
                }
                .padding(.vertical, 4)
                
                // Add a divider except for the last row
                if index < percentages.count - 1 {
                    Divider()
                }
            }
        }
    }
}

