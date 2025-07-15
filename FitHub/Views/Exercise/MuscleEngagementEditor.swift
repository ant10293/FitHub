import SwiftUI

// MARK: - Main editor
struct MuscleEngagementEditor: View {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var muscleEngagements: [MuscleEngagement]

    // ────────── Editor state
    @State private var selectedMuscle: Muscle? = nil
    @State private var pct: Double = 0
    @State private var isPrimary: Bool = false
    @State private var subEng: [SubMuscleEngagement] = []
    @State private var editingIndex: Int? = nil        // nil → adding

    // ────────── Helpers
    private var totalUsed: Double {
        muscleEngagements.reduce(0) { $0 + $1.engagementPercentage }
    }
    private var remainingForNew: Double {
        max(0, 100 - totalUsed + (editingIndex.map { muscleEngagements[$0].engagementPercentage } ?? 0))
    }
    private var availableMuscles: [Muscle] {
        let taken = Set(muscleEngagements.map(\.muscleWorked))
        return Muscle.allCases.filter(\.isVisible).filter { m in
            editingIndex.map { m == muscleEngagements[$0].muscleWorked } ?? true || !taken.contains(m)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Picker row ────────────────────────────
                        HStack {
                            Text("Muscle Worked")
                            Spacer(minLength: 8)
                            Picker(
                                selection: $selectedMuscle,
                                label: Text(selectedMuscle?.rawValue ?? "Select")
                                    .foregroundColor(selectedMuscle == nil ? .secondary : .primary)
                            ) {
                                Text("Select").tag(nil as Muscle?)
                                ForEach(availableMuscles, id: \.self) { m in
                                    Text(m.rawValue).tag(Optional(m))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.top)      // keeps it clear of nav bar
                        .onChange(of: selectedMuscle) {
                            if editingIndex == nil { pct = remainingForNew }
                            subEng.removeAll()
                        }

                        // ── Detail controls ──────────────────────
                        if let muscle = selectedMuscle {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Engagement: \(Int(pct)) %")
                                    Slider(value: $pct, in: 0...100, step: 1)
                                }
                                
                                let effectiveTotal: Double = {
                                    if let idx = editingIndex {                     // editing existing
                                        return totalUsed                             // current saved total
                                             - muscleEngagements[idx].engagementPercentage // subtract old value
                                             + pct                                    // add slider value
                                    } else {                                        // adding new
                                        return totalUsed + pct
                                    }
                                }()
                                
                                // ── Overall-total warning  (only when nothing selected) ─────
                                if !muscleEngagements.isEmpty && effectiveTotal != 100 {
                                    Text("⚠️ Overall total is \(Int(effectiveTotal)) %. Must equal 100 %.")
                                        .foregroundColor(.red)
                                }
                                
                                Toggle("Primary Mover", isOn: $isPrimary)
                            }
                            
                            Divider()
                            
                            SubMusclePicker(muscle: muscle, subEng: $subEng)
                        }

                        Divider()

                        // ── Current list ────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Added Muscles").font(.headline)
                            if muscleEngagements.isEmpty {
                                Text("None yet").foregroundColor(.secondary)
                            } else {
                                ForEach(muscleEngagements.indices, id: \.self) { idx in
                                    let me = muscleEngagements[idx]
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(me.muscleWorked.rawValue) — \(Int(me.engagementPercentage)) % \(me.isPrimary ? "(Primary)" : "")")
                                        if let subs = me.submusclesWorked, !subs.isEmpty {
                                            Text(subs.map { "\($0.submuscleWorked.rawValue) (\(Int($0.engagementPercentage)) %)" }
                                                    .joined(separator: ", "))
                                                .font(.subheadline)
                                        }
                                    }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                                    .contentShape(Rectangle())
                                    .onTapGesture { loadForEdit(idx) }
                                }
                                .onDelete { muscleEngagements.remove(atOffsets: $0) }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // ── Add / Save button pinned bottom ───────────
                Button(action: editingIndex == nil ? append : save) {
                    Text(editingIndex == nil ? "Add Muscle" : "Save Changes")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(selectedMuscle == nil ? Color.gray : Color.blue))
                        .foregroundColor(.white)
                }
                .disabled(selectedMuscle == nil)
                .padding()
            }
            .navigationTitle("Muscle Engagement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }
                    .foregroundStyle(.red)
            }}
        }
    }

    // ────────── CRUD helpers
    private func append() {
        guard let m = selectedMuscle else { return }
        muscleEngagements.append(
            MuscleEngagement(
                muscleWorked: m,
                engagementPercentage: pct,
                isPrimary: isPrimary,
                submusclesWorked: subEng.isEmpty ? nil : subEng
            )
        )
        reset()
    }
    
    private func save() {
        guard let idx = editingIndex, let m = selectedMuscle else { return }
        muscleEngagements[idx] = MuscleEngagement(
            muscleWorked: m,
            engagementPercentage: pct,
            isPrimary: isPrimary,
            submusclesWorked: subEng.isEmpty ? nil : subEng
        )
        reset()
    }
    
    private func loadForEdit(_ idx: Int) {
        let me = muscleEngagements[idx]
        selectedMuscle = me.muscleWorked
        pct           = me.engagementPercentage
        isPrimary     = me.isPrimary
        subEng        = me.submusclesWorked ?? []
        editingIndex  = idx
    }
    
    private func reset() {
        selectedMuscle = nil
        pct = 0
        isPrimary = false
        subEng = []
        editingIndex = nil
    }
}

// MARK: – Sub-muscle picker / editor
private struct SubMusclePicker: View {
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
                Text("None added").foregroundColor(.secondary)
            } else {
                ForEach(subEng.indices, id: \.self) { idx in
                    let s = subEng[idx]

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(s.submuscleWorked.rawValue)
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
                    .foregroundColor(.red)
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


