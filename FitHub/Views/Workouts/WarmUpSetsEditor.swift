//
//  WarmUpSetsEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/4/25.
//

import SwiftUI


struct WarmUpSetsEditorView: View {
    @EnvironmentObject var equipmentData: EquipmentData
    @Environment(\.dismiss) private var dismiss
    @Binding var exercise: Exercise
    @State private var weightInputs: [String] = []
    @State private var repInputs: [String] = []
    @State private var isKeyboardVisible: Bool = false
    @State private var changeMade: Bool = false
    var roundingPreference: [EquipmentCategory: Double]
    var setStructure: SetStructures = .pyramid

    init(exercise: Binding<Exercise>, weightInputs: [String] = [], repInputs: [String] = [], setStructure: SetStructures, roundingPreference: [EquipmentCategory: Double]) {
        _exercise = exercise
        _weightInputs = State(initialValue: exercise.wrappedValue.warmUpDetails.map { $0.weight > 0 ? ($0.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0.weight) : String($0.weight)) : "" })
        _repInputs = State(initialValue: exercise.wrappedValue.warmUpDetails.map { $0.reps > 0 ? String($0.reps) : "" })
        
        self.setStructure = setStructure
        self.roundingPreference = roundingPreference
    }
    
    var body: some View {
        NavigationView {
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
                                    if exercise.usesWeight {
                                        Text("lbs")
                                            .bold()
                                        TextField("Weight", text: Binding(
                                            get: {
                                                weightInputs.indices.contains(index) ? weightInputs[index] : ""
                                            },
                                            set: { newValue in
                                                if weightInputs.indices.contains(index) {
                                                    // keep only digits + dot
                                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                                    // allow up to 4 integer digits and up to 2 fractional digits
                                                    let pattern = #"^(\d{0,4})(\.\d{0,2})?$"#
                                                    guard filtered.range(of: pattern, options: .regularExpression) != nil else {
                                                        return    // reject this keystroke
                                                    }
                                                    // apply it
                                                    weightInputs[index] = filtered
                                                    // update model
                                                    if let w = Double(filtered) {
                                                        exercise.warmUpDetails[index].weight = w
                                                    } else if filtered.isEmpty {
                                                        exercise.warmUpDetails[index].weight = 0
                                                    }
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
                                        get: {
                                            repInputs.indices.contains(index) ? repInputs[index] : ""
                                        },
                                        set: { newValue in
                                            if repInputs.indices.contains(index) {
                                                let filtered = newValue.filter { "0123456789".contains($0) }
                                                let capped = String(filtered.prefix(3))
                                                repInputs[index] = capped              // UI text
                                                if let r = Int(filtered) {
                                                    exercise.warmUpDetails[index].reps = r
                                                } else if filtered.isEmpty {
                                                    exercise.warmUpDetails[index].reps = 0
                                                }
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
                        Button(action: autofillWarmUpSets) {
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
                                    if exercise.usesWeight {
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
            .onChange(of: exercise.warmUpDetails) {
                print("change")
                resetInputs()
            }
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear(perform: removeKeyboardObservers)
            .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .navigationTitle(exercise.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Warm-Up Set Functions
    private func addWarmUpSet() {
        weightInputs.append("")
        repInputs.append("")
        let newSetNumber = exercise.warmUpSets + 1
        exercise.warmUpDetails.append(SetDetail(setNumber: newSetNumber, weight: 0, reps: 0))
    }
    
    private func deleteLastWarmUpSet() {
        guard !exercise.warmUpDetails.isEmpty else { return }
        exercise.warmUpDetails.removeLast()
        guard !weightInputs.isEmpty, !repInputs.isEmpty else { return }
        weightInputs.removeLast()
        repInputs.removeLast()
    }
    
    /// Uses the first regular set as a baseline to generate auto-filled warm-up sets.
    private func addWarmUpSets() {
        guard let baselineSet = exercise.setDetails.first else { return }
        let warmUpSets = createWarmUpDetails(baselineSet: baselineSet)
        exercise.warmUpDetails = warmUpSets
    }
    
    /// Generates warm-up sets based on the chosen set structure.
    private func createWarmUpDetails(baselineSet: SetDetail) -> [SetDetail] {
        var warmUpDetails: [SetDetail] = []
        var totalWarmUpSets: Int = 0
        var weightReductionSteps: [Double] = []
        var repsIncreaseSteps: [Int] = []
        
        switch setStructure {
        case .pyramid:
            totalWarmUpSets = 2
            weightReductionSteps = [0.5, 0.65]
            repsIncreaseSteps = [12, 10]
        case .reversePyramid:
            totalWarmUpSets = 3
            weightReductionSteps = [0.5, 0.65, 0.8]
            repsIncreaseSteps = [10, 8, 6]
        default:
            totalWarmUpSets = 0
            weightReductionSteps = []
            repsIncreaseSteps = []
        }
        
        for i in 0..<totalWarmUpSets {
            let weight = baselineSet.weight * weightReductionSteps[i]
            let roundedWeight = equipmentData.roundWeight(weight, for: exercise.equipmentRequired, roundingPreference: roundingPreference)
            let reps = repsIncreaseSteps[i]
            warmUpDetails.append(SetDetail(setNumber: i + 1, weight: roundedWeight, reps: reps))
        }
        
        return warmUpDetails
    }
    
    private func resetInputs() {
        weightInputs = exercise.warmUpDetails.map { $0.weight > 0 ? ($0.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0.weight) : String($0.weight)) : "" }
        repInputs = exercise.warmUpDetails.map { $0.reps > 0 ? String($0.reps) : "" }
    }
    
    /// Auto-fills warm-up sets and updates the input arrays.
    private func autofillWarmUpSets() {
        guard let baseline = exercise.setDetails.first else { return }

        let details = createWarmUpDetails(baselineSet: baseline)       // uses roundWeight ✅

        exercise.warmUpDetails = details                               // commit last

       // exercise = exercise
    }
}
