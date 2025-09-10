//
//  SubMuscleEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/9/25.
//

import SwiftUI


// MARK: – Sub-muscle picker / editor
struct SubMuscleEditor: View {
    let muscle: Muscle
    @Binding var subEng: [SubMuscleEngagement]

    // add-new state
    @State private var chosen: SubMuscles? = nil
    @State private var pct: Double = 0

    // inline-edit state
    @State private var editingIdx: Int? = nil          // row that’s showing a slider

    // ───── helpers
    private var usedPct: Double { subEng.reduce(0) { $0 + $1.engagementPercentage } }
    private var remaining: Double { max(0, 100 - usedPct) }
    private var available: [SubMuscles] {
        let taken = Set(subEng.map(\.submuscleWorked))
        return Muscle.getSubMuscles(for: muscle).filter { !taken.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sub-muscles").font(.headline)

            // ── Existing rows ─────────────────────────────
            if subEng.isEmpty {
                Text("None added").foregroundStyle(Color.secondary)
            } else {
                ForEach(subEng.indices, id: \.self) { idx in
                    let s = subEng[idx]

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("• \(s.submuscleWorked.rawValue)")
                            Spacer()
                            Text("\(Int(s.engagementPercentage)) %")
                                .font(.subheadline)
                            Button {
                                // toggle slider for this row
                                editingIdx = editingIdx == idx ? nil : idx
                            } label: {
                                Image(systemName: "ellipsis")
                                    .imageScale(.medium)
                                    .padding(.leading, 4)
                            }
                        }

                        // slider only if this row is “open”
                        if editingIdx == idx {
                            Slider(
                                value: Binding(
                                    get: { subEng[idx].engagementPercentage },
                                    set: { newVal in subEng[idx].engagementPercentage = newVal }
                                ),
                                in: 0...100,
                                step: 1
                            )
                        }
                    }
                }
                .onDelete { subEng.remove(atOffsets: $0) }
            }

            // ── Add-new picker row ───────────────────────
            if !available.isEmpty {
                HStack(spacing: 12) {
                    Picker("Add Sub-muscle", selection: $chosen) {
                        Text("Select").tag(nil as SubMuscles?)
                        ForEach(available, id: \.self) { s in
                            Text(s.rawValue).tag(Optional(s))
                        }
                    }
                    .onChange(of: chosen) { pct = remaining }

                    Spacer()

                    Button(action: add) {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .tint(.green)
                    .disabled(chosen == nil || pct == 0)
                    .opacity((chosen == nil || pct == 0) ? 0.4 : 1)
                }
            }

            // slider for *new* addition
            if chosen != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Engagement: \(Int(pct)) %")
                    Slider(value: $pct, in: 0...100, step: 1)
                }
            }

            // total warning
            let tot = subEng.reduce(0) { $0 + $1.engagementPercentage }
            if !subEng.isEmpty && tot != 100 {
                Text("⚠️ Sub-muscle total \(Int(tot)) % (needs 100 %).")
                    .foregroundStyle(.red)
            }
        }
    }

    // add-new action
    private func add() {
        guard let s = chosen, pct > 0 else { return }
        subEng.append(SubMuscleEngagement(submuscleWorked: s, engagementPercentage: pct))
        chosen = nil
        pct = 0
    }
}


