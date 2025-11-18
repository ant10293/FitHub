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
    @State private var showingInstructionEditor: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showRestoreAlert: Bool = false
    @State private var equipmentRequired: [GymEquipment] = []
    @State private var draft: InitExercise
    let original: Exercise?

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
                instructions: ExerciseInstructions(steps: []),
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NameField(title: "Name", placeholder: "Exercise Name", text: $draft.name, error: nameError)
                        .disabled(isReadOnly)

                    AliasesField(aliases: $draft.aliases, readOnly: isReadOnly)
                    muscleField
                    equipmentSection
                              
                    if !equipmentRequired.isEmpty, ctx.equipment.hasEquipmentAdjustments(for: equipmentRequired) {
                        adjustmentsField
                    }
                    
                    instructionsSection
                              
                    if !isReadOnly {
                        ImageField(initialFilename: draft.image, onImageUpdate: { name in
                            draft.image = name
                        })
                    }
                    
                    difficultySection
                    classificationPickers
                }
                .padding(.bottom)
                                                
                if !kbd.isVisible {
                    RectangularButton(
                        title: isEditing ? "Save Changes" : "Create Exercise",
                        enabled: isInputValid,
                        bgColor: isInputValid ? .blue : .gray
                    ) {
                        exerciseCreated = true
                        draft.name = draft.name.trimmed
        
                        ctx.exercises.updateExercise(exercise)
                        
                        dismiss()
                    }
                    .padding(.vertical)
                    
                    if isEditing {
                        switch ctx.exercises.getExerciseLocation(exercise) {
                        case .user:
                            RectangularButton(title: "Delete Exercise", systemImage: "trash", bgColor: .red, action: {
                                showDeleteAlert = true
                            })
                        case .bundled:
                            RectangularButton(title: "Restore Exercise", systemImage: "arrow.2.circlepath", bgColor: .red, action: {
                                showRestoreAlert = true
                            })
                        case .none:
                            EmptyView()
                        }
                    } 
                }
            }
            .padding()
            .navigationBarTitle(isEditing ? "Edit Exercise" : "New Exercise", displayMode: .inline)
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
        .sheet(isPresented: $selectingEquipment) {
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
        .sheet(isPresented: $showingInstructionEditor) {
            ExInstructionsEditor(instructions: $draft.instructions)
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
        .alert("Restore bundled version?", isPresented: $showRestoreAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Restore", role: .destructive) {
                if let restored = ctx.exercises.restoreBundledExercise(exercise) {
                    draft = .init(from: restored)
                }
            }
        } message: {
            Text("This will discard your changes and reload the original exercise.")
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
        if let newResistance = determineType() { draft.resistance = newResistance }
    }
    
    // FIXME: the selection "any" is invalid and does not have an associated tag, this will give undefined results
    private func determineType() -> ResistanceType? {
        if equipmentRequired.contains(where: { EquipmentCategory.machineCats.contains($0.equCategory) }){
            return .machine
        } else if equipmentRequired.contains(where: { EquipmentCategory.freeWeightCats.contains($0.equCategory) }) {
            return .freeWeight
        } else if equipmentRequired.isEmpty || equipmentRequired.contains(where: { $0.equCategory == .benchesRacks }) {
            return .bodyweight
        } else if equipmentRequired.contains(where: { $0.equCategory == .resistanceBands }){
            return .banded
        } else {
            return nil
        }
    }
    
    // FIXME: doesnt accomodate others like per peg, etc
    private func determineWeightInstruction() -> WeightInstruction? {
        if let movement = draft.limbMovementType, movement != .bilateralDependent {
            if draft.equipmentRequired.contains("Dumbbells") {
                return .perDumbbell
            } else if equipmentRequired.contains(where: { $0.equCategory == .cableMachines }) {
                return .perStack
            } else if equipmentRequired.contains(where: { $0.equCategory == .platedMachines }) {
                return .perPeg
            }
        }
        return nil
    }
    
    private var muscleField: some View {
        FieldEditor(
            title: "Muscles Worked",
            valueText: draft.muscles.isEmpty
                ? "None"
                : draft.muscles
                    .map { "\($0.muscleWorked.rawValue) (\(Int($0.engagementPercentage))%)" }
                    .joined(separator: ", "),
            isEmpty: draft.muscles.isEmpty,
            isReadOnly: isReadOnly,
            buttonLabel: "Edit Muscles",
            onEdit: { showingMuscleEditor = true }
        )
    }

    private var equipmentSection: some View {
        FieldEditor(
            title: "Equipment Required",
            valueText: draft.equipmentRequired.isEmpty
                ? "None"
                : draft.equipmentRequired.joined(separator: ", "),
            isEmpty: draft.equipmentRequired.isEmpty,
            isReadOnly: isReadOnly,
            buttonLabel: "Select Equipment",
            onEdit: { selectingEquipment = true }
        )
    }

    private var instructionsSection: some View {
        let text = draft.instructions.formattedString(leadingNewline: true) ?? "None"
        return FieldEditor(
            title: "Instructions",
            valueText: text,
            isEmpty: draft.instructions.steps.isEmpty,
            isReadOnly: isReadOnly,
            buttonLabel: "Edit Instructions",
            onEdit: { showingInstructionEditor = true }
        )
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
                Group {
                    // Resistance Type (exclude .weighted)
                    MenuPickerRow(title: "Resistance Type", selection: $draft.resistance, showDivider: false) {
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
                }
                .disabled(isReadOnly)

                // Reps Instruction (Optional, conditional)
                if exercise.usesReps {
                    MenuPickerRow(title: "Reps Instruction", selection: $draft.repsInstruction) {
                        Text("None").tag(nil as RepsInstruction?)
                        ForEach(RepsInstruction.allCases, id: \.self) {
                            Text($0.rawValue).tag(Optional($0))
                        }
                    }
                }

                // Weight Instruction (Optional, conditional)
                if exercise.usesWeight {
                    MenuPickerRow(title: "Weight Instruction", selection: $draft.weightInstruction) {
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
