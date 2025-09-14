//
//  ExerciseSetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


// MARK: - ExerciseSetDetail (SetMetric-aware)
struct ExerciseSetDetail: View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var template: WorkoutTemplate
    @Binding var exercise: Exercise
    @Binding var isCollapsed: Bool
    @Binding var isShowingOptions: Bool
    @Binding var replacedExercises: [String]

    @State private var showSupersetOptions = false
    @State private var showReplaceAlert = false

    @State private var weightTexts: [String]
    @State private var metricTexts: [String]   // holds reps OR time "mm:ss"/"ss"
    
    var hasEquipmentAdjustments: Bool
    var perform: (CallBackAction) -> Void
    var onSuperset: (String) -> Void

    // MARK: - Init
    init(
        template: Binding<WorkoutTemplate>,
        exercise: Binding<Exercise>,
        isCollapsed: Binding<Bool>,
        isShowingOptions: Binding<Bool>,
        replacedExercises: Binding<[String]>,
        hasEquipmentAdjustments: Bool,
        perform: @escaping (CallBackAction) -> Void,
        onSuperSet: @escaping (String) -> Void
    ) {
        _template          = template
        _exercise          = exercise
        _isCollapsed       = isCollapsed
        _isShowingOptions  = isShowingOptions
        _replacedExercises = replacedExercises

        _showSupersetOptions = State(initialValue: exercise.wrappedValue.isSupersettedWith != nil)

        // Seed buffers from current model
        let sets = exercise.wrappedValue.setDetails
        _weightTexts = State(initialValue: sets.map { $0.weightFieldString })
        _metricTexts = State(initialValue: sets.map { $0.metricFieldString })

        self.hasEquipmentAdjustments = hasEquipmentAdjustments
        self.perform = perform
        self.onSuperset = onSuperSet
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            exerciseToolbar

            if !isCollapsed {
                superSetOptions
                setDetails
                AddDeleteButtons(addSet: addSet, deleteLastSet: deleteLastSet)
                equipmentAdjustments
            }
        }
        .disabled(isShowingOptions)
        .overlay(alignment: .topTrailing) { isShowingOptions ? exerciseDetailOptions : nil }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .padding(.horizontal, 2.5)
        .onChange(of: exercise.setDetails) { resyncBuffersFromModel() }
        .onChange(of: exercise.isSupersettedWith) { showSupersetOptions = (exercise.isSupersettedWith != nil) }
        .alert(isPresented: $showReplaceAlert) {
            Alert(
                title: Text("Are you sure you want to replace this exercise?"),
                message: Text("This action can be undone via:\nEdit → Undo"),
                primaryButton: .destructive(Text("Replace"), action: { perform(.replaceExercise) }),
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Set rows
    @ViewBuilder private var setDetails: some View {
        ForEach(exercise.setDetails.indices, id: \.self) { index in
            // Weight text binding with buffer + commit to Mass when numeric
            let weightText: Binding<String> = Binding(
                get: { weightTexts[safe: index] ?? "" },
                set: { newText in
                    weightTexts[safeEdit: index] = newText
                    let val = Double(newText) ?? 0
                    exercise.setDetails[index].weight.set(val)   // commits in user’s selected unit
                }
            )

            // Reps/time text binding with buffer + commit to SetMetric
            let metricText: Binding<String> = Binding(
                get: { metricTexts[safe: index] ?? "" },
                set: { newText in
                    switch exercise.setDetails[index].planned {
                    case .reps:
                        metricTexts[safeEdit: index] = newText
                        let val = Int(newText) ?? 0
                        exercise.setDetails[index].planned = .reps(val)
                    case .hold:
                        let secs = TimeSpan.seconds(from: newText)
                        let ts = TimeSpan.init(seconds: secs)
                        exercise.setDetails[index].planned = .hold(ts)
                        metricTexts[safeEdit: index] = ts.displayStringCompact
                    }
                }
            )

            SetInputRow(
                setNumber: index + 1,
                exercise: exercise,
                weightText: weightText,
                metricText: metricText
            )
        }
        .onMove(perform: moveSet)
        .onDelete(perform: deleteSetDetails)
    }

    // MARK: - Top bar
    private var exerciseToolbar: some View {
        HStack {
            Button(action: { perform(.viewDetail) }) {
                HStack(spacing: 5) {
                    Text(exercise.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "info.circle")
                }
            }
            .buttonStyle(.plain)

            Button(action: { showSupersetOptions.toggle() }) {
                Image(systemName: showSupersetOptions ? "chevron.down" : "chevron.right")
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { isShowingOptions.toggle() }) {
                Image(systemName: "line.horizontal.3")
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 5)
    }

    // MARK: - Superset
    @ViewBuilder private var superSetOptions: some View {
        if showSupersetOptions {
            Picker("Superset With", selection: Binding(
                get: {
                    if let partnerID = exercise.isSupersettedWith,
                       template.exercises.contains(where: {
                           $0.id.uuidString == partnerID &&
                           ($0.isSupersettedWith == nil || $0.isSupersettedWith == exercise.id.uuidString)
                       }) {
                        return partnerID
                    }
                    return "None"
                },
                set: { onSuperset($0) }
            )) {
                Text("None").tag("None")
                ForEach(
                    template.exercises.filter {
                        $0.id != exercise.id &&
                        ($0.isSupersettedWith == nil || $0.isSupersettedWith == exercise.id.uuidString)
                    }, id: \.id
                ) { ex in
                    Text(ex.name).tag(ex.id.uuidString)
                }
            }
            .pickerStyle(.menu)
            .padding(.top, -15)
        }
    }

    // MARK: - Options overlay
    @ViewBuilder private var exerciseDetailOptions: some View {
        ZStack {
            Color.clear.contentShape(Rectangle())
                .onTapGesture { withAnimation { isShowingOptions = false } }
            VStack {
                HStack {
                    Spacer()
                    ExerciseDetailOptions(
                        template: $template,
                        exercise: $exercise,
                        onReplaceExercise: { showReplaceAlert = true },
                        onRemoveExercise: { perform(.removeExercise) },
                        onClose: { isShowingOptions = false },
                        onSave: { perform(.saveTemplate) }
                    )
                    .onTapGesture { }
                    .transition(.slide)
                }
                Spacer()
            }
        }
    }

    // MARK: - Equipment adjustments
    @ViewBuilder private var equipmentAdjustments: some View {
        if hasEquipmentAdjustments {
            HStack {
                Spacer()
                Button(action: { perform(.viewAdjustments) }) {
                    Label("Equipment Adjustments", systemImage: "slider.horizontal.3")
                        .foregroundStyle(.green)
                }
                .centerHorizontally()
                .buttonStyle(.bordered)
                .tint(.green)
                Spacer()
            }
            .padding(.top, -5)
        }
    }

    // MARK: - Mutations
    private func addSet() {
        perform(.addSet)
        // Extend buffers so indices stay aligned
        weightTexts.append("")
        metricTexts.append("")
    }

    private func deleteLastSet() {
        guard !exercise.setDetails.isEmpty else { return }
        perform(.deleteSet)
        _ = weightTexts.popLast()
        _ = metricTexts.popLast()
    }

    private func moveSet(from source: IndexSet, to destination: Int) {
        exercise.setDetails.move(fromOffsets: source, toOffset: destination)
        weightTexts.move(fromOffsets: source, toOffset: destination)
        metricTexts.move(fromOffsets: source, toOffset: destination)
        perform(.saveTemplate)
    }

    private func deleteSetDetails(at offsets: IndexSet) {
        exercise.setDetails.remove(atOffsets: offsets)
        weightTexts.remove(atOffsets: offsets)
        metricTexts.remove(atOffsets: offsets)
        perform(.saveTemplate)
    }

    private func resyncBuffersFromModel() {
        let sets = exercise.setDetails
        weightTexts = sets.map { $0.weightFieldString }
        metricTexts = sets.map { $0.metricFieldString }
    }
}
