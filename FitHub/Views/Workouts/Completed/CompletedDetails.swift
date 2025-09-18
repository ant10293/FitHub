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
                    Text(categories)
                        .multilineTextAlignment(.leading)
                        .padding(.top)

                    Text("Date: \(Format.formatDate(workout.date, dateStyle: .full, timeStyle: .short))")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                    
                    Text("Duration: \(Format.formatDuration(workout.duration, roundSeconds: true))")
                        .font(.subheadline)
                        .padding(.bottom, 5)
                        .multilineTextAlignment(.leading)
                    
                    ForEach(workout.template.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(exercise.name)
                                .font(.subheadline)
                                .padding(.top, 10)
                                .multilineTextAlignment(.leading)
                            
                            if let supersettedWith = exercise.isSupersettedWith {
                                Text("(Supersetted with \(supersettedWith))")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Text("Time spent: \(Format.formatDuration(exercise.timeSpent))")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            
                            if !exercise.warmUpDetails.isEmpty {
                                exerciseSets(exercise: exercise, details: exercise.warmUpDetails, warmup: true)
                                Divider().padding(.vertical, 4)
                            }
                            
                            exerciseSets(exercise: exercise, details: exercise.setDetails, warmup: false)
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
private extension CompletedDetails {
    func exerciseSets(exercise: Exercise, details: [SetDetail], warmup: Bool) -> some View {
        ForEach(details) { set in
            VStack(alignment: .leading, spacing: 2) {
                // Single line: planned + completed + RPE
                SetRow(set: set, exercise: exercise, warmup: warmup)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                prBadge(for: exercise, set: set)
            }
        }
    }
    
    @ViewBuilder func prBadge(for exercise: Exercise, set: SetDetail) -> some View {
        // PR line (unchanged logic)
        if let prUpdate = workout.updatedMax.first(where: {
            $0.exerciseId == exercise.id && $0.setId == set.id //$0.setNumber == set.setNumber
        }),
           let prRepsWeight = prUpdate.repsXweight {
            HStack {
                Image(systemName: "trophy.fill")
                if exercise.resistance.usesWeight {
                    if prRepsWeight.reps > 1 {
                        prRepsWeight.formattedText +
                        Text(" = ") +
                        prUpdate.value.labeledText
                    } else {
                        prUpdate.value.labeledText
                    }
                } else {
                    prUpdate.value.labeledText
                }
                Spacer(minLength: 0)
            }
            .font(.caption2)
            .foregroundStyle(Color.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - A single set row (planned + completed + RPE on one line)
private extension CompletedDetails {
    struct SetRow: View {
        let set: SetDetail
        let exercise: Exercise
        let warmup: Bool
        
        var body: some View {
            HStack(spacing: 6) {
                Text("\(warmup ? "Warm-up " : "")Set \(set.setNumber):")
                    .fontWeight(.bold)
                
                // Planned (weight if relevant) + target (reps or time)
                plannedText(set: set, usesWeight: exercise.resistance.usesWeight)
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
        
        // Build planned text (weight if relevant + reps/time)
        private func plannedText(set: SetDetail, usesWeight: Bool) -> Text {
            let planStr = displayString(for: set.planned)
            if usesWeight {
                return set.weight.formattedText()
                + Text(" × ").foregroundStyle(.gray)
                + Text(planStr).fontWeight(.light)
            } else {
                return Text(planStr).fontWeight(.light)
            }
        }
        
        // Convert SetMetric → user-facing string
        private func displayString(for metric: SetMetric) -> String {
            switch metric {
            case .reps(let r):
                return "\(max(0, r)) reps"
            case .hold(let span):
                return span.displayStringCompact // e.g. "0:45" or "12:03"
            }
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
                    Text("@ RPE \(String(format: "%.1f", rpe))")
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        private func completedDisplay() -> (String, Color) {
            // If not logged, show planned as neutral
            guard let comp = completed else {
                return (string(from: planned) + " completed", .secondary)
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
            }
        }
        
        private func normalized(_ m: SetMetric) -> Double {
            switch m {
            case .reps(let r): return Double(max(0, r))
            case .hold(let span): return Double(max(0, span.inSeconds))
            }
        }
    }
}
