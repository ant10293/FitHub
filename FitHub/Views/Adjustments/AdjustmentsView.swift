//
//  AdjustmentsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/9/25.
//
import SwiftUI
import UIKit

struct AdjustmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    
    @State private var showAddCategoryPicker = false
    @State private var donePressed: Bool = false
    @State private var local: ExerciseEquipmentAdjustments
    @State private var activeImageCategory: AdjustmentCategory? = nil
    @State private var categoryPendingRemoval: AdjustmentCategory? = nil
    
    let exercise: Exercise

    init(exercise: Exercise) {
        self.exercise = exercise
        _local = State(initialValue: ExerciseEquipmentAdjustments(id: exercise.id, equipmentAdjustments: [], sorted: true))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                headerSection
                adjustmentList(for: local.equipmentAdjustments)
                Spacer(minLength: 0)
            }
            .padding()
            .navigationBarTitle("Equipment Adjustments", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .sheet(isPresented: $showAddCategoryPicker) {
                AddCategoryPicker(
                    exercise: exercise,
                    existingCategories: existingCategories
                ) { category in
                    addAdjustmentCategory(category)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        donePressed = true
                        commitChangesIfNeeded()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: onAppear)
            .onDisappear(perform: commitIfDismissedWithoutClose)
            .sheet(item: $activeImageCategory) { category in
                UploadImage(initialFilename: local.adjustment(for: category)?.image) { filename in
                    let normalized = filename.isEmpty ? nil : filename
                    updateImage(for: category, filename: normalized)
                    activeImageCategory = nil
                }
                .presentationDragIndicator(.visible)
            }
            .alert("Remove custom image?", isPresented: removalAlertBinding) {
                Button("Cancel", role: .cancel) {
                    categoryPendingRemoval = nil
                }
                Button("Remove", role: .destructive) {
                    if let category = categoryPendingRemoval {
                        updateImage(for: category, filename: nil)
                    }
                    categoryPendingRemoval = nil
                }
            } message: {
                Text("This will revert to the default adjustment illustration.")
            }
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
    
    // MARK: – List
    private func adjustmentList(for adjustments: [EquipmentAdjustment]) -> some View {
        let sortedAdjustments = ExerciseEquipmentAdjustments.sorted(adjustments)
        
        return List {
            Section {
                if sortedAdjustments.isEmpty {
                    Text("No adjustments found for this exercise.")
                        .foregroundStyle(.red)
                } else {
                    ForEach(sortedAdjustments, id: \.category) { adjustment in
                        adjustmentRow(for: adjustment)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let categoryToDelete = sortedAdjustments[index].category
                            removeAdjustment(categoryToDelete)
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
    
    // MARK: – Row
    private func adjustmentRow(for adjustment: EquipmentAdjustment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(adjustment.category.rawValue)
                Spacer()
                
                TextField("Value", text: bindingForCategory(adjustment.category))
                    .keyboardType(adjustment.value.keyboardType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                
                Button {
                    clearValue(for: adjustment.category)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.borderless)
            }
            
            imagePreview(for: adjustment)
        }
    }
    
    private var existingCategories: Set<AdjustmentCategory> { local.categories }
    
    // MARK: – Bindings & Mutations
    private func bindingForCategory(_ category: AdjustmentCategory) -> Binding<String> {
        Binding(
            get: { local.textValue(for: category) },
            set: { local.setValue(AdjustmentValue.from($0), for: category) }
        )
    }
    
    private func addAdjustmentCategory(_ category: AdjustmentCategory) { local.addCategory(category) }
    
    private func removeAdjustment(_ category: AdjustmentCategory) { local.removeCategory(category) }
    
    private func clearValue(for category: AdjustmentCategory) { local.clearValue(for: category) }
    
    private func updateImage(for category: AdjustmentCategory, filename: String?) {
        local.setImage(filename, for: category)
    }
    
    // MARK: – Image Helpers
    private func imagePreview(for adjustment: EquipmentAdjustment) -> some View {
        let width = UIScreen.main.bounds.width
        
        return displayImage(for: adjustment)
            .resizable()
            .scaledToFit()
            .frame(width: width * 0.2)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.15))
            )
            .overlay(alignment: .topTrailing) {
                Button {
                    handleImageButtonTap(for: adjustment.category)
                } label: {
                    Image(systemName: adjustment.hasCustomImage ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(adjustment.hasCustomImage ? .red : .blue)
                }
            }
    }
    
    private func displayImage(for adjustment: EquipmentAdjustment) -> Image {
        if let name = adjustment.image, !name.isEmpty,
           let uiImage = UIImage(contentsOfFile: getDocumentsDirectory().appendingPathComponent(name).path) {
            return Image(uiImage: uiImage)
        }
        return Image(adjustment.category.image)
    }
    
    private func handleImageButtonTap(for category: AdjustmentCategory) {
        if local.adjustment(for: category)?.hasCustomImage == true {
            categoryPendingRemoval = category
        } else {
            activeImageCategory = category
        }
    }
    
    private var removalAlertBinding: Binding<Bool> {
        Binding(
            get: { categoryPendingRemoval != nil },
            set: { if !$0 { categoryPendingRemoval = nil } }
        )
    }
    
    // MARK: – Lifecycle
    private func onAppear() {
        ctx.adjustments.loadAdjustments(for: exercise, allEquipment: ctx.equipment.allEquipment)
        local = ctx.adjustments.adjustmentsEntry(for: exercise)
    }
    
    private func commitIfDismissedWithoutClose() {
        guard !donePressed else { return }
        commitChangesIfNeeded()
    }
    
    private func commitChangesIfNeeded() {
        let normalizedLocal = local.normalized()
        let original = ctx.adjustments.adjustmentsEntry(for: exercise)
        guard original != normalizedLocal else { return }
        
        ctx.adjustments.overwriteAdjustments(for: exercise, new: normalizedLocal)
    }
}

