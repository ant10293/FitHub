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
                
                if setChange.loadChange != nil //setChange.weightChange != nil
                    || setChange.metricChange != nil {
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
                /*
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
                */
                // Previous values
                             setInfoView(
                                 title: "Previous",
                                 set: setChange.previousSet,
                                 isPrevious: true
                             )
                
                // Arrow
                VStack {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("→")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                /*
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
                */
                // New values
                                setInfoView(
                                    title: "New",
                                    set: setChange.newSet,
                                    isPrevious: false,
                                    loadChange: setChange.loadChange,
                                    metricChange: setChange.metricChange
                                )
                
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
        private func setInfoView(
            title: String,
            set: SetDetail?,
            isPrevious: Bool,
            loadChange: SetChange.LoadChange? = nil,
            metricChange: SetChange.MetricChange? = nil
        ) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isPrevious ? .secondary : .primary)
                
                if let set = set {
                    let load = set.load
                    // Load info
                    if load != .none {
                        HStack {
                            Image(systemName: load.iconName)
                                .foregroundStyle(isPrevious ? .secondary : .primary)
                                .font(.caption2)
                            Text(load.displayString)
                                .font(.caption)
                                .fontWeight(isPrevious ? .regular : .medium)
                                .foregroundStyle(isPrevious ? .secondary : .primary)
                        }
                    }
                    
                    // Metric info
                    HStack {
                        Image(systemName: set.planned.iconName)
                            .foregroundStyle(isPrevious ? .secondary : .primary)
                            .font(.caption2)
                        Text(set.planned.fieldString)
                            .font(.caption)
                            .fontWeight(isPrevious ? .regular : .medium)
                            .foregroundStyle(isPrevious ? .secondary : .primary)
                        
                        // Change indicator for new values only
                        if !isPrevious {
                            if let loadChange = loadChange {
                                Image(systemName: loadChange.isIncrease ? "arrow.up" : "arrow.down")
                                    .foregroundStyle(loadChange.isIncrease ? .green : .red)
                                    .font(.caption2)
                            } else if let metricChange = metricChange {
                                Image(systemName: metricChange.newValue > metricChange.previousValue ? "arrow.up" : "arrow.down")
                                    .foregroundStyle(metricChange.newValue > metricChange.previousValue ? .green : .red)
                                    .font(.caption2)
                            }
                        }
                    }
                } else {
                    Text("New exercise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
}

