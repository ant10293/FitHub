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
    @State private var isEditMode: Bool = false
    @State private var categoryPendingDeletion: AdjustmentCategory? = nil

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
            }
            .navigationBarTitle("Equipment Adjustments", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .sheet(isPresented: $showAddCategoryPicker) {
                AddCategoryPicker(
                    exercise: exercise,
                    existingCategories: existingCategories,
                    onAddCategory: { category in
                        addAdjustmentCategory(category)
                    }
                )
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
                    hasExistingEquipmentImage: hasExistingEquipmentImage,
                    associatedEquipment: associatedEquipment(entry: entry),
                    onImagePicked: { filename, storageLevel in
                        let normalized = filename.isEmpty ? nil : filename
                        updateImage(for: category, filename: normalized, storageLevel: storageLevel)
                        activeImageCategory = nil
                    }
                )
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
            .alert("Delete Adjustment?", isPresented: Binding(
                get: { categoryPendingDeletion != nil },
                set: { if !$0 { categoryPendingDeletion = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    categoryPendingDeletion = nil
                }
                Button("Delete", role: .destructive) {
                    if let category = categoryPendingDeletion {
                        removeAdjustment(category)
                        commitChangesIfNeeded()
                        categoryPendingDeletion = nil
                    }
                }
            } message: {
                if let category = categoryPendingDeletion {
                    Text("Are you sure you want to delete the \(category.rawValue) adjustment?")
                }
            }
        }
    }

    // MARK: – Header
    private var headerSection: some View {
        let imageSize = screenHeight * 0.14

        return HStack {
            Text(exercise.name.isEmpty ? "Unnamed\nExercise" : exercise.name)
                .font(.title2)
                .padding(.trailing, 8)
                .multilineTextAlignment(.center)

            exercise.fullImageView(favState: FavoriteState.getState(for: exercise, userData: ctx.userData))
                .frame(width: imageSize, height: imageSize)
        }
        .padding([.horizontal, .top])
    }

    // MARK: – List
    private func adjustmentList(for adjustments: [AdjustmentEntry]) -> some View {
        let sortedAdjustments = ExerciseAdjustments.sorted(adjustments)

        return List {
            Section {
                if sortedAdjustments.isEmpty {
                    Text("No adjustments found for this exercise.")
                        .foregroundStyle(.gray)
                } else {
                    ForEach(sortedAdjustments, id: \.category) { adjustment in
                        adjustmentRow(for: adjustment)
                    }
                }
                Button {
                    showAddCategoryPicker = true
                } label: {
                    Label("Add Adjustment", systemImage: "plus")
                }
            } header: {
                HStack {
                    Spacer()

                    Button(isEditMode ? "Done" : "Edit") {
                        isEditMode.toggle()
                    }
                    .textCase(.none)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: – Row
    private func adjustmentRow(for adjustment: AdjustmentEntry) -> some View {
        return HStack {
            if isEditMode {
                Button {
                    categoryPendingDeletion = adjustment.category
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(adjustment.category.rawValue)
                        .bold()
                    
                    // Value input based on current value type
                    AdjustmentInputView(
                        value: valueBinding(for: adjustment.category)
                    )
                }
                
                HStack {
                    imagePreview(for: adjustment)
                        .overlay(alignment: .topTrailing) {
                            imageButton(for: adjustment)
                                .allowsHitTesting(true)
                        }
                    
                    // Category picker
                    Picker("Value Type", selection: categoryBinding(for: adjustment.category)) {
                        ForEach(AdjustmentValueCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized)
                                .tag(category)
                                .font(.caption)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private func associatedEquipment(entry: AdjustmentEntry?) -> GymEquipment? {
        guard let entry else { return nil }
        return ctx.equipment.equipment(for: entry.equipmentID)
    }

    private var existingCategories: Set<AdjustmentCategory> { local.categories }

    // MARK: – Bindings & Mutations
    private func valueBinding(for category: AdjustmentCategory) -> Binding<AdjustmentValue> {
        Binding(
            get: {
                local.adjustment(for: category)?.value ?? category.defaultValue
            },
            set: { newValue in
                local.setValue(newValue, for: category)
                commitChangesIfNeeded()
            }
        )
    }
    
    private func categoryBinding(for category: AdjustmentCategory) -> Binding<AdjustmentValueCategory> {
        Binding(
            get: {
                local.adjustment(for: category)?.value.category ?? category.defaultValue.category
            },
            set: { newCategory in
                guard let currentValue = local.adjustment(for: category)?.value else { return }
                let convertedValue = currentValue.converted(to: newCategory)
                local.setValue(convertedValue, for: category)
                commitChangesIfNeeded()
            }
        )
    }

    private func addAdjustmentCategory(_ category: AdjustmentCategory) {
        local.addCategory(category)
        commitChangesIfNeeded()
    }

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
        let width = screenWidth * 0.2

        return displayImage(for: adjustment)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.15))
            )
            .allowsHitTesting(false)
    }

    private func imageButton(for adjustment: AdjustmentEntry) -> some View {
        let hasAnyCustomImage = adjustment.hasCustomImage ||
            (ctx.adjustments.resolvedImage(for: adjustment) != adjustment.category.image)

        return Button {
            handleImageButtonTap(for: adjustment.category)
        } label: {
            Image(systemName: hasAnyCustomImage ? "xmark.circle.fill" : "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(hasAnyCustomImage ? .red : .blue)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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
        ctx.adjustments.loadAdjustments(for: exercise, equipment: ctx.equipment, availableEquipment: ctx.userData.evaluation.availableEquipment)
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
