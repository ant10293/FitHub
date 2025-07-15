//
//  AdjustmentsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/3/24.
//

import SwiftUI

struct AdjustmentsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var AdjustmentsData: AdjustmentsData
    @StateObject private var kbd = KeyboardManager.shared
    @State private var showAddCategoryPicker = false
    var exercise: Exercise
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header
                headerSection
                
                // Adjustments List
                adjustmentList(
                    for: AdjustmentsData.adjustments[exercise.id]
                    ?? ExerciseEquipmentAdjustments(id: exercise.id, equipmentAdjustments: [:], adjustmentImage: "")
                )
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Equipment Adjustments", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .sheet(isPresented: $showAddCategoryPicker) {
                AddCategoryPicker(
                    exercise: exercise,
                    existingCategories: Set(AdjustmentsData.getEquipmentAdjustments(for: exercise)?.keys.map { $0 } ?? []),
                    onAddCategory: { category in
                        AdjustmentsData.addAdjustmentCategory(exercise, category: category)
                    }
                )
            }
            .toolbar {
                toolbarContent
            }
        }
    }
    
    // MARK: – Header
    private var headerSection: some View {
        let imageSize = UIScreen.main.bounds.height * 0.14    // square side

        return HStack {
            Text(exercise.name.isEmpty ? "Unnamed\nExercise" : exercise.name)
                .font(.title2)
                .padding(.trailing, 8)
                .multilineTextAlignment(.center)

            // Try to load the exercise image; fall back to a placeholder
            exercise.fullImage
            .resizable()
            .scaledToFit()
            .frame(width: imageSize, height: imageSize)       // ← always square
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var noAdjustmentsText: some View {
        Text("No adjustments found for this exercise.")
            .foregroundStyle(.red)
    }
    
    // MARK: - Adjustment list with “Add” button as a section footer
    private func adjustmentList(for exerciseAdjustment: ExerciseEquipmentAdjustments) -> some View {
        List {
            Section {
                if exerciseAdjustment.equipmentAdjustments.isEmpty {
                    noAdjustmentsText
                } else {
                    ForEach(exerciseAdjustment.equipmentAdjustments.keys.sorted(), id: \.self) { category in
                        adjustmentRow(for: category, in: exerciseAdjustment)
                    }
                    .onDelete { indexSet in
                        handleDelete(indexSet, in: exerciseAdjustment)
                    }
                }
                
            } footer: {
                Button {
                    showAddCategoryPicker = true
                } label: {
                    Label("Add Adjustment", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)   // optional, looks good with a footer CTA
    }
    
    private func handleDelete(_ indexSet: IndexSet, in adjustment: ExerciseEquipmentAdjustments) {
        for index in indexSet {
            let categoryToDelete = adjustment.equipmentAdjustments.keys.sorted()[index]
            AdjustmentsData.deleteAdjustment(exercise: exercise, category: categoryToDelete)
        }
    }
    
    private func adjustmentRow(for category: AdjustmentCategory, in adjustment: ExerciseEquipmentAdjustments) -> some View {
        VStack {
            HStack {
                Text(category.rawValue)
                
                Spacer()
                
                // TextField for adjustment value
                TextField("Value", text: bindingForCategory(category, in: adjustment))
                    .keyboardType(determineKeyboardType(for: adjustment.equipmentAdjustments[category]))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                // Clear button
                Button(action: {
                    AdjustmentsData.clearAdjustmentValue(exercise: exercise, for: category, in: adjustment)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Adjustment image
            Image(category.image)
                .resizable()
                .scaledToFit()
                .frame(height: UIScreen.main.bounds.height * 0.1)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Done").bold()
                    .padding(.trailing)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func bindingForCategory(_ category: AdjustmentCategory, in adjustment: ExerciseEquipmentAdjustments) -> Binding<String> {
        Binding(
            get: {
                AdjustmentsData.adjustmentInputs["\(adjustment.id)-\(category.rawValue)", default: ""]
            },
            set: { newValue in
                let adjustmentValue = AdjustmentValue.from(newValue)
                AdjustmentsData.updateAdjustmentValue(for: exercise, category: category, newValue: adjustmentValue)
            }
        )
    }
    
    private func determineKeyboardType(for adjustmentValue: AdjustmentValue?) -> UIKeyboardType {
        switch adjustmentValue {
        case .integer: return .numbersAndPunctuation
        case .string, .none: return .default
        }
    }
}




