//
//  ExerciseSetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// FIXME: CRITICAL ERRORS when moving exercises. It's because of TimeEntryField
// cannot allow set deletion if keyboard is open
// FIXME: 0.5 cannot be typed without later converting to 5, using 0.** causes issues with time speed conversion (sync issue?)

// MARK: - ExerciseSetDetail (SetMetric-aware)
struct ExerciseSetDetail: View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var template: WorkoutTemplate
    @Binding var exercise: Exercise
    @Binding var isShowingOptions: Bool

    @State private var showSupersetOptions: Bool = false
    @State private var tosInputKey: TimeOrSpeed.InputKey?
    
    let isCollapsed: Bool
    let keyboardVisible: Bool
    let hasEquipmentAdjustments: Bool
    let perform: (CallBackAction) -> Void
    let onSuperset: (String) -> Void
    
    // MARK: - Init
    init(
        template: Binding<WorkoutTemplate>,
        exercise: Binding<Exercise>,
        isShowingOptions: Binding<Bool>,
        isCollapsed: Bool,
        keyboardVisible: Bool,
        hasEquipmentAdjustments: Bool,
        perform: @escaping (CallBackAction) -> Void,
        onSuperSet: @escaping (String) -> Void
    ) {
        _template          = template
        _exercise          = exercise
        _isShowingOptions  = isShowingOptions
                
        let wrappedEx = exercise.wrappedValue
        _showSupersetOptions = State(initialValue: wrappedEx.isSupersettedWith != nil)
        
        if let set = wrappedEx.setDetails.first, let tos = set.planned.timeSpeed {
            _tosInputKey = State(initialValue: tos.showing)
        }
        
        self.isCollapsed = isCollapsed
        self.keyboardVisible = keyboardVisible
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
                AddDeleteButtons(
                    addSet: addSet,
                    deleteSet: deleteLastSet,
                    disableDelete: exercise.setDetails.isEmpty
                )
                equipmentAdjustments
            }
        }
        .disabled(isShowingOptions)
        .overlay(alignment: .topTrailing) { isShowingOptions ? exerciseDetailOptions : nil }
        .cardContainer(
            cornerRadius: 10,
            backgroundColor: colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
        )
        .padding(.horizontal, 2.5)
        .onChange(of: exercise.isSupersettedWith) { showSupersetOptions = (exercise.isSupersettedWith != nil) }
    }

    // MARK: - Set rows
    @ViewBuilder private var setDetails: some View {
        ForEach($exercise.setDetails) { $set in
            let setNumber = set.setNumber

            SetInputRow(
                setNumber: setNumber,
                exercise: exercise,
                load: set.load,
                metric: set.planned,
                loadField: {
                    SetLoadEditor(load: $set.load)
                        .textFieldStyle(.roundedBorder)
                },
                metricField: {
                    SetMetricEditor(
                        planned: $set.planned,
                        showing: $tosInputKey,
                        hideTOSMenu: setNumber != 1,
                        load: set.load
                    )
                    .textFieldStyle(.roundedBorder)
                }
            )
        }
        .onMove(perform: moveSet)
        //.onDelete(perform: deleteSetDetails)
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

            if !isCollapsed {
                Button(action: { showSupersetOptions.toggle() }) {
                    Image(systemName: showSupersetOptions ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

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
                .onTapGesture { isShowingOptions = false }
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
                }
                Spacer()
            }
        }
    }

    // MARK: - Equipment adjustments
    @ViewBuilder private var equipmentAdjustments: some View {
        if hasEquipmentAdjustments {
            LabelButton(
                title: "Equipment Adjustments",
                systemImage: "slider.horizontal.3",
                tint: .green,
                width: .fit,
                action: { perform(.viewAdjustments) }
            )
            .centerHorizontally()
            .padding(.top, -5)
        }
    }

    // MARK: - Mutations
    private func addSet() {
        perform(.addSet)
    }

    private func deleteLastSet() {
        guard !exercise.setDetails.isEmpty else { return }
        // Unfocus the text field first
        KeyboardManager.dismissKeyboard()
        perform(.deleteSet)
        if exercise.setDetails.isEmpty { tosInputKey = nil }
    }

    private func moveSet(from source: IndexSet, to destination: Int) {
        // Unfocus the text field first
        KeyboardManager.dismissKeyboard()
        exercise.setDetails.move(fromOffsets: source, toOffset: destination)
        perform(.saveTemplate)
    }
}
