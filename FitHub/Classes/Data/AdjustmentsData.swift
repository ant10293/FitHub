//
//  AdjustmentsData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

final class AdjustmentsData: ObservableObject {
    static let jsonKey: String = "adjustments.json"
    @Published var adjustments: [UUID: ExerciseEquipmentAdjustments] = [:] // Store adjustments using a dictionary for fast lookups
    
    // MARK: – Persistence Logic
    static func loadAdjustmentsFromFile() -> AdjustmentsData? {
        guard let savedAdjustments = JSONFileManager.shared.loadAdjustments(from: AdjustmentsData.jsonKey) else {
            return nil
        }
        let adjustmentsData = AdjustmentsData()
        adjustmentsData.adjustments = savedAdjustments
        return adjustmentsData
    }
    
    // Load adjustments for all exercises
    func loadAllAdjustments(for exercises: [Exercise], allEquipment: [GymEquipment]) {
        for exercise in exercises {
            loadAdjustments(for: exercise, allEquipment: allEquipment)
        }
    }
    
    func loadAdjustments(for exercise: Exercise, allEquipment: [GymEquipment]) {
        let requiredCategories = categoriesForExercise(exercise, allEquipment: allEquipment)
        
        if var existing = adjustments[exercise.id] {
            var seen = Set(existing.equipmentAdjustments.map(\.category))
            
            for category in requiredCategories where !seen.contains(category) {
                existing.equipmentAdjustments.append(
                    EquipmentAdjustment(category: category, value: .string(""), image: nil)
                )
                seen.insert(category)
            }
            
            existing.setSorted()
            adjustments[exercise.id] = existing
            
            return
        }
        
        let adjustmentValues: [EquipmentAdjustment] = requiredCategories.map {
            return EquipmentAdjustment(category: $0, value: .string(""), image: nil)
        }
        
        let newEntry = ExerciseEquipmentAdjustments(
            id: exercise.id,
            equipmentAdjustments: adjustmentValues,
            sorted: true
        )
        
        adjustments[exercise.id] = newEntry
    }
    
    // MARK: saving logic
    func saveAdjustmentsToFile() {
        JSONFileManager.shared.save(adjustments, to: AdjustmentsData.jsonKey)
    }
}

extension AdjustmentsData {
    // MARK: – Deletion Mutations
    func deleteAdjustments(for exercise: Exercise, shouldSave: Bool = true) {
        // Guard: nothing to delete
         guard hasAdjustments(for: exercise) else { return }
    
        // 1. Remove the top-level entry
        adjustments.removeValue(forKey: exercise.id)

        // 2. Persist (optional)
        if shouldSave { saveAdjustmentsToFile() }
    }
    
    func deleteAdjustment(exercise: Exercise, category: AdjustmentCategory) {
        guard var adjustments = adjustments[exercise.id] else { return }
        adjustments.equipmentAdjustments.removeAll { $0.category == category }
        self.adjustments[exercise.id] = adjustments
        saveAdjustmentsToFile() // Save changes
    }
    
    func clearAdjustmentValue(exercise: Exercise, for category: AdjustmentCategory, in adjustment: ExerciseEquipmentAdjustments) {
        updateAdjustmentValue(for: exercise, category: category, newValue: .string(""))
    }
}

extension AdjustmentsData {
    // MARK: – Update Mutations
    func overwriteAdjustments(for exercise: Exercise, new: ExerciseEquipmentAdjustments, shouldSave: Bool = true) {
        adjustments[exercise.id] = new.normalized()
        if shouldSave { saveAdjustmentsToFile() }
    }

    func updateAdjustmentValue(for exercise: Exercise, category: AdjustmentCategory, newValue: AdjustmentValue, shouldSave: Bool = true) {
        // Grab an existing struct or make an empty one
        var adjustment = adjustments[exercise.id] ?? ExerciseEquipmentAdjustments(id: exercise.id, equipmentAdjustments: [])

        // Write the new value
        if let index = adjustment.equipmentAdjustments.firstIndex(where: { $0.category == category }) {
            adjustment.equipmentAdjustments[index].value = newValue
        } else {
            adjustment.equipmentAdjustments.append(EquipmentAdjustment(category: category, value: newValue, image: nil))
        }
        
        adjustment.setSorted()
        adjustments[exercise.id] = adjustment

        // Sync the TextField cache
        if shouldSave { saveAdjustmentsToFile() }
    }
    
    func addAdjustmentCategory(_ exercise: Exercise, category: AdjustmentCategory) {
        updateAdjustmentValue(for: exercise, category: category, newValue: .string(""))
    }
    
    func updateAdjustmentImage(for exercise: Exercise, category: AdjustmentCategory, newImageName: String?, shouldSave: Bool = true) {
        guard var adjustment = adjustments[exercise.id] else { return }
        if let index = adjustment.equipmentAdjustments.firstIndex(where: { $0.category == category }) {
            adjustment.equipmentAdjustments[index].image = newImageName?.isEmpty == false ? newImageName : nil
            adjustments[exercise.id] = adjustment
            if shouldSave { saveAdjustmentsToFile() }
        }
    }
}

extension AdjustmentsData {
    // MARK: – Helpers
    private func categoriesForExercise(_ exercise: Exercise, allEquipment: [GymEquipment]) -> [AdjustmentCategory] {
        var categories: [AdjustmentCategory] = []
        var seen = Set<AdjustmentCategory>()
        
        for requiredName in exercise.equipmentRequired {
            guard let gear = allEquipment.first(where: { $0.name.normalize() == requiredName.normalize() }),
                  let gearAdjustments = gear.adjustments else { continue }
            
            for category in gearAdjustments where !seen.contains(category) {
                seen.insert(category)
                categories.append(category)
            }
        }
        
        return categories
    }
    
    func getEquipmentAdjustments(for exercise: Exercise) -> [EquipmentAdjustment]? {
        if let adjustment = adjustments[exercise.id] {
            return adjustment.equipmentAdjustments
        }
        return nil
    }
    
    func adjustmentsEntry(for exercise: Exercise) -> ExerciseEquipmentAdjustments {
        if let existing = adjustments[exercise.id] {
            return existing.normalized()
        }
        return ExerciseEquipmentAdjustments(id: exercise.id, equipmentAdjustments: [], sorted: true)
    }
    
    func hasAdjustments(for exercise: Exercise) -> Bool { adjustments[exercise.id]?.equipmentAdjustments.isEmpty == false }
}

