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
                
                if setChange.loadChange != nil || setChange.metricChange != nil {
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

