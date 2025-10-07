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

    @State private var showSupersetOptions: Bool = false
    
    let hasEquipmentAdjustments: Bool
    let perform: (CallBackAction) -> Void
    let onSuperset: (String) -> Void

    
    // MARK: - Init
    init(
        template: Binding<WorkoutTemplate>,
        exercise: Binding<Exercise>,
        isCollapsed: Binding<Bool>,
        isShowingOptions: Binding<Bool>,
        hasEquipmentAdjustments: Bool,
        perform: @escaping (CallBackAction) -> Void,
        onSuperSet: @escaping (String) -> Void
    ) {
        _template          = template
        _exercise          = exercise
        _isCollapsed       = isCollapsed
        _isShowingOptions  = isShowingOptions
        _showSupersetOptions = State(initialValue: exercise.wrappedValue.isSupersettedWith != nil)

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
        .onChange(of: exercise.isSupersettedWith) { showSupersetOptions = (exercise.isSupersettedWith != nil) }
    }

    // MARK: - Set rows
    @ViewBuilder private var setDetails: some View {
        ForEach(exercise.setDetails.indices, id: \.self) { i in
            let setBinding = $exercise.setDetails[i]

            SetInputRow(
                setNumber: i + 1,
                exercise: exercise,
                load: exercise.setDetails[i].load,  
                metric: exercise.setDetails[i].planned,
                loadField: {
                    // Keep your chrome; just embed the editor
                    SetLoadEditor(load: setBinding.load)
                        .textFieldStyle(.roundedBorder)
                },
                metricField: {
                    SetMetricEditor(
                        planned: setBinding.planned,
                        load: exercise.setDetails[i].load
                    )
                    .textFieldStyle(.roundedBorder)
                }
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
                        onReplaceExercise: { perform(.replaceExercise) },
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
    }

    private func deleteLastSet() {
        guard !exercise.setDetails.isEmpty else { return }
        perform(.deleteSet)
    }

    private func moveSet(from source: IndexSet, to destination: Int) {
        exercise.setDetails.move(fromOffsets: source, toOffset: destination)
        perform(.saveTemplate)
    }

    private func deleteSetDetails(at offsets: IndexSet) {
        exercise.setDetails.remove(atOffsets: offsets)
        perform(.saveTemplate)
    }
}
