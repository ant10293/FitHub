//
//  CompletedDetails.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct CompletedDetails: View {
    let workout: CompletedWorkout
    let categories: String
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !categories.isEmpty {
                        Text(categories)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                    }

                    Text("Date: \(Format.formatDate(workout.date, dateStyle: .full, timeStyle: .short))")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                    
                    Text("Duration: \(Format.formatDuration(workout.duration))")
                        .font(.subheadline)
                        .padding(.bottom, 5)
                        .multilineTextAlignment(.leading)
                    
                    ForEach(workout.template.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 5) {
                            let statusSuffix: Text = {
                                if exercise.isCompleted {
                                    return Text("") // no suffix
                                } else if exercise.noSetsCompleted {
                                    return Text(" (Skipped)").foregroundStyle(.red)
                                } else {
                                    return Text(" (Incomplete)").foregroundStyle(.orange)
                                }
                            }()

                            (
                            Text(exercise.name)
                                .font(.subheadline)
                            + statusSuffix
                                .font(.caption)
                            )
                            .padding(.top, 10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                            if let ex = workout.template.supersetFor(exercise: exercise) {
                                Text("(Supersetted with \(ex.name))")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Text("Time spent: \(Format.formatDuration(exercise.timeSpent))")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            
                            if !exercise.warmUpDetails.isEmpty {
                                CompletedDetails.exerciseSets(exercise: exercise, warmup: true, prs: workout.updatedMax)
                                Divider().padding(.vertical, 4)
                            }
                            
                            CompletedDetails.exerciseSets(exercise: exercise, warmup: false, prs: workout.updatedMax)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)   // ← row block stretches
                        .padding(.bottom, 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)             // ← key fix
                .padding(.horizontal)                                        // keep left/right padding
            }
        }
        .navigationBarTitle(workout.name, displayMode: .inline)
    }
}

// MARK: - Subviews / helpers
extension CompletedDetails {
    static func exerciseSets(exercise: Exercise, warmup: Bool, prs: [PerformanceUpdate]) -> some View {
        ForEach(warmup ? exercise.warmUpDetails : exercise.setDetails) { set in
            VStack(alignment: .leading, spacing: 2) {
                // Single line: planned + completed + RPE
                SetRow(set: set, warmup: warmup)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                prBadge(for: exercise.id, set: set, prs: prs)
            }
        }
    }
}

// MARK: - A single set row (planned + completed + RPE on one line)
private extension CompletedDetails {
    struct SetRow: View {
        let set: SetDetail
        let warmup: Bool
        
        var body: some View {
            HStack(spacing: 6) {
                Text("\(warmup ? "Warm-up " : "")Set \(set.setNumber):")
                    .fontWeight(.bold)
                
                // Planned (weight if relevant) + target (reps or time)
                set.formattedPlannedText
                    .fontWeight(.regular)

                // Completed + RPE inline on the same row
                CompletedMetricView(planned: set.planned,
                                    completed: set.completed,
                                    rpe: set.rpe)

                Spacer(minLength: 0)
            }
            .font(.caption)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder static func prBadge(for exerciseID: Exercise.ID, set: SetDetail, prs: [PerformanceUpdate]) -> some View {
        // PR line (unchanged logic)
        if let prUpdate = prs.first(where: {
            $0.exerciseId == exerciseID && $0.setId == set.id
        }) {
            HStack {
                Image(systemName: "trophy.fill")
                if let prLoadxMetric = prUpdate.loadXmetric, prUpdate.value.actualValue != set.load.actualValue {
                    prLoadxMetric.formattedText() +
                    Text(" ≈ ") +
                    prUpdate.value.labeledText
                } else {
                    prUpdate.value.labeledText
                }
            }
            .font(.caption2)
            .foregroundStyle(Color.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Inline completed metric + tint + RPE (same name, new inline usage)
private extension CompletedDetails {
    struct CompletedMetricView: View {
        let planned: SetMetric
        let completed: SetMetric?
        let rpe: Double?
        
        var body: some View {
            HStack(spacing: 6) {
                let (doneStr, tint) = completedDisplay()
                ( Text("→ ") + Text(doneStr).italic() )
                    .foregroundStyle(tint)
                
                if let rpe {
                    Text("@ RPE \(Format.smartFormat(rpe))")
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        private func completedDisplay() -> (String, Color) {
            // If not logged, show planned as neutral
            guard let comp = completed else {
                return (string(from: planned.zeroValue) + " completed", .secondary)
            }
            
            // Compare completed vs planned (reps as count, holds as seconds)
            let p = normalized(planned)
            let d = normalized(comp)
            let color: Color = (d == p) ? .blue : (d < p ? .red : .green)
            
            return (string(from: comp) + " completed", color)
        }
        
        private func string(from metric: SetMetric) -> String {
            switch metric {
            case .reps(let r): return "\(max(0, r)) reps"
            case .hold(let span): return span.displayStringCompact
            case .cardio(let ts): return ts.time.displayStringCompact
            }
        }
        
        private func normalized(_ m: SetMetric) -> Double {
            switch m {
            case .reps(let r): return Double(max(0, r))
            case .hold(let span): return Double(max(0, span.inSeconds))
            case .cardio(let ts): return Double(max(0, ts.time.inSeconds))
            }
        }
    }
}
