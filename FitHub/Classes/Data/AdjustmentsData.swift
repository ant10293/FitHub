//
//  AdjustmentsData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

final class AdjustmentsData: ObservableObject {
    static let exerciseAdjustmentsKey: String = "exerciseAdjustments.json"
    static let equipmentAdjustmentsKey: String = "equipmentAdjustments.json"
    @Published var exerciseAdjustments: [Exercise.ID: ExerciseAdjustments] = [:] // Store adjustments using a dictionary for fast lookups
    @Published var equipmentAdjustments: [GymEquipment.ID: [EquipmentAdjustment]] = [:] // Store equipment-level images
    
    init() {
        exerciseAdjustments = AdjustmentsData.loadExerciseAdjustments()
        equipmentAdjustments = AdjustmentsData.loadEquipmentAdjustments()
    }
    
    // MARK: – Persistence Logic
    static func loadExerciseAdjustments() -> [Exercise.ID: ExerciseAdjustments] {
        JSONFileManager.shared.loadExerciseAdjustments(from: AdjustmentsData.exerciseAdjustmentsKey) ?? [:]
    }
    
    static func loadEquipmentAdjustments() -> [GymEquipment.ID: [EquipmentAdjustment]] {
        JSONFileManager.shared.loadEquipmentAdjustments(from: AdjustmentsData.equipmentAdjustmentsKey) ?? [:]
    }
    
    // Load adjustments for all exercises
    func loadAllAdjustments(for exercises: [Exercise], allEquipment: [GymEquipment]) {
        for exercise in exercises {
            loadAdjustments(for: exercise, allEquipment: allEquipment)
        }
    }
    
    func loadAdjustments(for exercise: Exercise, allEquipment: [GymEquipment]) {
        let requiredKeys = categoriesForExercise(exercise, allEquipment: allEquipment)
        
        // Start from existing or create empty container
        var localAdjustments = exerciseAdjustments[exercise.id] ?? ExerciseAdjustments(
            id: exercise.id,
            entries: [],
            sorted: false
        )
        
        // Track what we already have
        var seen = Set(
            localAdjustments.entries.map {
                AdjustmentKey(equipmentID: $0.equipmentID, category: $0.category)
            }
        )
        
        // Ensure each required key has an entry
        for key in requiredKeys where !seen.contains(key) {
            localAdjustments.entries.append(.empty(for: key))
            seen.insert(key)
        }
        
        localAdjustments.setSorted()
        exerciseAdjustments[exercise.id] = localAdjustments
    }
    
    // MARK: saving logic
    func saveAdjustmentsToFile() {
        JSONFileManager.shared.save(exerciseAdjustments, to: AdjustmentsData.exerciseAdjustmentsKey)
        JSONFileManager.shared.save(equipmentAdjustments, to: AdjustmentsData.equipmentAdjustmentsKey)
    }
}

extension AdjustmentsData {
    // MARK: – Deletion Mutations
    func deleteAdjustments(for exercise: Exercise, shouldSave: Bool = true) {
        // Guard: nothing to delete
         guard hasAdjustments(for: exercise) else { return }
    
        // 1. Remove the top-level entry
        exerciseAdjustments.removeValue(forKey: exercise.id)

        // 2. Persist (optional)
        if shouldSave { saveAdjustmentsToFile() }
    }
    
    func deleteAdjustment(exercise: Exercise, category: AdjustmentCategory) {
        guard var adjustments = exerciseAdjustments[exercise.id] else { return }
        adjustments.entries.removeAll { $0.category == category }
        self.exerciseAdjustments[exercise.id] = adjustments
        saveAdjustmentsToFile() // Save changes
    }
    
    func clearAdjustmentValue(exercise: Exercise, for category: AdjustmentCategory, in adjustment: ExerciseAdjustments) {
        updateAdjustmentValue(for: exercise, category: category, newValue: .string(""))
    }
}

extension AdjustmentsData {
    // MARK: – Update Mutations
    func overwriteAdjustments(for exercise: Exercise, new: ExerciseAdjustments, shouldSave: Bool = true) {
        exerciseAdjustments[exercise.id] = new.normalized()
        if shouldSave { saveAdjustmentsToFile() }
    }

    func updateAdjustmentValue(for exercise: Exercise, category: AdjustmentCategory, newValue: AdjustmentValue, shouldSave: Bool = true) {
        // Grab an existing struct or make an empty one
        var adjustment = exerciseAdjustments[exercise.id] ?? ExerciseAdjustments(id: exercise.id, entries: [])

        // Write the new value
        if let index = adjustment.entries.firstIndex(where: { $0.category == category }) {
            adjustment.entries[index].value = newValue
        } else {
            // Try to find equipment ID from exercise's required equipment
            // This is a fallback - ideally entries should be created via loadAdjustments
            guard let equipmentID = findEquipmentID(for: exercise, category: category) else {
                print("⚠️ Cannot create adjustment entry for \(category.rawValue) - equipment not found. Call loadAdjustments first.")
                return
            }
            let key = AdjustmentKey(equipmentID: equipmentID, category: category)
            var newEntry = AdjustmentEntry.empty(for: key)
            newEntry.value = newValue
            adjustment.entries.append(newEntry)
        }
        
        adjustment.setSorted()
        exerciseAdjustments[exercise.id] = adjustment

        // Sync the TextField cache
        if shouldSave { saveAdjustmentsToFile() }
    }
    
    func addAdjustmentCategory(_ exercise: Exercise, category: AdjustmentCategory) {
        updateAdjustmentValue(for: exercise, category: category, newValue: .string(""))
    }
    
    func updateAdjustmentImage(for exercise: Exercise, category: AdjustmentCategory, newImageName: String?, storageLevel: ImageStorageLevel = .equipment, shouldSave: Bool = true) {
        guard var adjustment = exerciseAdjustments[exercise.id],
              let index = adjustment.entries.firstIndex(where: { $0.category == category }) else {
            print("⚠️ [AdjustmentsData] Cannot update image - adjustment entry not found for \(exercise.name), category: \(category.rawValue)")
            return
        }
        
        let entry = adjustment.entries[index]
        let equipmentID = entry.equipmentID
        let normalizedImage = newImageName?.isEmpty == false ? newImageName : nil
        let isRemoving = normalizedImage == nil
        
        if isRemoving {
            // Removing an image
            switch storageLevel {
            case .exercise:
                // Check if there's an equipment-level image
                let equipmentImage = getEquipmentImage(for: equipmentID, category: category)
                let hasEquipmentImage = equipmentImage?.isEmpty == false
                
                if hasEquipmentImage, let imageName = equipmentImage {
                    // Store the equipment image name so this exercise will ignore this specific image
                    // Also clear any exercise-specific override
                    var updatedAdjustment = entry.adjustment
                    updatedAdjustment.image = nil
                    let updatedEntry = AdjustmentEntry(adjustment: updatedAdjustment, value: entry.value, ignoredEquipmentLevelImage: imageName)
                    adjustment.entries[index] = updatedEntry
                    print("📸 [AdjustmentsData] Set ignoredEquipmentLevelImage=\(imageName) for \(exercise.name), equipment: \(equipmentID.uuidString.prefix(8)), category: \(category.rawValue)")
                } else {
                    // No equipment image, just remove exercise-specific override
                    var updatedAdjustment = entry.adjustment
                    updatedAdjustment.image = nil
                    let updatedEntry = AdjustmentEntry(adjustment: updatedAdjustment, value: entry.value, ignoredEquipmentLevelImage: nil)
                    adjustment.entries[index] = updatedEntry
                    print("📸 [AdjustmentsData] Removed exercise-specific override for \(exercise.name), equipment: \(equipmentID.uuidString.prefix(8)), category: \(category.rawValue)")
                }
            case .equipment:
                // Remove equipment-level image (affects all exercises using this equipment)
                setEquipmentImage(for: equipmentID, category: category, image: nil)
                // Clear ignored image since equipment image is gone
                let updatedEntry = AdjustmentEntry(adjustment: entry.adjustment, value: entry.value, ignoredEquipmentLevelImage: nil)
                adjustment.entries[index] = updatedEntry
                print("📸 [AdjustmentsData] Removed equipment-level image for equipment: \(equipmentID.uuidString.prefix(8)), category: \(category.rawValue)")
            }
        } else {
            // Adding/updating an image
            switch storageLevel {
            case .exercise:
                // Store as exercise-specific override
                var updatedAdjustment = entry.adjustment
                updatedAdjustment.image = normalizedImage
                // Clear ignored image since user is providing their own image
                let updatedEntry = AdjustmentEntry(adjustment: updatedAdjustment, value: entry.value, ignoredEquipmentLevelImage: nil)
                adjustment.entries[index] = updatedEntry
                print("📸 [AdjustmentsData] Stored exercise-specific override for \(exercise.name), equipment: \(equipmentID.uuidString.prefix(8)), category: \(category.rawValue)")
            case .equipment:
                // Store at equipment level (shared across exercises)
                setEquipmentImage(for: equipmentID, category: category, image: normalizedImage)
                print("📸 [AdjustmentsData] Stored equipment-level image for equipment: \(equipmentID.uuidString.prefix(8)), category: \(category.rawValue), image: \(normalizedImage ?? "nil")")
                // Also ensure entry has no exercise-specific override
                // Clear ignored image since this is a new equipment-level image (different from any previously ignored one)
                var updatedAdjustment = entry.adjustment
                updatedAdjustment.image = nil
                let updatedEntry = AdjustmentEntry(adjustment: updatedAdjustment, value: entry.value, ignoredEquipmentLevelImage: nil)
                adjustment.entries[index] = updatedEntry
            }
        }
        
        exerciseAdjustments[exercise.id] = adjustment
        if shouldSave { saveAdjustmentsToFile() }
    }
}

extension AdjustmentsData {
    // MARK: – Helpers
    
    /// Resolves image with priority: exercise-specific → equipment-level → default
    func resolvedImage(for entry: AdjustmentEntry) -> String {
        // 1. Check exercise-specific override
        if let exerciseImage = entry.image, !exerciseImage.isEmpty {
            return exerciseImage
        }
        
        // 2. Check equipment-level
        if let equipmentImage = getEquipmentImage(for: entry.equipmentID, category: entry.category),
           !equipmentImage.isEmpty {
            // 3. Check if this specific equipment image is being ignored
            if let ignoredImage = entry.ignoredEquipmentLevelImage, ignoredImage == equipmentImage {
                // This specific image is ignored, use default
                return entry.category.image
            }
            // Equipment image exists and is not ignored, use it
            return equipmentImage
        }
        
        // 4. Default
        return entry.category.image
    }
    
    /// Gets equipment-level image for a category
    private func getEquipmentImage(for equipmentID: GymEquipment.ID?, category: AdjustmentCategory) -> String? {
        guard let equipmentID = equipmentID,
              let adjustments = equipmentAdjustments[equipmentID] else {
            return nil
        }
        return adjustments.first { $0.category == category }?.image
    }
    
    /// Checks if there's an existing equipment-level image (public helper for UI)
    func hasEquipmentLevelImage(for equipmentID: GymEquipment.ID, category: AdjustmentCategory) -> Bool {
        let image = getEquipmentImage(for: equipmentID, category: category)
        return image?.isEmpty == false
    }
    
    /// Sets equipment-level image for a category
    private func setEquipmentImage(for equipmentID: GymEquipment.ID, category: AdjustmentCategory, image: String?) {
        if equipmentAdjustments[equipmentID] == nil {
            equipmentAdjustments[equipmentID] = []
        }
        
        var adjustments = equipmentAdjustments[equipmentID]!
        if let index = adjustments.firstIndex(where: { $0.category == category }) {
            adjustments[index].image = image
        } else {
            let equipmentAdjustment = EquipmentAdjustment(
                id: equipmentID,
                category: category,
                image: image
            )
            adjustments.append(equipmentAdjustment)
        }
        equipmentAdjustments[equipmentID] = adjustments
    }
    
    /// Finds the equipment ID for a category in an exercise (helper for fallback scenarios)
    private func findEquipmentID(for exercise: Exercise, category: AdjustmentCategory) -> GymEquipment.ID? {
        // This is a fallback - in practice entries should be created via loadAdjustments
        // Try to find from existing entries first (same category might exist for different equipment)
        // Or look up from equipmentAdjustments dictionary
        for (equipmentID, adjustments) in equipmentAdjustments {
            if adjustments.contains(where: { $0.category == category }) {
                return equipmentID
            }
        }
        return nil
    }
    
    private func categoriesForExercise(_ exercise: Exercise, allEquipment: [GymEquipment]) -> [AdjustmentKey] {
        var result: [AdjustmentKey] = []
        var seen = Set<AdjustmentKey>()
        
        for requiredName in exercise.equipmentRequired {
            guard let gear = allEquipment.first(where: { $0.name.normalize() == requiredName.normalize() }),
                  let gearAdjustments = gear.adjustments else { continue }
            
            for category in gearAdjustments {
                let key = AdjustmentKey(equipmentID: gear.id, category: category)
                guard !seen.contains(key) else { continue }
                
                seen.insert(key)
                result.append(key)
            }
        }
        
        return result
    }

    func getEquipmentAdjustments(for exercise: Exercise) -> [AdjustmentEntry]? {
        if let adjustment = exerciseAdjustments[exercise.id] {
            return adjustment.entries
        }
        return nil
    }
    
    func adjustmentsEntry(for exercise: Exercise) -> ExerciseAdjustments {
        if let existing = exerciseAdjustments[exercise.id] {
            return existing.normalized()
        }
        return ExerciseAdjustments(id: exercise.id, entries: [], sorted: true)
    }
    
    func hasAdjustments(for exercise: Exercise) -> Bool { exerciseAdjustments[exercise.id]?.entries.isEmpty == false }
}
