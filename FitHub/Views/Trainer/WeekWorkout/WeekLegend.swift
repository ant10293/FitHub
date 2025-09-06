//
//  WeekLegend.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/5/25.
//

import SwiftUI

struct WeekLegend: View {
    var body: some View {
        HStack(spacing: 15) {
            LegendItem(color: .blue, label: "Planned")
            LegendItem(color: .green, label: "Completed")
            LegendItem(color: .red, label: "Missed")
        }
        .padding(.top, 8)
    }
    
    struct LegendItem: View {
        var color: Color
        var label: String
        
        var body: some View {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.primary)
            }
        }
    }
}
