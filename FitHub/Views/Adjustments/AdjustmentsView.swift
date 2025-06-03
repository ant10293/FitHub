//
//  AdjustmentsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/3/24.
//

import SwiftUI

struct AdjustmentsView: View {
    @EnvironmentObject var adjustmentsViewModel: AdjustmentsViewModel
    @ObservedObject var exerciseData: ExerciseData
    @EnvironmentObject var equipmentData: EquipmentData
    @State private var isKeyboardVisible = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddCategoryPicker = false
    var exercise: Exercise
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header
                headerSection
                
                // Adjustments List
                if let exerciseAdjustment = adjustmentsViewModel.adjustments[exercise.name] {
                    adjustmentList(for: exerciseAdjustment)
                } else {
                    noAdjustmentsText
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Equipment Adjustments")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear(perform: removeKeyboardObservers)
            .sheet(isPresented: $showAddCategoryPicker) {
                AddCategoryPicker(
                    exercise: exercise,
                    existingCategories: Set(adjustmentsViewModel.getEquipmentAdjustments(for: exercise)?.keys.map { $0 } ?? []),
                    onAddCategory: { category in
                        adjustmentsViewModel.addAdjustmentCategory(exercise, category: category)
                    }
                )
            }
            .toolbar {
                toolbarContent
            }
        }
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        HStack {
            Text(exercise.name)
                .font(.title2)
                .padding()
            Image(exercise.fullImagePath)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var noAdjustmentsText: some View {
        Text("No adjustments required for this exercise.")
            .font(.subheadline)
            .foregroundColor(.gray)
    }
    
    private func adjustmentList(for exerciseAdjustment: ExerciseEquipmentAdjustments) -> some View {
        List {
            ForEach(exerciseAdjustment.equipmentAdjustments.keys.sorted(), id: \.self) { category in
                adjustmentRow(for: category, in: exerciseAdjustment)
            }
            .onDelete { indexSet in
                handleDelete(indexSet, in: exerciseAdjustment)
            }
            // Row for adding a new category
            Button(action: {
                showAddCategoryPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Add Adjustment")
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func handleDelete(_ indexSet: IndexSet, in adjustment: ExerciseEquipmentAdjustments) {
        for index in indexSet {
            let categoryToDelete = adjustment.equipmentAdjustments.keys.sorted()[index]
            adjustmentsViewModel.deleteAdjustment(exercise: exercise, category: categoryToDelete)
        }
    }
    
    private func adjustmentRow(for category: AdjustmentCategories, in adjustment: ExerciseEquipmentAdjustments) -> some View {
        VStack {
            HStack {
                Text(category.rawValue)
                
                Spacer()
                
                // TextField for adjustment value
                TextField(
                    "Value",
                    text: bindingForCategory(category, in: adjustment)
                )
                .keyboardType(determineKeyboardType(for: adjustment.equipmentAdjustments[category]))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                
                // Clear button
                Button(action: {
                    adjustmentsViewModel.clearAdjustmentValue(exercise: exercise, for: category, in: adjustment)
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
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button(action: dismiss) {
                Text("Save").bold()
                    .frame(alignment: .trailing)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func bindingForCategory(_ category: AdjustmentCategories, in adjustment: ExerciseEquipmentAdjustments) -> Binding<String> {
        Binding(
            get: {
                adjustmentsViewModel.adjustmentInputs["\(adjustment.id)-\(category.rawValue)", default: ""]
            },
            set: { newValue in
                let adjustmentValue = AdjustmentValue.from(newValue)
                adjustmentsViewModel.updateAdjustmentValue(for: exercise.name, category: category, newValue: adjustmentValue)
            }
        )
    }
    
    private func determineKeyboardType(for adjustmentValue: AdjustmentValue?) -> UIKeyboardType {
        switch adjustmentValue {
        case .integer:
            return .numbersAndPunctuation
        case .string, .none:
            return .default
        }
    }
    
    private func dismiss() {
        adjustmentsViewModel.saveAdjustmentsToFile()
        presentationMode.wrappedValue.dismiss()
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
}




