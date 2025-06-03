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
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(workout.name)
                    .font(.headline)
                    .padding(.bottom, 5)
                
                Text(categories)
                
                Text("Date: \(workout.date, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Duration: \(workout.duration / 60) minutes")
                    .font(.subheadline)
                    .padding(.bottom, 5)
                
                ForEach(workout.template.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .padding(.top, 10)
                        
                        // Display a special indicator if the exercise is supersetted
                        if let supersettedWith = exercise.isSupersettedWith {
                            Text("(Supersetted with \(supersettedWith))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        // --- Show time spent on this exercise ---
                        Text("Time spent: \(formatTime(exercise.timeSpent))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        
                        // ─── Warm‑up Sets ────────────────────────────────────────────────
                        if !exercise.warmUpDetails.isEmpty {
                            ForEach(exercise.warmUpDetails.indices, id: \.self) { idx in
                                let set = exercise.warmUpDetails[idx]
                                HStack {
                                    Text("Warm‑up Set \(idx + 1):")
                                        .fontWeight(.bold)
                                        .font(.caption)
                                                                        
                                    let txt: Text = {
                                        if exercise.usesWeight {
                                            return Text(smartFormat(set.weight))
                                              + Text(" lbs").fontWeight(.light)
                                              + Text(" x ").foregroundColor(.gray)
                                              + Text("\(set.reps)")
                                              + Text(" reps").fontWeight(.light)
                                        } else {
                                            return Text("\(set.reps)")
                                              + Text(" reps planned").fontWeight(.light)
                                        }
                                    }()
                                    txt.font(.caption)

                                    RepsCompletedView(repsCompleted: set.repsCompleted, repsPlanned: set.reps)
                                }
                                .font(.caption)
                          }
                          Divider().padding(.vertical, 4)
                        }
                        
                        // ─── Main Sets ───────────────────────────────────────────────────
                        ForEach(exercise.setDetails) { set in
                            HStack {
                                Text("Set \(set.setNumber):")
                                    .fontWeight(.bold)
                                    .font(.caption)
                                
                                let txt: Text = {
                                    if exercise.usesWeight {
                                        return Text(smartFormat(set.weight))
                                          + Text(" lbs").fontWeight(.light)
                                          + Text(" x ").foregroundColor(.gray)
                                          + Text("\(set.reps)")
                                          + Text(" reps").fontWeight(.light)
                                    } else {
                                        return Text("\(set.reps)")
                                          + Text(" reps planned").fontWeight(.light)
                                    }
                                }()
                                txt.font(.caption)

                                RepsCompletedView(repsCompleted: set.repsCompleted, repsPlanned: set.reps)
                            }
                            
                            // Check for a PerformanceUpdate for this exercise at the specific set.
                            if let prUpdate = workout.updatedMax.first(where: {
                                $0.exerciseName == exercise.name && $0.setNumber == set.setNumber
                            }),
                            let prRepsWeight = prUpdate.repsXweight {
                                HStack {
                                    if exercise.usesWeight {
                                        Image(systemName: "trophy.fill")
                                        if prRepsWeight.reps == 1 {
                                            Text("\(smartFormat(prUpdate.value)) lbs")
                                        } else {
                                            Text("\(smartFormat(prRepsWeight.weight)) lbs x \(prRepsWeight.reps) reps") +
                                            Text(" = \(smartFormat(prUpdate.value)) lbs")
                                        }
                                    } else {
                                        Image(systemName: "trophy.fill")
                                        Text("\(smartFormat(prUpdate.value)) reps")
                                    }
                                }
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
            .padding()
            .navigationTitle("Workout Details").navigationBarTitleDisplayMode(.inline)
        }
    }
    
    struct RepsCompletedView: View {
        let repsCompleted: Int?
        let repsPlanned:   Int

        var body: some View {
            let done = repsCompleted ?? 0
            let color = color(for: done, planned: repsPlanned)

            // Compose two Texts: arrow+number normal, label italic
            ( Text("→ ")
              + Text("\(done) reps completed").italic()
            )
            .font(.caption)
            .foregroundColor(color)
        }

        private func color(for done: Int, planned: Int) -> Color {
            switch done {
                case planned: return .blue
                case ..<planned: return .red
                default: return .green
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short  // Display short time format (hour and minute)
        
        return formatter
    }
}
