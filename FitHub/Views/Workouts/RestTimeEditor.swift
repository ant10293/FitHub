//
//  RestTimeEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/4/25.
//

import SwiftUI


struct RestTimerEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercise: Exercise
    @State private var setType: RestTimerSetType = .working

    // New state variables for presenting and tracking the rest picker for a particular set.
    @State private var showingRestPicker: Bool = false
    @State private var currentRestSetIndex: Int? = nil
    
    @State private var pickerMinutes: Int = 0
    @State private var pickerSeconds: Int = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Rest Periods")
                    .font(.headline)
                
                Picker("Set Type", selection: $setType) {
                    ForEach(RestTimerSetType.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: setType) { oldValue, newValue in
                    if oldValue != newValue {
                        resetPicker()
                    }
                }
                
                List {
                    // For each set, display a row with a button that shows the formatted rest time.
                    if getSelectedSets().isEmpty {
                        Text(setType == .working ? "No working sets available." : "No warm-up sets available.")
                    } else {
                        ForEach(getSelectedSets().indices, id: \.self) { index in
                            HStack {
                                Text("Set \(index + 1)")
                                Spacer()
                                // Display the rest time in a button with a rounded rectangle border.
                                Button(action: {
                                    // Tapping this button opens the picker.
                                    currentRestSetIndex = index
                                    let rest = getSelectedSets()[index].restPeriod ?? 0
                                    pickerMinutes = rest / 60
                                    pickerSeconds = rest % 60
                                    showingRestPicker = true
                                }) {
                                    if showingRestPicker && currentRestSetIndex == index {
                                        Text(formatTimeShort(pickerTimeSeconds()))
                                            .frame(width: 80, height: 30)
                                            .background(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(Color(UIColor.secondarySystemBackground))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 5)
                                                            .stroke(Color.secondary, lineWidth: 1)
                                                    )
                                            )
                                    } else {
                                        Text(formatTimeShort(getSelectedSets()[index].restPeriod ?? 0))
                                            .frame(width: 80, height: 30)
                                            .background(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(Color(UIColor.secondarySystemBackground))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 5)
                                                            .stroke(Color.secondary, lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding()
                            .listRowSeparator(showingRestPicker && currentRestSetIndex == index ? .hidden : .visible)
                            if showingRestPicker && currentRestSetIndex == index {
                                VStack {
                                    Text("Adjust Rest Period for Set \(index + 1)")
                                        .font(.headline)
                                    
                                    HStack {
                                        RestPicker(minutes: $pickerMinutes, seconds: $pickerSeconds, frameWidth: 120)
                                            .padding(.trailing)
                                        
                                        Button(action: {
                                            guard let idx = currentRestSetIndex else { return }
                                            updateRestPeriod(for: idx, withMinutes: pickerMinutes, seconds: pickerSeconds)
                                            resetPicker()
                                        }) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
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
            .navigationTitle(exercise.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    private func pickerTimeSeconds() -> Int {
        return pickerMinutes * 60 + pickerSeconds
    }
    
    private func resetPicker() {
        showingRestPicker = false
        currentRestSetIndex = nil
    }
    
    /// Returns the currently selected array of sets.
    private func getSelectedSets() -> [SetDetail] {
        if setType == .warmUp {
            return exercise.warmUpDetails
        } else {
            return exercise.setDetails
        }
    }
    
    /// Updates the rest period for the set at the specified index with the given minutes and seconds.
    private func updateRestPeriod(for index: Int, withMinutes minutes: Int, seconds: Int) {
        let newRest = minutes * 60 + seconds
        var sets: [SetDetail]
        if setType == .warmUp {
            sets = exercise.warmUpDetails
        } else {
            sets = exercise.setDetails
        }
        sets[index].restPeriod = newRest
        if setType == .warmUp {
            exercise.warmUpDetails = sets
        } else {
            exercise.setDetails = sets
        }
    }
}
