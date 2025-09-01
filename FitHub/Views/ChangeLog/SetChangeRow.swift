//
//  SetChangeRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import SwiftUI

struct SetChangeRow: View {
    let setChange: SetChange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Set \(setChange.setNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if setChange.weightChange != nil || setChange.metricChange != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.blue)
                            .font(.caption2)
                        Text("Modified")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 16) {
                // Previous values
                VStack(alignment: .leading, spacing: 6) {
                    Text("Previous")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    if let previousSet = setChange.previousSet {
                        if previousSet.weight.displayValue > 0 {
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                                previousSet.weight.formattedText()
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        HStack {
                            Image(systemName: setChange.newSet.planned.repsValue != nil ? "number" : "clock")
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                            Text(previousSet.planned.fieldString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("New exercise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow
                VStack {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("→")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                
                // New values
                VStack(alignment: .leading, spacing: 6) {
                    Text("New")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if setChange.newSet.weight.displayValue > 0 {
                        HStack {
                            Image(systemName: "scalemass")
                                .foregroundStyle(.primary)
                                .font(.caption2)
                            setChange.newSet.weight.formattedText()
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            if let weightChange = setChange.weightChange {
                                Image(systemName: weightChange.isIncrease ? "arrow.up" : "arrow.down")
                                    .foregroundStyle(weightChange.isIncrease ? .green : .red)
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: setChange.newSet.planned.repsValue != nil ? "number" : "clock")
                            .foregroundStyle(.primary)
                            .font(.caption2)
                        Text(setChange.newSet.planned.fieldString)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if let metricChange = setChange.metricChange {
                            Image(systemName: metricChange.newValue > metricChange.previousValue ? "arrow.up" : "arrow.down")
                                .foregroundStyle(metricChange.newValue > metricChange.previousValue ? .green : .red)
                                .font(.caption2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 4)
    }
}
