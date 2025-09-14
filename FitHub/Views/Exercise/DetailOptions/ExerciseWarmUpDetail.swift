//  ExerciseWarmUpDetail.swift

import SwiftUI


// MARK: - Row view-model (typed to SetMetric)
private struct WarmUpRowVM: Identifiable {
    let id = UUID()
    var setNumber: Int
    var weight: Mass
    var planned: SetMetric   // <-- reps(...) or hold(...)

    init(detail: SetDetail) {
        setNumber = detail.setNumber
        weight    = detail.weight
        planned   = detail.planned
    }
    func toDetail() -> SetDetail {
        SetDetail(setNumber: setNumber, weight: weight, planned: planned)
    }
}

// MARK: - Main editor
struct ExerciseWarmUpDetail: View {
    // 1) canonical model from parent
    @Binding var exercise: Exercise

    // 2) local editable buffer
    @State private var rows: [WarmUpRowVM]

    // 3) env / helpers
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    private let generator = WorkoutGenerator()
    private let onSave: () -> Void

    // 4) save-once flag
    @State private var didSave = false

    // ───────── init ─────────
    init(exercise: Binding<Exercise>, onSave: @escaping () -> Void) {
        _exercise = exercise
        _rows = State(initialValue: exercise.wrappedValue.warmUpDetails.map(WarmUpRowVM.init))
        self.onSave = onSave
    }

    // ───────── body ─────────
    var body: some View {
        NavigationStack {
            List {
                warmUpSection
                buttonSection
                workingSetSection
            }
            .listStyle(.plain)
            .navigationBarTitle(exercise.name, displayMode: .inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: saveAndDismiss)
            }}
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onDisappear(perform: saveIfNeeded)
        }
    }

    // MARK: Warm-up rows (editable)
    private var warmUpSection: some View {
        VStack(alignment: .leading) {
            Text("Warm-Up Sets")
                .font(.headline)
                .padding(.bottom)

            if rows.isEmpty {
                Text("No warm-up sets yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($rows) { $row in
                    // Weight ↔︎ String
                    let weightText: Binding<String> = $row.weight.asText()

                    // Metric ↔︎ String (reps or seconds depending on exercise)
                    let metricText: Binding<String> = Binding<String>(
                        get: {
                           // ✅ use your computed property for display text
                           SetDetail(setNumber: row.setNumber, weight: row.weight, planned: row.planned)
                               .metricFieldString
                        },
                        set: { newValue in
                            if exercise.effort.usesReps {
                                let value = Int(newValue) ?? 0
                                row.planned = .reps(value)
                            } else {
                               // keep exactly what user typed (no auto-convert to minutes)
                                let secs = TimeSpan.seconds(from: newValue)
                                row.planned = .hold(TimeSpan(seconds: secs))
                            }
                        }
                    )

                    SetInputRow(
                        setNumber: row.setNumber,
                        exercise : exercise,
                        weightText: weightText,
                        metricText: metricText
                    )
                    .padding(.horizontal)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listRowSeparator(.hidden)
        .padding(.top)
    }

    // MARK: Buttons (add / delete / autofill)
    private var buttonSection: some View {
        VStack {
           AddDeleteButtons(addSet: addRow, deleteLastSet: deleteRow)
            .listRowSeparator(.hidden)

            HStack {
                Spacer()
                Button(action: autofill) {
                    Label("Autofill", systemImage: "wand.and.stars").foregroundStyle(.green)
                }
                .buttonStyle(.bordered).tint(.green)
                Spacer()
            }
            .listRowSeparator(.hidden)
        }
    }

    // MARK: Working sets (read-only)
    private var workingSetSection: some View {
        VStack(alignment: .leading) {
            (Text("Working Sets ").font(.headline) +
             Text("(Read Only)").foregroundStyle(.secondary))
            .padding(.bottom)

            if exercise.setDetails.isEmpty {
                Text("No working sets available.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(exercise.setDetails.indices, id: \.self) { idx in
                    let sd = exercise.setDetails[idx]

                    SetInputRow(
                        setNumber: idx + 1,
                        exercise : exercise,
                        weightText: .constant(sd.weightFieldString),
                        metricText: .constant(sd.metricFieldString)
                    )
                    .opacity(0.7)
                    .padding(.horizontal)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .padding(.top)
        .listRowSeparator(.hidden)
    }

    // MARK: Row mutators
    private func addRow() {
        let next = rows.count + 1
        let defaultMetric: SetMetric = exercise.effort.usesReps ? .reps(0) : .hold(TimeSpan(seconds: 0))
        rows.append(.init(detail: SetDetail(setNumber: next, weight: Mass(kg: 0), planned: defaultMetric)))
    }

    private func deleteRow() { if !rows.isEmpty { rows.removeLast() } }

    private func autofill() {
        exercise.createWarmupDetails(
            equipmentData: ctx.equipment,
            userData: ctx.userData
        )
        rows = exercise.warmUpDetails.map(WarmUpRowVM.init)
    }

    // MARK: Save helpers
    private func save() {
        guard !didSave else { return }
        didSave = true
        exercise.warmUpDetails = rows.map { $0.toDetail() }
        onSave()
    }
    
    private func saveAndDismiss() { save(); dismiss() }
    
    private func saveIfNeeded() { save() }
}

