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
    var onSave: () -> Void

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

                List {
                    if selectedSets.isEmpty {
                        Text(setType == .working ? "No working sets available." : "No warm-up sets available.")
                    } else {
                        ForEach(selectedSets.indices, id: \.self) { index in
                            HStack {
                                Text("Set \(index + 1)")
                                Spacer()

                                Button(action: { initializePicker(for: index) }) {
                                    let seconds = isActive(idx: index) ? pickerTime.inSeconds : effectiveRestSeconds(for: index)
                                    Text(Format.timeString(from: seconds))
                                        .frame(width: 80, height: 30)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color(UIColor.secondarySystemBackground))
                                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary, lineWidth: 1))
                                        )
                                }
                            }
                            .padding()
                            .listRowSeparator(isActive(idx: index) ? .hidden : .visible)

                            if isActive(idx: index) {
                                VStack {
                                    Text("Adjust Rest Period for Set \(index + 1)")
                                        .font(.headline)

                                    HStack {
                                        MinSecPicker(time: $pickerTime)

                                        Button(action: {
                                            guard let idx = currentRestSetIndex else { return }
                                            updateRestPeriod(for: idx, with: pickerTime)
                                            onSave()
                                            resetPicker()
                                        }) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .padding()
                                        }
                                        .background(Circle().fill(Color.blue))
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .padding()
            .navigationBarTitle(exercise.name, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
        if let override = selectedSets[index].restPeriod { return override }
        // Fallback: ask the exercise itself
        let isWarm = (setType == .warmUp)
        return exercise.getRestPeriod(
            isWarm: isWarm,
            rest: ctx.userData.workoutPrefs.customRestPeriods ?? ctx.userData.physical.goal.defaultRest
        )
    }

    /// Updates the rest period for the set at the specified index.
    private func updateRestPeriod(for index: Int, with time: TimeSpan) {
        let newRest = time.inSeconds
        if setType == .warmUp {
            var sets = exercise.warmUpDetails
            sets[index].restPeriod = newRest
            exercise.warmUpDetails = sets
        } else {
            var sets = exercise.setDetails
            sets[index].restPeriod = newRest
            exercise.setDetails = sets
        }
    }
}
