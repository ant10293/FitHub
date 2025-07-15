//
//  WarmUpSetsEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/4/25.
//

import SwiftUI


struct WarmUpSetsEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @Binding var exercise: Exercise
    @StateObject private var kbd = KeyboardManager.shared
    @State private var weightInputs: [String] = []
    @State private var repInputs: [String] = []
    @State private var changeMade: Bool = false
    var setStructure: SetStructures = .pyramid
    let roundingPreference: RoundingPreference
    var onSave: () -> Void
    private let generator = WorkoutGenerator()

    init(exercise: Binding<Exercise>, setStructure: SetStructures, roundingPreference: RoundingPreference, onSave: @escaping () -> Void) {
        _exercise = exercise
        _weightInputs = State(initialValue: exercise.wrappedValue.warmUpDetails.map { $0.weight > 0 ? Format.smartFormat($0.weight) : "" })
        _repInputs = State(initialValue: exercise.wrappedValue.warmUpDetails.map { $0.reps > 0 ? String($0.reps) : "" })
        
        self.setStructure = setStructure
        self.roundingPreference = roundingPreference
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // List for warm-up sets (editable)
                List {
                    VStack(alignment: .leading) {
                        Text("Warm-Up Sets")
                            .font(.headline)
                        
                        if !exercise.warmUpDetails.isEmpty {
                            ForEach(exercise.warmUpDetails.indices, id: \.self) { index in
                                HStack {
                                    Text("Set \(index + 1)")
                                    Spacer()
                                    if exercise.type.usesWeight {
                                        Text("lbs")
                                            .bold()
                                        TextField("Weight", text: Binding(
                                            get: { weightInputs.indices.contains(index) ? weightInputs[index] : "" },
                                            set: { newValue in
                                                if weightInputs.indices.contains(index) {
                                                    guard weightInputs.indices.contains(index) else { return }
                                                    let filtered = InputLimiter.filteredWeight(old:  weightInputs[index], new: newValue)
                                                    weightInputs[index] = filtered
                                                    exercise.warmUpDetails[index].weight = Double(filtered) ?? 0
                                                }
                                            }
                                        ))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    }
                                    Text("Reps")
                                        .bold()
                                    TextField("Reps", text: Binding(
                                        get: { repInputs.indices.contains(index) ? repInputs[index] : "" },
                                        set: { newValue in
                                            if repInputs.indices.contains(index) {
                                                guard repInputs.indices.contains(index) else { return }
                                                let filtered = InputLimiter.filteredReps(newValue)
                                                repInputs[index] = filtered
                                                exercise.warmUpDetails[index].reps = Int(filtered) ?? 0
                                            }
                                        }
                                    ))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                }
                                // In the list row
                                .listRowSeparator(.hidden)
                                .padding(.horizontal)
                            }
                        } else {
                            Text("No warm-up sets yet.")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .listRowSeparator(.hidden)

                    // Buttons for editing warm-up sets.
                    HStack {
                        Spacer()
                        Button(action: addWarmUpSet) {
                            Label("Add Set", systemImage: "plus")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        Button(action: deleteLastWarmUpSet) {
                            Label("Delete Set", systemImage: "minus")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        Spacer()
                    }
                    .padding(.top)
                    .listRowSeparator(.hidden)
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            generator.autofillWarmUpSets(equipmentData: ctx.equipment, for: &exercise, setStructure: setStructure, roundingPref: roundingPreference)
                            onSave()
                        }
                        ) {
                            Label("Autofill", systemImage: "wand.and.stars")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    
                    // Read-only Working Sets Section
                    VStack(alignment: .leading) {
                        Text("Working Sets")
                            .font(.headline)
                        
                        if !exercise.setDetails.isEmpty {
                            ForEach(exercise.setDetails.indices, id: \.self) { index in
                                HStack {
                                    Text("Set \(index + 1)")
                                    Spacer()
                                    if exercise.type.usesWeight {
                                        Text("lbs")
                                            .bold()
                                        // Display the working set weight using a rounded rectangle background similar to textfields.
                                        Text(String(format: "%.0f", exercise.setDetails[index].weight))
                                            .frame(width: 80, height: 30)
                                            .background(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary))
                                            .multilineTextAlignment(.center)
                                    }
                                    Text("Reps")
                                        .bold()
                                    Text(String(exercise.setDetails[index].reps))
                                        .frame(width: 80, height: 30)
                                        .background(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal)
                                .listRowSeparator(.hidden)
                            }
                        } else {
                            Text("No working sets available.")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
            }
            .onChange(of: exercise.warmUpDetails) { resetInputs() }
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationBarTitle(exercise.name, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Warm-Up Set Functions
    private func addWarmUpSet() {
        weightInputs.append("")
        repInputs.append("")
        let newSetNumber = exercise.warmUpSets + 1
        exercise.warmUpDetails.append(SetDetail(setNumber: newSetNumber, weight: 0, reps: 0))
        onSave()
    }
    
    private func deleteLastWarmUpSet() {
        guard !exercise.warmUpDetails.isEmpty else { return }
        exercise.warmUpDetails.removeLast()
        guard !weightInputs.isEmpty, !repInputs.isEmpty else { return }
        weightInputs.removeLast()
        repInputs.removeLast()
        onSave()
    }
    
    /// Uses the first regular set as a baseline to generate auto-filled warm-up sets.
    private func addWarmUpSets() {
        guard let baselineSet = exercise.setDetails.first else { return }
        let warmUpSets = generator.createWarmUpDetails(equipmentData: ctx.equipment, for: exercise, baselineSet: baselineSet, setStructure: setStructure, roundingPref: roundingPreference)
        exercise.warmUpDetails = warmUpSets
        onSave()
    }
    
    private func resetInputs() {
        weightInputs = exercise.warmUpDetails.map { $0.weight > 0 ? Format.smartFormat($0.weight) : "" }
        repInputs = exercise.warmUpDetails.map { $0.reps > 0 ? String($0.reps) : "" }
    }
}

