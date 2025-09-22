//
//  SortOptionSheet.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/19/25.
//

import SwiftUI

struct SortOptionSheet: View {
    let current: ExerciseSortOption
    let options: [ExerciseSortOption]   // caller filters templateCategories if needed
    let onPick: (ExerciseSortOption) -> Void

    // Reusable row
    @ViewBuilder private func row(_ opt: ExerciseSortOption) -> some View {
        Button {
            onPick(opt)
        } label: {
            HStack {
                Text(opt.rawValue)
                Spacer()
                if opt == current {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())           // full-row tap target
        }
        .buttonStyle(.plain)                     // remove default blue/tint
    }

    var body: some View {
        NavigationStack {
            List {
                // Complexity
                Section("Complexity") {
                    ForEach(options.filter { [.simple, .moderate, .complex].contains($0) }, id: \.rawValue) { row($0) }
                }
                // Template (only if present)
                if options.contains(.templateCategories) {
                    Section("Template") {
                        ForEach(options.filter { $0 == .templateCategories }, id: \.rawValue) { row($0) }
                    }
                }
                // Structure
                Section("Structure") {
                    ForEach(options.filter { [.upperLower, .pushPull].contains($0) }, id: \.rawValue) { row($0) }
                }
                // Attributes
                Section("Attributes") {
                    ForEach(options.filter { [.difficulty, .resistanceType, .effortType, .limbMovement].contains($0) }, id: \.rawValue) { row($0) }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Sort Categories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
