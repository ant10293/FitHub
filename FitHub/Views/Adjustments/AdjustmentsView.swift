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
    @State private var local: ExerciseAdjustments
    @State private var activeImageCategory: AdjustmentCategory? = nil
    @State private var categoryPendingRemoval: AdjustmentCategory? = nil
    @State private var isRemovingEquipmentLevelImage: Bool = false
    
    let exercise: Exercise

    init(exercise: Exercise) {
        self.exercise = exercise
        _local = State(initialValue: ExerciseAdjustments(id: exercise.id, entries: [], sorted: true))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                headerSection
                adjustmentList(for: local.entries)
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
                // Show the currently resolved image as initial filename (if it's a custom one)
                let entry = local.adjustment(for: category)
                let resolvedImageName = entry.flatMap { ctx.adjustments.resolvedImage(for: $0) }
                let initialFilename = (resolvedImageName != category.image && resolvedImageName != nil) ? resolvedImageName : entry?.image
                
                // Check if there's an existing equipment-level image (even if this exercise is ignoring it)
                let hasExistingEquipmentImage = entry.flatMap { 
                    ctx.adjustments.hasEquipmentLevelImage(for: $0.equipmentID, category: category)
                } ?? false
                
                AdjustmentImageUpload(
                    initialFilename: initialFilename,
                    hasExistingEquipmentImage: hasExistingEquipmentImage
                ) { filename, storageLevel in
                    let normalized = filename.isEmpty ? nil : filename
                    updateImage(for: category, filename: normalized, storageLevel: storageLevel)
                    activeImageCategory = nil
                }
                .presentationDragIndicator(.visible)
            }
            .alert("Remove custom image?", isPresented: removalAlertBinding) {
                Button("Cancel", role: .cancel) {
                    categoryPendingRemoval = nil
                    isRemovingEquipmentLevelImage = false
                }
                if isRemovingEquipmentLevelImage {
                    // Equipment-level image exists - show both options
                    Button("Remove for Exercise", role: .destructive) {
                        if let category = categoryPendingRemoval {
                            // Remove exercise override (if exists), keep equipment-level
                            updateImage(for: category, filename: nil, storageLevel: .exercise)
                        }
                        categoryPendingRemoval = nil
                        isRemovingEquipmentLevelImage = false
                    }
                    Button("Remove for Equipment", role: .destructive) {
                        if let category = categoryPendingRemoval {
                            // Remove equipment-level image (affects all exercises)
                            updateImage(for: category, filename: nil, storageLevel: .equipment)
                        }
                        categoryPendingRemoval = nil
                        isRemovingEquipmentLevelImage = false
                    }
                } else {
                    // Only exercise-specific override exists
                    Button("Remove", role: .destructive) {
                        if let category = categoryPendingRemoval {
                            updateImage(for: category, filename: nil, storageLevel: .exercise)
                        }
                        categoryPendingRemoval = nil
                        isRemovingEquipmentLevelImage = false
                    }
                }
            } message: {
                if isRemovingEquipmentLevelImage {
                    Text("Choose whether to remove the exercise-specific override or the equipment-level image (affects all exercises).")
                } else {
                    Text("This will remove the exercise-specific image and revert to the default illustration.")
                }
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
    private func adjustmentList(for adjustments: [AdjustmentEntry]) -> some View {
        let sortedAdjustments = ExerciseAdjustments.sorted(adjustments)
        
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
    private func adjustmentRow(for adjustment: AdjustmentEntry) -> some View {
        let fieldSize = UIScreen.main.bounds.width * 0.2

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(adjustment.category.rawValue)
                
                Spacer()
                
                TextField("Value", text: bindingForCategory(adjustment.category))
                    .keyboardType(adjustment.value.keyboardType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: fieldSize)
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
    
    private func updateImage(for category: AdjustmentCategory, filename: String?, storageLevel: ImageStorageLevel = .equipment) {
        // Update the equipment-level or exercise-specific image storage
        ctx.adjustments.updateAdjustmentImage(for: exercise, category: category, newImageName: filename, storageLevel: storageLevel)
        // Sync local state with what was actually stored
        local = ctx.adjustments.adjustmentsEntry(for: exercise)
    }
    
    // MARK: – Image Helpers
    private func imagePreview(for adjustment: AdjustmentEntry) -> some View {
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
                    let hasAnyCustomImage = adjustment.hasCustomImage || 
                        (ctx.adjustments.resolvedImage(for: adjustment) != adjustment.category.image)
                    Image(systemName: hasAnyCustomImage ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(hasAnyCustomImage ? .red : .blue)
                }
            }
    }
    
    private func displayImage(for adjustment: AdjustmentEntry) -> Image {
        // Use resolved image with priority: exercise → equipment → default
        let resolvedImageName = ctx.adjustments.resolvedImage(for: adjustment)
        
        // Check if it's a custom image (not the default)
        if resolvedImageName != adjustment.category.image,
           let uiImage = UIImage(contentsOfFile: getDocumentsDirectory().appendingPathComponent(resolvedImageName).path) {
            return Image(uiImage: uiImage)
        }
        return Image(adjustment.category.image)
    }
    
    private func handleImageButtonTap(for category: AdjustmentCategory) {
        // Check if there's any custom image (exercise-specific or equipment-level)
        guard let entry = local.adjustment(for: category) else { return }
        let hasAnyCustomImage = entry.hasCustomImage || 
            (ctx.adjustments.resolvedImage(for: entry) != entry.category.image)
        
        if hasAnyCustomImage {
            // Determine if we're removing equipment-level or exercise-specific
            let hasExerciseOverride = entry.hasCustomImage
            let hasEquipmentImage = !hasExerciseOverride && 
                (ctx.adjustments.resolvedImage(for: entry) != entry.category.image)
            isRemovingEquipmentLevelImage = hasEquipmentImage
            categoryPendingRemoval = category
        } else {
            activeImageCategory = category
        }
    }
    
    private var removalAlertBinding: Binding<Bool> {
        Binding(
            get: { categoryPendingRemoval != nil },
            set: { 
                if !$0 { 
                    categoryPendingRemoval = nil
                    isRemovingEquipmentLevelImage = false
                }
            }
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

