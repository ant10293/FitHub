//
//  AdjustmentsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/3/24.
//
import SwiftUI

struct AdjustmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var showAddCategoryPicker = false
    @State private var donePressed: Bool = false

    // Local working copy (no disk writes while typing)
    @State private var local: ExerciseEquipmentAdjustments
    let exercise: Exercise
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _local = State(initialValue: ExerciseEquipmentAdjustments(id: exercise.id, equipmentAdjustments: [:], adjustmentImage: ""))
    }

    var body: some View {
        NavigationStack {
            VStack {
                headerSection
                adjustmentList(for: local)
                Spacer(minLength: 0)
            }
            .padding()
            .navigationBarTitle("Equipment Adjustments", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .sheet(isPresented: $showAddCategoryPicker) {
                AddCategoryPicker(
                    exercise: exercise,
                    existingCategories: Set(local.equipmentAdjustments.keys.map { $0 }),
                    onAddCategory: { category in
                        // Create with a sensible default; keep it local
                        if local.equipmentAdjustments[category] == nil {
                            local.equipmentAdjustments[category] = .string("")
                        }
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        commitIfChanged()
                        dismiss()
                        donePressed = true
                    }
                }
            }
            .onAppear(perform: onAppear)
            .onDisappear(perform: commitIfChanged)
        }
    }

    // MARK: – Header
    private var headerSection: some View {
        let imageSize = UIScreen.main.bounds.height * 0.14
        return HStack {
            Text(exercise.name.isEmpty ? "Unnamed\nExercise" : exercise.name)
                .font(.title2)
                .padding(.trailing, 8)
                .multilineTextAlignment(.center)

            exercise.fullImageView(favState: FavoriteState.getState(for: exercise, userData: ctx.userData))
                .frame(width: imageSize, height: imageSize)
        }
    }

    // MARK: - List
    private func adjustmentList(for exerciseAdjustment: ExerciseEquipmentAdjustments) -> some View {
        List {
            Section {
                if exerciseAdjustment.equipmentAdjustments.isEmpty {
                    Text("No adjustments found for this exercise.")
                        .foregroundStyle(.red)
                } else {
                    ForEach(exerciseAdjustment.equipmentAdjustments.keys.sorted(), id: \.self) { category in
                        adjustmentRow(for: category)
                    }
                    .onDelete { indexSet in
                        let sorted = exerciseAdjustment.equipmentAdjustments.keys.sorted()
                        for index in indexSet {
                            let categoryToDelete = sorted[index]
                            // Remove locally only; persist later on commit
                            local.equipmentAdjustments.removeValue(forKey: categoryToDelete)
                        }
                    }
                }
            } footer: {
                Button {
                    showAddCategoryPicker = true
                } label: {
                    Label("Add Adjustment", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row
    private func adjustmentRow(for category: AdjustmentCategory) -> some View {
        VStack {
            HStack {
                Text(category.rawValue)
                Spacer()

                TextField("Value", text: bindingForCategory(category))
                    .keyboardType(determineKeyboardType(for: local.equipmentAdjustments[category]))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                Button {
                    // Clear locally; keep the key but blank out value
                    local.equipmentAdjustments[category] = .string("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.borderless)
            }

            Image(category.image)
                .resizable()
                .scaledToFit()
                .frame(height: UIScreen.main.bounds.height * 0.1)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Bindings
    private func bindingForCategory(_ category: AdjustmentCategory) -> Binding<String> {
        Binding(
            get: {
                displayString(for: local.equipmentAdjustments[category])
            },
            set: { newString in
                // Parse into typed value, stored locally only
                local.equipmentAdjustments[category] = AdjustmentValue.from(newString)
            }
        )
    }

    private func displayString(for value: AdjustmentValue?) -> String {
        switch value {
        case .integer(let n): return String(n)
        case .string(let s):  return s
        case .none:           return ""
        }
    }

    private func determineKeyboardType(for value: AdjustmentValue?) -> UIKeyboardType {
        switch value {
        case .integer: return .numbersAndPunctuation
        case .string, .none: return .default
        }
    }
    
    private func onAppear() {
        if let initial = ctx.adjustments.adjustments[exercise.id] {
            local = initial
        }
    }

    // MARK: - Commit
    private func commitIfChanged() {
        if !donePressed {
            let original = ctx.adjustments.adjustments[exercise.id]
            ?? ExerciseEquipmentAdjustments(id: exercise.id, equipmentAdjustments: [:], adjustmentImage: "")
            
            if !modelsEqual(original, local) {
                // One write, one save
                ctx.adjustments.adjustments[exercise.id] = local
                ctx.adjustments.saveAdjustmentsToFile()
            }
        }
    }

    private func modelsEqual(_ a: ExerciseEquipmentAdjustments, _ b: ExerciseEquipmentAdjustments) -> Bool {
        a.id == b.id &&
        a.adjustmentImage == b.adjustmentImage &&
        a.equipmentAdjustments == b.equipmentAdjustments
    }
}
