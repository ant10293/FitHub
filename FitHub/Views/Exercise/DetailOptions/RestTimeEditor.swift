//
//  RestTimeEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/4/25.
//

import SwiftUI


struct RestTimeEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var ctx: AppContext
    @Binding var exercise: Exercise
    @State private var setType: RestTimerSetType = .working
    @State private var showingRestPicker: Bool = false
    @State private var currentRestSetIndex: Int? = nil
    @State private var pickerTime: TimeSpan = .init(seconds: 0)
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Rest Periods")
                    .font(.headline)

                Picker("Set Type", selection: $setType) {
                    ForEach(RestTimerSetType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: setType) { oldValue, newValue in
                    if oldValue != newValue { resetPicker() }
                }

                ScrollView {
                    if selectedSets.isEmpty {
                        Text(setType == .working ? "No working sets available." : "No warm-up sets available.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .cardContainer()
                            .padding()
                    } else {
                        let width = calculateTextWidth(text: "00:00", minWidth: screenWidth * 0.2, maxWidth: screenWidth * 0.267)

                        ForEach(selectedSets.indices, id: \.self) { index in
                            VStack {
                                HStack {
                                    Text("Set \(index + 1)")
                                    Spacer()

                                    Button(action: { initializePicker(for: index) }) {
                                        let seconds = isActive(idx: index) ? pickerTime.inSeconds : effectiveRestSeconds(for: index)

                                        FieldChrome(width: width) {
                                            Text(Format.timeString(from: seconds))
                                        }
                                    }
                                }
                                .padding()

                                if isActive(idx: index) {
                                    Text("Adjust Rest Period for Set \(index + 1)")
                                        .font(.headline)

                                    MinSecPicker(time: $pickerTime)

                                    HStack {
                                        Spacer()
                                        FloatingButton(image: "checkmark") {
                                            guard let idx = currentRestSetIndex else { return }
                                            updateRestPeriod(for: idx, with: pickerTime)
                                            onSave()
                                            resetPicker()
                                        }
                                    }
                                }

                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationBarTitle(exercise.name, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func isActive(idx: Int) -> Bool {
        return showingRestPicker && currentRestSetIndex == idx
    }

    private func resetPicker() {
        showingRestPicker = false
        currentRestSetIndex = nil
    }

    private func initializePicker(for index: Int) {
        currentRestSetIndex = index
        let seconds = effectiveRestSeconds(for: index)   // ← uses resolver if nil
        pickerTime = .init(seconds: seconds)
        showingRestPicker = true
    }

    /// Returns the currently selected array of sets.
    private var selectedSets: [SetDetail] {
        setType == .warmUp ? exercise.warmUpDetails : exercise.setDetails
    }

    /// Read the per-set override if present; otherwise use your resolver.
    private func effectiveRestSeconds(for index: Int) -> Int {
        if let override = selectedSets[safe: index]?.restPeriod { return override }
        // Fallback: ask the exercise itself
        return exercise.getRestPeriod(
            isWarm: setType == .warmUp,
            rest: ctx.userData.workoutPrefs.customRestPeriods ?? ctx.userData.physical.goal.defaultRest
        )
    }

    /// Updates the rest period for the set at the specified index.
    private func updateRestPeriod(for index: Int, with time: TimeSpan) {
        let newRest = time.inSeconds
        switch setType {
        case .warmUp:
            var sets = exercise.warmUpDetails
            sets[safeEdit: index]?.restPeriod = newRest
            exercise.warmUpDetails = sets
        case .working:
            var sets = exercise.setDetails
            sets[safeEdit: index]?.restPeriod = newRest
            exercise.setDetails = sets
        }
    }
}
