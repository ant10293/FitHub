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
    @Environment(\.dismiss) private var dismiss
    @State private var expandedTemplateID: WorkoutTemplate.ID?
    @State private var adjustmentMessage: String? = nil
    let workoutChanges: WorkoutChanges

    var body: some View {
        NavigationStack {
            let templates = ctx.userData.workoutPlans.trainerTemplates
            let agg = aggregateRemovals(templates: templates, workoutChanges: workoutChanges)

            VStack(spacing: 12) {
                // ⚠️ Inline summary banner (plain, not inside the List)
                if let top = agg.first {
                    ReductionSummaryBanner(top: top) { reason in
                        switch reason {
                        case .effort:
                            ctx.userData.workoutPrefs.customDistribution = nil
                            adjustmentMessage = "Erased Custom Effort Distribution"
                        case .disliked:
                            ctx.userData.allowDisliked = true
                            adjustmentMessage = "Allowing Inclusion of Disliked Exercises"
                        case .resistance:
                            let initial = ctx.userData.workoutPrefs.resistance
                            let new: ResistanceType = .any
                            ctx.userData.workoutPrefs.resistance = new
                            adjustmentMessage = "Resistance Selection \(initial.rawValue) → \(new.rawValue)"
                        case .sets:
                            ctx.userData.workoutPrefs.customSets = nil
                            adjustmentMessage = "Erased Custom Sets"
                        case .repCap, .repMin, .noData, .tooDifficult, .cannotPerform, .split:
                            break
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }

                if let msg = adjustmentMessage {
                    ErrorFooter(message: msg, color: .orange)

                    RectangularButton(
                        title: "Regenerate Templates",
                        systemImage: "arrow.clockwise",
                        fontWeight: .bold,
                        action: {
                            dismiss()
                            ctx.userData.generateWorkoutPlan(
                                exerciseData: ctx.exercises,
                                equipmentData: ctx.equipment,
                                keepCurrentExercises: false,
                                generationDisabled: ctx.disableCreatePlan
                            )
                        }
                    )
                    .padding(.horizontal)
                }

                // Main content list
                ScrollView {
                    Section {
                        if templates.isEmpty {
                            Text("No Trainer Templates")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(templates, id: \.id) { tpl in
                                TemplateReasoning(
                                    template: tpl,
                                    reductions: workoutChanges.pool(for: tpl.id),
                                    allExercises: ctx.exercises.allExercises,
                                    isExpanded: Binding(
                                        get: { expandedTemplateID == tpl.id },
                                        set: { $0 ? (expandedTemplateID = tpl.id) : (expandedTemplateID = nil) }
                                    )
                                )
                                .cardContainer()
                            }
                        }
                    } header: {
                        HStack {
                            Text("Generated Templates")
                            Spacer()
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Potential Issues", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: Aggregation
    private func aggregateRemovals(
        templates: [WorkoutTemplate],
        workoutChanges: WorkoutChanges
    ) -> [AggregatedReasonStat] {
        var map: [PoolChanges.ReductionReason: AggregatedReasonStat] = [:]

        for tpl in templates {
            guard let pr = workoutChanges.pool(for: tpl.id) else { continue }

            for rc in pr.reasons where rc.reason.hasAction == true {
                let removedCount = rc.removed ?? rc.exerciseIDs.count
                guard removedCount > 0 else { continue }

                var entry = map[rc.reason] ?? AggregatedReasonStat(
                    reason: rc.reason,
                    totalRemoved: 0,
                    templatesAffected: [],
                    sampleExerciseIDs: []
                )
                entry.totalRemoved += removedCount
                entry.templatesAffected.insert(tpl.id)

                if entry.sampleExerciseIDs.count < 12 {
                    entry.sampleExerciseIDs.append(contentsOf: rc.exerciseIDs.prefix(12 - entry.sampleExerciseIDs.count))
                }
                map[rc.reason] = entry
            }
        }

        return map.values
            .filter { $0.totalRemoved > 0 }
            .sorted {
                if $0.totalRemoved != $1.totalRemoved { return $0.totalRemoved > $1.totalRemoved }
                if $0.templatesAffected.count != $1.templatesAffected.count { return $0.templatesAffected.count > $1.templatesAffected.count }
                return $0.reason.description < $1.reason.description
            }
    }
}

// MARK: - AggregatedReasonStat
private struct AggregatedReasonStat: Identifiable {
    let reason: PoolChanges.ReductionReason
    var totalRemoved: Int
    var templatesAffected: Set<WorkoutTemplate.ID>
    var sampleExerciseIDs: [Exercise.ID]

    var id: PoolChanges.ReductionReason { reason }
}

// MARK: - ReductionSummaryBanner
private struct ReductionSummaryBanner: View {
    @State private var isAdjusted: Bool = false
    let top: AggregatedReasonStat
    let onAdjust: (PoolChanges.ReductionReason) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: top.reason.icon)
                .imageScale(.large)
                .foregroundStyle(top.reason.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text("Largest Reduction: \(top.reason.description)")
                    .font(.subheadline).bold()
                let count = top.templatesAffected.count
                Text("\(top.totalRemoved) filtered across \(Format.countText(count, base: "template"))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Adjust") {
                onAdjust(top.reason)
                isAdjusted = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAdjusted)
        }
    }
}

// MARK: - TemplateReasoning
private struct TemplateReasoning: View {
    @State private var selectedView: ViewOption = .filtering
    let template: WorkoutTemplate
    let reductions: PoolChanges?
    let allExercises: [Exercise]
    @Binding var isExpanded: Bool

    private let previewCount = 3

    var body: some View {
        // Combined list + the set of relaxed filters
        let combined = combinedReductionsAndRelaxed(reductions)
        let items = combined.items
        let relaxedFilters = combined.relaxedFilters

        let byId = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })

        TappableDisclosure(isExpanded: $isExpanded) {
            HStack {
                if let reductions, !reductions.relaxedFilters.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.yellow)
                }
                VStack(alignment: .leading) {
                    Text(template.name)
                        .font(.headline)
                    
                    if !template.categories.isEmpty {
                        Text(SplitCategory.concatenateCategories(for: template.categories))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text(Format.countText(template.exercises.count, capitalize: true))
                        if let est = template.estimatedCompletionTime {
                            Text("•")
                            Text("Est. Duration: \(est.displayStringCompact)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
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
                    Picker("Select View", selection: $selectedView) {
                        ForEach(ViewOption.allCases, id: \.self) { view in
                            Text(view.rawValue).tag(view)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    switch selectedView {
                    case .filtering:
                        ForEach(items, id: \.reason) { rc in
                            ReasonRow(
                                rc: rc,
                                byId: byId,
                                previewCount: previewCount,
                                relaxedFilters: relaxedFilters   // pass filters (not reasons)
                            )
                        }
                    case .exercises:
                        ForEach(template.exercises, id: \.id) { ex in
                            ExerciseSetChange(newExercise: ex, oldExercise: nil)
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    private enum ViewOption: String, CaseIterable {
        case filtering = "Filtering"
        case exercises = "Exercises"
    }

    private func filteredAndSortedReductions(_ reductionOpt: PoolChanges?) -> [PoolChanges.ReasoningCount] {
        guard let reduction = reductionOpt else { return [] }
        return reduction.reasons
            .filter { !$0.exerciseIDs.isEmpty || ($0.removed ?? 0) > 0 }
            .sorted {
                let l = ($0.removed ?? 0, $0.exerciseIDs.count, $0.reason.description)
                let r = ($1.removed ?? 0, $1.exerciseIDs.count, $1.reason.description)
                return l.0 != r.0 ? l.0 > r.0 : (l.1 != r.1 ? l.1 > r.1 : l.2 < r.2)
            }
    }

    /// Combine reductions + relaxed without duplication.
    /// - Reductions: strongest-first (unchanged).
    /// - Relaxed-only rows: appended in RelaxedFilter.defaultOrder.
    /// - Returns: items + **Set<RelaxedFilter>** for row rendering.
    private func combinedReductionsAndRelaxed(_ reductionOpt: PoolChanges?)
    -> (items: [PoolChanges.ReasoningCount], relaxedFilters: Set<PoolChanges.RelaxedFilter>) {
        let reduced = filteredAndSortedReductions(reductionOpt)

        guard let reduction = reductionOpt else {
            return (reduced, [])
        }

        let existingReasons = Set(reduced.map { $0.reason })

        // Sort stored relaxed filters by enum order, then dedupe while preserving that order
        let sortedFilters = reduction.relaxedFilters.sorted()
        var orderedRelaxed: [PoolChanges.RelaxedFilter] = []
        orderedRelaxed.reserveCapacity(sortedFilters.count)
        var seen = Set<PoolChanges.RelaxedFilter>()
        for f in sortedFilters where !seen.contains(f) {
            seen.insert(f)
            orderedRelaxed.append(f)
        }

        // Synthesize rows for relaxed filters whose reduction isn't already present
        var synthetic: [PoolChanges.ReasoningCount] = []
        for f in orderedRelaxed {
            let rr = f.correspondingReduction
            if !existingReasons.contains(rr) {
                synthetic.append(PoolChanges.ReasoningCount(reason: rr))
            }
        }

        return (reduced + synthetic, Set(orderedRelaxed))
    }
}

// MARK: - ReasonRow
private struct ReasonRow: View {
    let rc: PoolChanges.ReasoningCount
    let byId: [Exercise.ID: Exercise]
    let previewCount: Int
    let relaxedFilters: Set<PoolChanges.RelaxedFilter>?   // << use filters, not reasons

    @State private var showAll = false

    var body: some View {
        let names   = rc.exerciseIDs.compactMap { byId[$0]?.name }
        let visible = showAll ? names : Array(names.prefix(previewCount))

        // Find which relaxed filter (if any) maps to this reduction reason
        let matchingRelaxedFilter: PoolChanges.RelaxedFilter? = {
            guard let filters = relaxedFilters else { return nil }
            return filters.first { $0.correspondingReduction == rc.reason }
        }()
        let isRelaxed = (matchingRelaxedFilter != nil)

        VStack(alignment: .leading, spacing: 3) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Image(systemName: rc.reason.icon)
                    .imageScale(.small)
                    .foregroundStyle(rc.reason.tint)

                if let f = matchingRelaxedFilter {
                    Text("Relaxed \(f.label) Filter")
                        .font(.subheadline).bold()
                } else {
                    Text(rc.reason.description)
                        .font(.subheadline).bold()
                }
                Spacer(minLength: 0)
            }

            // Footnote
            Group {
                if !isRelaxed {
                    let count = rc.removed ?? names.count
                    Text("\(Format.countText(count)) filtered out")
                    if let remaining = rc.afterCount {
                        Text("\(remaining) remaining in pool")
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            // Names list hidden when relaxed
            if !isRelaxed, !names.isEmpty {
                ForEach(visible, id: \.self) { name in
                    Text("• ").font(.footnote).bold() + Text(name).font(.footnote)
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
