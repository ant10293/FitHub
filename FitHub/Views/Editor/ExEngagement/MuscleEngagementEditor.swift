import SwiftUI

// MARK: - Main editor
struct MuscleEngagementEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var muscleEngagements: [MuscleEngagement]

    // ────────── Editor state
    @State private var selectedMuscle: Muscle? = nil
    @State private var pct: Double = 0
    @State private var moverType: MoverType = .primary
    @State private var subEng: [SubMuscleEngagement] = []
    @State private var editingIndex: Int? = nil        // nil → adding

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
                                    .foregroundStyle(selectedMuscle == nil ? .secondary : .primary)
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
                            if editingIndex == nil { 
                                pct = remainingForNew 
                                subEng.removeAll()  // Only clear when adding new, not editing
                            }
                        }

                        // ── Detail controls ──────────────────────
                        if let muscle = selectedMuscle {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Engagement: \(Int(pct)) %")
                                    Slider(value: $pct, in: 0...100, step: 1)
                                    
                                    if pct <= 0 {
                                        ErrorFooter(message: "Engagement percentage must be greater than 0%.", showImage: true)
                                    }
                                }
                                
                                // ── Overall-total warning ──────────────────────
                                if !muscleEngagements.isEmpty && effectiveTotal != 100 {
                                    ErrorFooter(message: "Overall total is \(Int(effectiveTotal)) %. Must equal 100 %.", showImage: true)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Mover Type")
                                    Picker("Mover Type", selection: $moverType) {
                                        ForEach(MoverType.allCases, id: \.self) { moverType in
                                            Text(moverType.displayName).tag(moverType)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            
                            Divider()
                            
                            SubMuscleEditor(muscle: muscle, subEng: $subEng)
                        }

                        Divider()

                        // ── Current list ────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Added Muscles").font(.headline)
                            if muscleEngagements.isEmpty {
                                Text("None yet").foregroundStyle(Color.secondary)
                            } else {
                                ForEach(muscleEngagements.indices, id: \.self) { idx in
                                    let me = muscleEngagements[idx]
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(me.muscleWorked.rawValue) — \(Int(me.engagementPercentage)) % (\(me.mover.rawValue.capitalized))")
                                        if let subs = me.submusclesWorked, !subs.isEmpty {
                                            Text(subs.map { "\($0.submuscleWorked.rawValue) (\(Int($0.engagementPercentage)) %)" }
                                                    .joined(separator: ", "))
                                                .font(.subheadline)
                                        }
                                    }
                                    .padding(8)
                                    .roundedBackground(cornerRadius: 8, color: Color.secondary.opacity(0.08))
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
                RectangularButton(
                    title: editingIndex == nil ? "Add Muscle" : "Save Changes",
                    enabled: !invalidEngagement,
                    bgColor: .blue,
                    fontWeight: .semibold,
                    action: editingIndex == nil ? append : save
                )
                .padding()
            }
            .navigationBarTitle("Muscle Engagement", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private var invalidEngagement: Bool { pct <= 0 || selectedMuscle == nil || effectiveTotal > 100 }
    
    private var effectiveTotal: Double {
        if let idx = editingIndex {                     // editing existing
            return totalUsed                             // current saved total
                 - muscleEngagements[idx].engagementPercentage // subtract old value
                 + pct                                    // add slider value
        } else {                                        // adding new
            return totalUsed + pct
        }
    }

    // ────────── Helpers
    private var totalUsed: Double { muscleEngagements.reduce(0) { $0 + $1.engagementPercentage } }
    
    private var remainingForNew: Double {
        max(0, 100 - totalUsed + (editingIndex.map { muscleEngagements[$0].engagementPercentage } ?? 0))
    }

    private var availableMuscles: [Muscle] {
        // Exclude every muscle already in the list, except the one being edited.
        let taken = Set(
            muscleEngagements.enumerated().compactMap { i, me in
                (i == editingIndex) ? nil : me.muscleWorked
            }
        )
        return Muscle.allCases
            /*.filter(\.isVisible) */
            .filter { $0 != .all }
            .filter { !taken.contains($0) }
    }

    // ────────── CRUD helpers
    private func append() {
        guard let m = selectedMuscle else { return }
        muscleEngagements.append(
            MuscleEngagement(
                muscleWorked: m,
                engagementPercentage: pct,
                mover: moverType,
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
            mover: moverType,
            submusclesWorked: subEng.isEmpty ? nil : subEng
        )
        reset()
    }
    
    private func loadForEdit(_ idx: Int) {
        let me = muscleEngagements[idx]
        selectedMuscle = me.muscleWorked
        pct           = me.engagementPercentage
        moverType     = me.mover
        subEng        = me.submusclesWorked ?? []
        editingIndex  = idx
    }
    
    private func reset() {
        selectedMuscle = nil
        pct = 0
        moverType = .primary
        subEng = []
        editingIndex = nil
    }
}
