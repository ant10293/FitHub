//
//  GenerationWarning.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/20/25.
//
import SwiftUI

// MARK: - GenerationWarning (top-level)
struct GenerationWarning: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var expandedTemplateID: WorkoutTemplate.ID?
    let workoutReductions: WorkoutReductions

    var body: some View {
        let templates = ctx.userData.workoutPlans.trainerTemplates
        let allExercises = ctx.exercises.allExercises

        List {
            Section("Generation Warnings") {
                if templates.isEmpty {
                    Text("No Trainer Templates")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(templates, id: \.id) { tpl in
                        TemplateReasoning(
                            template: tpl,
                            reductions: workoutReductions.pool(for: tpl.id),
                            allExercises: allExercises,
                            isExpanded: Binding(
                                get: { expandedTemplateID == tpl.id },
                                set: { $0 ? (expandedTemplateID = tpl.id) : (expandedTemplateID = nil) }
                            )
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - TemplateReasoning (one disclosure per template)
private struct TemplateReasoning: View {
    let template: WorkoutTemplate
    let reductions: PoolReduction?
    let allExercises: [Exercise]
    @Binding var isExpanded: Bool

    private let previewCount = 3

    var body: some View {
        
        let items = filteredAndSorted(reductions)
        let byId = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })

        TappableDisclosure(isExpanded: $isExpanded) {
            // TODO: display a warning symbol if not enough exercises or if filter was relaxed
            VStack(alignment: .leading) {
                Text(template.name)
                    .font(.headline)
                
                HStack {
                    Text(Format.exerciseCountText(template.exercises.count))
                    if let est = template.estimatedCompletionTime {
                        Text("•")
                        Text("Est. Completion: \(est.displayStringCompact)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } content: {
            if items.isEmpty {
                Text(reductions == nil
                     ? "No reduction data recorded."
                     : "No meaningful reductions.")
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(items, id: \.reason) { rc in
                        ReasonRow(
                            rc: rc,
                            byId: byId,
                            previewCount: previewCount
                        )
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    // Keep only reasons with signal; sort strongest-first
    private func filteredAndSorted(_ reductionOpt: PoolReduction?) -> [PoolReduction.ReasoningCount] {
        guard let reduction = reductionOpt else { return [] }
        return reduction.reasons
            .filter { !$0.exerciseIDs.isEmpty || ($0.removed ?? 0) > 0 }
            .sorted {
                let l = ($0.removed ?? 0, $0.exerciseIDs.count, $0.reason.description)
                let r = ($1.removed ?? 0, $1.exerciseIDs.count, $1.reason.description)
                return l.0 != r.0 ? l.0 > r.0 : (l.1 != r.1 ? l.1 > r.1 : l.2 < r.2)
            }
    }
}

// MARK: - ReasonRow (bullet list for names; no "Removed" pill; updated count copy)
private struct ReasonRow: View {
    let rc: PoolReduction.ReasoningCount
    let byId: [Exercise.ID: Exercise]
    let previewCount: Int

    @State private var showAll = false

    var body: some View {
        let names = rc.exerciseIDs.compactMap { byId[$0]?.name }
        let visible = showAll ? names : Array(names.prefix(previewCount))

        VStack(alignment: .leading, spacing: 3) {
            // Header: small tinted icon + title (no removed chip)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Image(systemName: rc.reason.icon)
                    .imageScale(.small)
                    .foregroundStyle(rc.reason.tint)   // tint applied to icon only
                Text(rc.reason.description)
                    .font(.subheadline).bold()
                Spacer(minLength: 0)
            }

            let count = rc.removed ?? names.count
            // Updated copy
            Group {
                Text("\(Format.exerciseCountText(count)) filtered out")
                if let remaining = rc.remaining {
                    Text("\(remaining) remaining in pool")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            
            if !names.isEmpty {
                // Bullet list (text bullet •, not an icon)
                ForEach(visible, id: \.self) { name in
                    Text("• ").font(.footnote).bold()
                    +
                    Text(name).font(.footnote)
                }
                
                if names.count > previewCount {
                    Button(showAll ? "View less" : "View all") {
                        withAnimation(.snappy) { showAll.toggle() }
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.leading)
                }
            }
        }
    }
}


