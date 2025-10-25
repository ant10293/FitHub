//  ExerciseWarmUpDetail.swift

import SwiftUI


// MARK: - Row view-model (typed to SetMetric)
private struct WarmUpRowVM: Identifiable {
    let id: UUID
    var setNumber: Int
    var load: SetLoad
    var planned: SetMetric   // <-- reps(...) or hold(...)

    init(detail: SetDetail) {
        id        = detail.id
        setNumber = detail.setNumber
        load      = detail.load
        planned   = detail.planned
    }
    
    func toDetail() -> SetDetail {
        SetDetail(
            id: id,
            setNumber: setNumber,
            load: load,
            planned: planned
        )
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
            // FIXME: list causes publishing issues without use of WarmUpRowVM
            List {
                warmUpSection
                buttonSection
                workingSetSection
            }
            .listStyle(.plain)
            .navigationBarTitle(exercise.name, displayMode: .inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Close", action: saveAndDismiss)
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
                    SetInputRow(
                        setNumber: row.setNumber,
                        exercise: exercise,
                        load: row.load,  // Use actual load from setDetails
                        metric: row.planned,
                        loadField: {
                            SetLoadEditor(load: $row.load)
                                .textFieldStyle(.roundedBorder)
                        },
                        metricField: {
                            // Warm-ups typically don’t track a separate “completed”.
                            // Mirror planned → completed locally so the editor behaves consistently.
                            SetMetricEditor(planned: $row.planned, load: row.load)
                                .textFieldStyle(.roundedBorder)
                        }
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
            AddDeleteButtons(addSet: addRow, deleteSet: deleteRow, disableDelete: exercise.warmUpDetails.isEmpty)
            .listRowSeparator(.hidden)

            LabelButton(
                title: "Autofill",
                systemImage: "wand.and.stars",
                tint: .green,
                action: autofill
            )
            .padding(.horizontal)
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
                ForEach(exercise.setDetails) { set in
                    SetInputRow(
                        setNumber: set.setNumber,
                        exercise: exercise,
                        load: set.load,
                        metric: set.planned,
                        loadField: {
                            TextField("", text: .constant(set.load.fieldString))
                                .multilineTextAlignment(.center)
                               .textFieldStyle(.roundedBorder)
                               .disabled(true)
                        },
                        metricField: {
                            TextField("", text: .constant(set.planned.fieldString))
                                .multilineTextAlignment(.center)
                               .textFieldStyle(.roundedBorder)
                               .disabled(true)
                        }
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
        kbd.dismiss()
        let next = rows.count + 1
        let defaultMetric: SetMetric = exercise.plannedMetric
        let defaultLoad: SetLoad = exercise.loadMetric
        rows.append(.init(detail: SetDetail(setNumber: next, load: defaultLoad, planned: defaultMetric)))
    }

    private func deleteRow() { if !rows.isEmpty { rows.removeLast() } }

    private func autofill() {
        kbd.dismiss()
        exercise.createWarmupDetails(equipmentData: ctx.equipment, userData: ctx.userData)
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
