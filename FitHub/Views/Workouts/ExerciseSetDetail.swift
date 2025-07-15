//
//  ExerciseSetDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct ExerciseSetDetail: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @Binding var template: WorkoutTemplate
    @Binding var exercise: Exercise
    @Binding var isCollapsed: Bool
    @Binding var isShowingOptions: Bool
    @Binding var replacedExercises: [String]
    @State private var weightInputs: [String]
    @State private var repInputs: [String]
    @State private var showSupersetOptions: Bool = false // Control superset picker visibility
    @State private var showReplaceAlert: Bool = false
    let roundingPref: RoundingPreference
    let setStruct: SetStructures
    let hasEquipmentAdjustments: Bool
    var perform: (CallBackAction) -> Void
    var onSuperset: (String) -> Void // uuid string or 'None'

    init(
        template: Binding<WorkoutTemplate>,
        exercise: Binding<Exercise>,
        isCollapsed: Binding<Bool>,
        isShowingOptions: Binding<Bool>,
        replacedExercises: Binding<[String]>,
        roundingPref: RoundingPreference,
        setStruct: SetStructures,
        hasEquipmentAdjustments: Bool,
        perform: @escaping (CallBackAction) -> Void,
        onSuperSet: @escaping (String) -> Void
    ) {
        _exercise = exercise
        _template = template
        _isCollapsed = isCollapsed
        _isShowingOptions = isShowingOptions
        _replacedExercises = replacedExercises
        _weightInputs = State(initialValue: exercise.wrappedValue.setDetails.map { $0.weight > 0 ? String(Format.smartFormat($0.weight)) : "" })
        _repInputs = State(initialValue: exercise.wrappedValue.setDetails.map { $0.reps > 0 ? String($0.reps) : "" })
        _showSupersetOptions = State(initialValue: exercise.wrappedValue.isSupersettedWith != nil)
        
        self.roundingPref = roundingPref
        self.setStruct = setStruct
        self.hasEquipmentAdjustments = hasEquipmentAdjustments
        self.perform = perform
        self.onSuperset = onSuperSet
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            exerciseToolbar
            
            // Conditionally show details if not collapsed
            if !isCollapsed {
                superSetOptions()
                setDetails()
                addDeleteButtons
                equipmentAdjustments()
            }
        }
        .disabled(isShowingOptions)
        .overlay(alignment: .topTrailing) { isShowingOptions ? exerciseDetailOptions() : nil }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .padding(.horizontal, 2.5)
        .onChange(of: exercise.setDetails) { reinitializeInputs() }
        .onChange(of: exercise.isSupersettedWith) {
            if exercise.isSupersettedWith != nil {
                showSupersetOptions = true
            } else {
                showSupersetOptions = false
            }
        }
        .alert(isPresented: $showReplaceAlert) {
            Alert(title: Text("Are you sure you want to replace this exercise?"), message: Text("This action can be undone via:\nEdit → Undo"),
                primaryButton: .destructive(Text("Replace"), action: { perform(.replaceExercise) }),
                secondaryButton: .cancel()
            )
        }
    }

    private var exerciseToolbar: some View {
        HStack {
            // Exercise Name + Info Button
            Button(action: { perform(.viewDetail) }) {
                HStack(spacing: 5) {
                    Text(exercise.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil) // allow multiple lines
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Image(systemName: "info.circle")
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Superset Toggle
            Button(action: { showSupersetOptions.toggle() }) {
                Image(systemName: showSupersetOptions ? "chevron.down" : "chevron.right")
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44) // keep minimum tap target
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()

            // Drag Handle
            Button(action: { isShowingOptions.toggle() }) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44) // keep minimum tap target
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private func superSetOptions() -> some View {
        if showSupersetOptions {
            Picker("Superset With", selection: Binding(
                get: {
                    // keep current ID only if it still refers to a valid partner
                    if let partnerID = exercise.isSupersettedWith,
                        template.exercises.contains(where: { $0.id.uuidString == partnerID && ($0.isSupersettedWith == nil || $0.isSupersettedWith == exercise.id.uuidString) }) {
                        return partnerID
                    }
                    return "None"  // fallback
                },
                set: { newID in
                    onSuperset(newID)                                                  // pass ID string
                }
            )) {
                Text("None").tag("None")

                // every other exercise that is either free or already linked to *this* one
                ForEach(template.exercises.filter { $0.id != exercise.id && ($0.isSupersettedWith == nil || $0.isSupersettedWith == exercise.id.uuidString) }, id: \.id) { ex in
                    Text(ex.name)              // display name …
                        .tag(ex.id.uuidString) // … but store the ID string
                }
            }
            .pickerStyle(.menu)
            .padding(.top, -15)
        }
    }

    
    private var addDeleteButtons: some View {
        HStack {
            Spacer()
            Button(action: { addSet() }) {
                Label(" Add Set ", systemImage: "plus")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            Button(action: { deleteLastSet() }) {
                Label("Delete Set", systemImage: "minus")
                    .foregroundColor(.red)
            }
            .tint(.red)
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding(.top)
    }
    
    @ViewBuilder
    private func setDetails() -> some View {
        ForEach($exercise.setDetails.indices, id: \.self) { index in
            HStack {
                Text("Set \(index + 1)")
                Spacer()
                
                // ───────── Weight ───────────────────────────────────────────────
                if exercise.type.usesWeight {
                    Text("lbs").bold()
                    
                    TextField("Weight", text: Binding<String>(
                        get: { weightInputs.indices.contains(index) ? weightInputs[index] : "" },
                        set: { newValue in
                            guard weightInputs.indices.contains(index) else { return }
                            let filtered = InputLimiter.filteredWeight(old:  weightInputs[index], new: newValue)
                            weightInputs[index] = filtered
                            exercise.setDetails[index].weight = Double(filtered) ?? 0
                        }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                }
                
                // ───────── Reps ─────────────────────────────────────────────────
                Text("Reps").bold()
                
                TextField("Reps", text: Binding<String>(
                    get: { repInputs.indices.contains(index) ? repInputs[index] : "" },
                    set: { newValue in
                        guard repInputs.indices.contains(index) else { return }
                        let filtered = InputLimiter.filteredReps(newValue)
                        repInputs[index] = filtered
                        exercise.setDetails[index].reps = Int(filtered) ?? 0
                    }
                ))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
            }
        }
        .onMove(perform: moveSet)
        .onDelete(perform: deleteSetDetails)
    }
    
    @ViewBuilder
    private func exerciseDetailOptions() -> some View {
        ZStack {
            // Full-screen background that catches taps.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { isShowingOptions = false } }
            
            // Container to position the overlay at top-trailing.
            VStack {
                HStack {
                    Spacer()  // Pushes content to the right.
                    ExerciseDetailOptions(
                        template: $template,
                        exercise: $exercise,
                        roundingPreference: roundingPref,
                        setStructure: setStruct,
                        onReplaceExercise: { showReplaceAlert = true },
                        onRemoveExercise: { perform(.removeExercise) },
                        onClose: { isShowingOptions = false },
                        onSave: { perform(.saveTemplate) }
                    )
                    .onTapGesture { } // Consume taps.
                    .transition(.slide)
                }
                Spacer() // Pushes content to the top.
            }
        }
    }
    
    @ViewBuilder
    private func equipmentAdjustments() -> some View {
        //if equipmentData.hasEquipmentAdjustments(for: exercise) {
        if hasEquipmentAdjustments {
            HStack {
                Spacer()
                Button(action: { perform(.viewAdjustments) }) {
                    Label("Equipment Adjustments", systemImage: "slider.horizontal.3")
                        .foregroundColor(.darkGreen)
                }
                .centerHorizontally()
                .buttonStyle(.bordered)
                .tint(.green)
                
                Spacer()
            }
            .padding(.top, -5)
        }
    }
    
    private func reinitializeInputs() { // Reinitialize weight and rep inputs based on the new exercise data
        weightInputs = exercise.setDetails.map { $0.weight > 0 ? String(Format.smartFormat($0.weight)) : "" }
        repInputs = exercise.setDetails.map { $0.reps > 0 ? String($0.reps) : "" }
    }
    
    private func addSet() {
        weightInputs.append("")
        repInputs.append("")
        perform(.addSet)
    }
    
    private func deleteLastSet() {
        guard !exercise.setDetails.isEmpty else { return }
        weightInputs.removeLast()
        repInputs.removeLast()
        perform(.deleteSet)
    }
    
    private func moveSet(from source: IndexSet, to destination: Int) {
        exercise.setDetails.move(fromOffsets: source, toOffset: destination)
        weightInputs.move(fromOffsets: source, toOffset: destination)
        repInputs.move(fromOffsets: source, toOffset: destination)
        perform(.saveTemplate)
    }
    
    private func deleteSetDetails(at offsets: IndexSet) {
        exercise.setDetails.remove(atOffsets: offsets)
        weightInputs.remove(atOffsets: offsets)
        repInputs.remove(atOffsets: offsets)
        perform(.saveTemplate)
    }
}



