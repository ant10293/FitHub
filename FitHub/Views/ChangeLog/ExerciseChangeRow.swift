//
//  ExerciseChangeRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import SwiftUI

struct ExerciseChangeRow: View {
    let change: ExerciseChange
    @State private var isExpanded = false

    var body: some View {
        TappableDisclosure(isExpanded: $isExpanded) {
            // LABEL
            HStack(spacing: 8) {
                Image(systemName: change.changeType.icon)
                    .foregroundStyle(change.changeType.color)

                Text(change.exerciseName)
                    .font(.subheadline).fontWeight(.medium)

                Text(change.changeType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(change.changeType.color.opacity(0.12))
                    .foregroundStyle(change.changeType.color)
                    .clipShape(Capsule())
            }
        } content: {
            // CONTENT
            VStack(alignment: .leading, spacing: 8) {
                if let maxRecordInfo = change.maxRecordInfo {
                    MaxRecordInfoRow(maxRecordInfo: maxRecordInfo)
                }
                VStack(spacing: 6) {
                    ForEach(change.setChanges) { setChange in
                        SetChangeRow(setChange: setChange)
                    }
                }
                if let progression = change.progressionDetails {
                    ProgressionDetailsRow(progression: progression)
                }
            }
            .padding(.leading, 12)
            .padding(.top, 8)
        }
    }
}

struct MaxRecordInfoRow: View {
    let maxRecordInfo: MaxRecordInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.gold)
                    .font(.caption)
                
                Text("Max Record Info")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gold)
                
                Spacer()
            }
            
            Text(maxRecordInfo.displayText)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let weeksSince = maxRecordInfo.weeksSinceLastUpdate {
                Text("Last updated \(weeksSince) week\(weeksSince == 1 ? "" : "s") ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ProgressionDetailsRow: View {
    let progression: ProgressionDetails
    
    var body: some View {
        HStack {
            Image(systemName: progression.progressionIcon)
                .foregroundStyle(progression.progressionColor)
            
            Text(progression.appliedChange)
                .font(.caption)
                .foregroundStyle(progression.progressionColor)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(progression.progressionColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
