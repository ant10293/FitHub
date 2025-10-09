//
//  AdjustmentsData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

final class AdjustmentsData: ObservableObject {
    private static let jsonKey: String = "adjustments.json"
    @Published var adjustments: [UUID: ExerciseEquipmentAdjustments] = [:] // Store adjustments using a dictionary for fast lookups
    @Published var adjustmentInputs: [String: String] = [:] // Store inputs as strings
    
    // MARK: – Persistence Logic
    static func loadAdjustmentsFromFile() -> AdjustmentsData? {
        guard let savedAdjustments = JSONFileManager.shared.loadAdjustments(from: AdjustmentsData.jsonKey) else {
            return nil
        }
        
        let viewModel = AdjustmentsData()
        viewModel.adjustments = savedAdjustments
        return viewModel
    }
    
    // Load adjustments for all exercises
    func loadAllAdjustments(for exercises: [Exercise], allEquipment: [GymEquipment]) {
        for exercise in exercises {
            loadAdjustments(for: exercise, allEquipment: allEquipment)
        }
        //print("Loaded all adjustments: \(adjustments)")
    }
    
    func loadAdjustments(for exercise: Exercise, allEquipment: [GymEquipment]) {
        // ── 0. If we already have an adjustments object, just hydrate the UI
        if let existing = adjustments[exercise.id] {
            for (cat, value) in existing.equipmentAdjustments {
                adjustmentInputs["\(existing.id)-\(cat.rawValue)"] = value.displayValue
            }
            return
        }

        // ── 1. Build a fresh map <AdjustmentCategory : AdjustmentValue>
        var adjustmentValues: [AdjustmentCategory : AdjustmentValue] = [:]

        for requiredName in exercise.equipmentRequired {            // [String]
            if let gear = allEquipment.first(where: {
                    normalize($0.name) == normalize(requiredName)
                }),
               let gearAdjustments = gear.adjustments {

                // create default values for every adjustment category
                for category in gearAdjustments {
                    adjustmentValues[category] = .string("")        // empty text field
                    adjustmentInputs["\(gear.name)-\(category.rawValue)"] = ""
                }
            }
        }

        // ── 2. Persist the empty shell so it’s picked up next launch
        let newEntry = ExerciseEquipmentAdjustments(
            id:               exercise.id,
            equipmentAdjustments: adjustmentValues,
            adjustmentImage:  exercise.image
        )
        adjustments[exercise.id] = newEntry
    }
    
    // MARK: saving logic
    func saveAdjustmentsToFile() {
        JSONFileManager.shared.save(adjustments, to: AdjustmentsData.jsonKey)
    }
}

extension AdjustmentsData {
    // MARK: – Mutations
    func deleteAdjustments(for exercise: Exercise, shouldSave: Bool = true) {
        // Guard: nothing to delete
         guard hasAdjustments(for: exercise) else { return }
    
        // 1. Remove the top-level entry
        adjustments.removeValue(forKey: exercise.id)

        // 2. Clear any cached TextField inputs for that exercise
        let prefix = "\(exercise.id)-"
        adjustmentInputs.keys
            .filter { $0.hasPrefix(prefix) }
            .forEach { adjustmentInputs.removeValue(forKey: $0) }

        // 3. Persist (optional)
        if shouldSave { saveAdjustmentsToFile() }
    }
    
    func updateAdjustmentValue(for exercise: Exercise, category: AdjustmentCategory, newValue: AdjustmentValue, shouldSave: Bool = true) {
        // Grab an existing struct or make an empty one
        var adjustment = adjustments[exercise.id] ?? ExerciseEquipmentAdjustments(id: exercise.id, equipmentAdjustments: [:], adjustmentImage: "")

        // Write the new value
        adjustment.equipmentAdjustments[category] = newValue
        adjustments[exercise.id] = adjustment

        // Sync the TextField cache
        adjustmentInputs["\(exercise.id)-\(category.rawValue)"] = newValue.displayValue

        if shouldSave { saveAdjustmentsToFile() }
    }
    
    func clearAdjustmentValue(exercise: Exercise, for category: AdjustmentCategory, in adjustment: ExerciseEquipmentAdjustments) {
        adjustmentInputs["\(adjustment.id)-\(category.rawValue)"] = ""
        updateAdjustmentValue(for: exercise, category: category, newValue: .string(""))
    }
    
    func addAdjustmentCategory(_ exercise: Exercise, category: AdjustmentCategory) {
        updateAdjustmentValue(for: exercise, category: category, newValue: .string(""))
    }
    
    func deleteAdjustment(exercise: Exercise, category: AdjustmentCategory) {
        guard var adjustments = adjustments[exercise.id] else { return }
        adjustments.equipmentAdjustments.removeValue(forKey: category)
        self.adjustments[exercise.id] = adjustments
        saveAdjustmentsToFile() // Save changes
    }
    
    // MARK: – Helpers
    func hasAdjustments(for exercise: Exercise) -> Bool { adjustments[exercise.id]?.equipmentAdjustments.isEmpty == false }
    
    func getEquipmentAdjustments(for exercise: Exercise) -> [AdjustmentCategory: AdjustmentValue]? {
        if let adjustment = adjustments[exercise.id] {
            return adjustment.equipmentAdjustments
        }
        return nil
    }
}

