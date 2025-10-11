//
//  NewExerciseView.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/3/25.
//

import SwiftUI


// TODO: certain vars must be reactive to other
// must modify to: determine if alias is the same name as an exercise or its alias then we should alert the user
// also, must create interface for adding muscle and submuscle engagement
// group category should be: arms, back, legs
// split category should not include those options ^
// if equipment is added, fill in the adjustments
struct NewExercise: View {
    // ────────── Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var ctx: AppContext
    
    // ────────── Local state
    @StateObject private var kbd = KeyboardManager.shared
    @State private var exerciseCreated: Bool = false
    @State private var selectingEquipment: Bool = false
    @State private var showingMuscleEditor: Bool = false
    @State private var showingAdjustmentsView: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var equipmentRequired: [GymEquipment] = []
    @State private var draft: InitExercise
    var original: Exercise? = nil

    init(original: Exercise? = nil) {
        self.original = original
        if let ex = original {
            _draft = State(initialValue: InitExercise(from: ex))   // you already have this init
        } else {
            _draft = State(initialValue: InitExercise(
                name: "",
                aliases: [],
                image: "",
                muscles: [],
                description: "",
                equipmentRequired: [],
                effort: .compound,
                resistance: .freeWeight,
                url: "",
                difficulty: .beginner
            ))
        }
    }
    
    // ────────── View
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        NameField(title: "Name", placeholder: "Exercise Name", text: $draft.name, error: nameError)
                        AliasesField(aliases: $draft.aliases, readOnly: isReadOnly)
                        muscleField
                        equipmentSection
                                  
                        if !equipmentRequired.isEmpty { adjustmentsField }
                                  
                        if !isReadOnly {
                            ImageField(initialFilename: draft.image, onImageUpdate: { name in
                                draft.image = name
                            })
                            
                            DescriptionField(text: $draft.description)
                        }
                        
                        difficultySection
                        classificationPickers
                    }
                    .padding()
                    .disabled(isReadOnly)
                    
                    if !kbd.isVisible && !isReadOnly {
                        RectangularButton(
                            title: isEditing ? "Save Changes" : "Create Exercise",
                            enabled: isInputValid,
                            bgColor: isInputValid ? .blue : .gray
                        ) {
                            exerciseCreated = true
                            draft.name = InputLimiter.trimmed(draft.name)
                            
                            if !isReadOnly {
                                if let orig = original {
                                    ctx.exercises.replace(orig, with: exercise)
                                } else {
                                    ctx.exercises.addExercise(exercise)
                                }
                            }
                            
                            dismiss()
                        }
                        .padding()
                        
                        if isEditing {
                            RectangularButton(title: "Delete Exercise", systemImage: "trash", bgColor: .red, action: {
                                showDeleteAlert = true
                            })
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                }
            }
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onDisappear(perform: disappearAction)
        .sheet(isPresented: $selectingEquipment, onDismiss: { draft.resistance = determineType() }) {
            EquipmentSelection(selection: equipmentRequired, onDone: { selection in
                setEquipment(selection: selection)
            })
        }
        .sheet(isPresented: $showingMuscleEditor) {
            MuscleEngagementEditor(muscleEngagements: $draft.muscles)
        }
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exercise: exercise)
        }
        .alert("Delete this exercise?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                ctx.exercises.removeExercise(exercise)
                dismiss()
            }
        } message: {
            Text("This action can’t be undone.")
        }
        .onChange(of: draft.limbMovementType) {
            if draft.weightInstruction == nil {
                draft.weightInstruction = determineWeightInstruction()
            }
        }
    }
    
    private var isEditing: Bool { original != nil }
    
    private var isReadOnly: Bool {
        if let ori = original { return !ctx.exercises.isUserExercise(ori) }
        return false
    }
    
    private func disappearAction() { if !exerciseCreated { ctx.adjustments.deleteAdjustments(for: exercise) } }
     
    private func setEquipment(selection: [GymEquipment]) {
        draft.equipmentRequired = selection.map(\.name)
        equipmentRequired = ctx.equipment.getEquipment(from: draft.equipmentRequired)
    }
    
    private func determineType() -> ResistanceType {
        if equipmentRequired.contains(where: { EquipmentCategory.machineCats.contains($0.equCategory) }){
            return .machine
        } else if equipmentRequired.contains(where: { EquipmentCategory.freeWeightCats.contains($0.equCategory) }) {
            return .freeWeight
        } else if equipmentRequired.isEmpty || equipmentRequired.contains(where: { $0.equCategory == .benchesRacks }) {
            return .bodyweight
        } else {
            return .any
        }
    }
    
    private func determineWeightInstruction() -> WeightInstruction? {
        if let movement = draft.limbMovementType, movement != .bilateralDependent {
            if draft.equipmentRequired.contains("Dumbbells") {
                return .perDumbbell
            } else if equipmentRequired.contains(where: { $0.equCategory == .cableMachines }) {
                return .perStack
            }
        }
        return nil
    }
    
    // ────────── Sub-views
    private var muscleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            (
                Text("Muscles Worked: ")
                    .font(.headline)
                +
                Text(
                    draft.muscles.isEmpty ? "None" :
                        draft.muscles.map { "\($0.muscleWorked.rawValue) (\(Int($0.engagementPercentage))%)" }.joined(separator: ", ")
                )
                .foregroundStyle(draft.muscles.isEmpty ? .secondary : .primary)
            )
            
            if !isReadOnly {
                Button {
                    showingMuscleEditor = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Edit Muscles")
                    }
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }
        }
    }
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            (
                Text("Equipment Required: ")
                    .font(.headline)
                +
                Text(draft.equipmentRequired.isEmpty ? "None" : draft.equipmentRequired.joined(separator: ", "))
                    .foregroundStyle(draft.equipmentRequired.isEmpty ? .secondary : .primary)
            )
            .multilineTextAlignment(.leading)
   
            if !isReadOnly {
                Button {
                    selectingEquipment = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Select Equipment")
                    }
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }
        }
    }
    
    private var adjustmentsField: some View {
        AdjustmentsSection(
            showingAdjustmentsView: $showingAdjustmentsView,
            showingPlateVisualizer: .constant(false),
            hidePlateVisualizer: true,
            exercise: exercise,
            titleFont: .headline,
            titleColor: .primary,
            bodyFont: .body,
            bodyColor: .blue
        )
    }
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Difficulty")
                .font(.headline)
            
            Picker("Difficulty", selection: $draft.difficulty) {
                ForEach(StrengthLevel.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: – Classification (inset-grouped look, no List)
    private var classificationPickers: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Classification")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Resistance Type (exclude .weighted)
                MenuPickerRow(title: "Resistance Type", selection: $draft.resistance) {
                    ForEach(ResistanceType.forExercises, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }

                // Effort Type
                MenuPickerRow(title: "Effort Type", selection: $draft.effort) {
                    ForEach(EffortType.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }

                // Limb Movement (Optional)
                MenuPickerRow(title: "Limb Movement", selection: $draft.limbMovementType) {
                    Text("None").tag(nil as LimbMovementType?)
                    ForEach(LimbMovementType.allCases, id: \.self) {
                        Text($0.rawValue).tag(Optional($0))
                    }
                }

                // Reps Instruction (Optional, conditional)
                if exercise.effort.usesReps {
                    MenuPickerRow(title: "Reps Instruction", selection: $draft.repsInstruction) {
                        Text("None").tag(nil as RepsInstruction?)
                        ForEach(RepsInstruction.allCases, id: \.self) {
                            Text($0.rawValue).tag(Optional($0))
                        }
                    }
                }

                // Weight Instruction (Optional, conditional)
                if exercise.usesWeight {
                    MenuPickerRow(title: "Weight Instruction", selection: $draft.weightInstruction, showDivider: false) {
                        Text("None").tag(nil as WeightInstruction?)
                        ForEach(WeightInstruction.allCases, id: \.self) {
                            Text($0.rawValue).tag(Optional($0))
                        }
                    }
                }
            }
            .roundedBackground(cornerRadius: 12, color: Color(UIColor.secondarySystemGroupedBackground), style: .continuous)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.secondary.opacity(0.15)))
            .padding(.top, 4)
        }
    }
    
    private var exercise: Exercise { Exercise(from: draft) }

    private var nameError: String? {
        guard !exerciseCreated else { return nil }
        if draft.name.isEmpty { return "Field is required." }
        if !InputLimiter.isValidInput(draft.name) { return "Invalid name (no symbols / leading spaces)." }
        if isDuplicateName { return "Name already exists." }
        return nil
    }
    
    private var isInputValid: Bool {
        !draft.name.isEmpty &&
        InputLimiter.isValidInput(draft.name) &&
        !isDuplicateName
    }
    
    private var isDuplicateName: Bool {
        ctx.exercises.allExercises.contains {
            $0.id != original?.id &&                       // ← ignore self
            $0.name.caseInsensitiveCompare(draft.name) == .orderedSame
        }
    }
}
