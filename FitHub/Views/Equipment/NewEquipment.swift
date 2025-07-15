
//
//  NewExerciseView.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/3/25.
//

import SwiftUI

struct NewEquipment: View {
    // ────────── Environment
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var ctx: AppContext
    
    // ────────── Local state
    @StateObject private var kbd = KeyboardManager.shared
    @State private var equipmentCreated: Bool = false
    @State private var selectingEquipment: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var alternativeEquipment: [GymEquipment] = []
    @State private var draft: InitEquipment
    var original: GymEquipment? = nil
    
    init(original: GymEquipment? = nil) {
        self.original = original
        if let ori = original {
            _draft = State(initialValue: InitEquipment(from: ori))  
        } else {
            _draft = State(initialValue: InitEquipment(
                name: "",
                aliases: [],
                alternativeEquipment: [],
                image: "", 
                equCategory: .other,
                adjustments: [],
                description: ""
            ))
        }
    }
    
    // ────────── View
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        NameField(title: "Name", placeholder: "Equipment Name", text: $draft.name, error: nameError)
                        AliasesField(aliases: $draft.aliases, readOnly: isReadOnly)
                        alternativeSection
                        categoryPicker
                        
                        if draft.equCategory == .barsPlates || draft.equCategory == .weightMachines {
                            singlePegToggle
                        }
                        
                        AdjustmentPicker(adjustments: $draft.adjustments)
                        
                        if EquipmentCategory.baseWeightCats.contains(draft.equCategory) {
                            baseWeightField
                        }
                        
                        if !isReadOnly {
                            ImageField(initialFilename: draft.image, onImageUpdate: { name in
                                draft.image = name
                            })
                            
                            DescriptionField(text: $draft.description)
                        }
                    }
                    .padding()
                    .disabled(isReadOnly)
                    
                    if !kbd.isVisible && !isReadOnly {
                        ActionButton(
                            title: isEditing ? "Save Changes" : "Create Equipment",
                            enabled: isInputValid,
                            color: isInputValid ? .blue : .gray
                        ) {
                            equipmentCreated = true
                            draft.name = InputLimiter.trimmed(draft.name)
                            
                            if !isReadOnly {
                                if let orig = original {
                                    ctx.equipment.replace(orig, with: equipment)
                                } else {
                                    ctx.equipment.addEquipment(equipment)
                                }
                            }
                            
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        
                        if isEditing {
                            ActionButton(title: "Delete Equipment", systemImage: "trash", color: .red, action: {
                                showDeleteAlert = true
                            })
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Equipment" : "New Equipment").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .destructive) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .sheet(isPresented: $selectingEquipment, onDismiss: { selectingEquipment = false }) {
            EquipmentSelection(selection: alternativeEquipment, forNewExercise: true) { selection in
                setEquipment(selection: selection)
            }
        }
        .alert("Delete this equipment?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                ctx.equipment.removeEquipment(equipment)  // actual deletion
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("This action can’t be undone.")
        }
    }
    
    private var isEditing: Bool { original != nil }
    
    private var isReadOnly: Bool {
        if let ori = original { return !ctx.equipment.isUserEquipment(ori) }
        return false
    }
    
    private var equipment: GymEquipment { GymEquipment(from: draft) }
    
    // ────────── Sub-views ------------------------------------------------
    private var alternativeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            let alt = draft.alternativeEquipment ?? []  // Always show the label
            (
                Text("Alternative Equipment: ")
                    .font(.headline)
                +
                Text(alt.isEmpty ? "None" : alt.joined(separator: ", "))
                    .foregroundColor(alt.isEmpty ? .secondary : .primary)
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
                .foregroundColor(.blue)
                .buttonStyle(.plain)
            }
        }
    }
    
    private var categoryPicker: some View {
        HStack {
            Text("Category").font(.headline)
            
            Spacer()
            
            Picker("Category", selection: $draft.equCategory) {
                ForEach(EquipmentCategory.allCases.filter { $0 != .all }, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var baseWeightField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Base Weight (lbs)").font(.headline)
            
            TextField("Optional", text: Binding(
                get: { draft.baseWeight.map(String.init) ?? "" },
                set: { input in
                    draft.baseWeight = Int(input)          // nil if not a valid Int
                }
            ))
            .keyboardType(.numberPad)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .dark
                          ? .black.opacity(0.2)
                          : Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    private var singlePegToggle: some View {
        Toggle("Single-peg weight carriage",
               isOn: Binding(
                   get: { draft.singlePeg ?? false },
                   set: { draft.singlePeg = $0 }
               ))
            .toggleStyle(.switch)
    }
    
    private var isDuplicateName: Bool {
        ctx.equipment.allEquipment.contains {
            $0.id != original?.id &&                       // ← ignore self
            $0.name.caseInsensitiveCompare(draft.name) == .orderedSame
        }
    }
    
    private var nameError: String? {
        guard !equipmentCreated else { return nil }
        if draft.name.isEmpty { return "Field is required." }
        if !InputLimiter.isValidInput(draft.name) { return "Invalid characters." }
        if isDuplicateName { return "Name already exists." }
        return nil
    }
    
    private var isInputValid: Bool {
        !draft.name.isEmpty &&
        InputLimiter.isValidInput(draft.name) &&
        !isDuplicateName
    }
    
    private func setEquipment(selection: [GymEquipment]) {
        draft.alternativeEquipment = selection.map(\.name)
        alternativeEquipment = ctx.equipment.getEquipment(from: draft.alternativeEquipment ?? [])
    }
}
