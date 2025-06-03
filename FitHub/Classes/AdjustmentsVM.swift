//
//  AdjustmentsViewModel.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

class AdjustmentsViewModel: ObservableObject {
     var adjustments: [String: ExerciseEquipmentAdjustments] = [:] // Store adjustments using a dictionary for fast lookups
     var adjustmentInputs: [String: String] = [:] // Store inputs as strings
    
    func clearAdjustmentValue(exercise: Exercise, for category: AdjustmentCategories, in adjustment: ExerciseEquipmentAdjustments) {
        adjustmentInputs["\(adjustment.id)-\(category.rawValue)"] = ""
        updateAdjustmentValue(for: exercise.name, category: category, newValue: .string(""))
    }
    
    func addAdjustmentCategory(_ exercise: Exercise, category: AdjustmentCategories) {
        updateAdjustmentValue(
            for: exercise.name,
            category: category,
            newValue: .string("") // Default value for a new category
        )
    }
    
    func deleteAdjustment(exercise: Exercise, category: AdjustmentCategories) {
        guard var adjustments = adjustments[exercise.name] else { return }
        adjustments.equipmentAdjustments.removeValue(forKey: category)
        self.adjustments[exercise.name] = adjustments
        saveAdjustmentsToFile() // Save changes
    }
    
    func getEquipmentAdjustments(for exercise: Exercise) -> [AdjustmentCategories: AdjustmentValue]? {
        if let adjustment = adjustments[exercise.name] {
            return adjustment.equipmentAdjustments
        }
        return nil
    }
    
    func hasEquipmentAdjustments(for exercise: Exercise) -> Bool {
        return adjustments[exercise.name]?.equipmentAdjustments.isEmpty == false
    }
    
    // Load adjustments for all exercises
    func loadAllAdjustments(for exercises: [Exercise], equipmentData: EquipmentData) {
        for exercise in exercises {
            loadAdjustments(for: exercise, equipmentData: equipmentData)
        }
        //print("Loaded all adjustments: \(adjustments)")
    }
    
    func loadAdjustments(for exercise: Exercise, equipmentData: EquipmentData) {
        guard let exerciseAdjustment = adjustments[exercise.name] else {
            // If no adjustments exist for the exercise, create new ones
            var adjustmentValues = [AdjustmentCategories: AdjustmentValue]()
            
            for equipmentName in exercise.equipmentRequired {
                if let gymEquipment = equipmentData.allEquipment.first(where: { $0.name == equipmentName }),
                   let equipmentAdjustments = gymEquipment.adjustments {
                    
                    // Initialize default adjustment values for each category
                    for category in equipmentAdjustments {
                        //adjustmentValues[category] = .integer(0)
                        adjustmentValues[category] = .string("") // Set initial value to an empty string
                        adjustmentInputs["\(gymEquipment.name)-\(category.rawValue)"] = ""
                    }
                }
            }
            
            let newAdjustment = ExerciseEquipmentAdjustments(
                id: exercise.name,
                exercise: exercise.name,
                equipmentAdjustments: adjustmentValues,
                adjustmentImage: exercise.image
            )
            adjustments[exercise.name] = newAdjustment
            return
        }
        
        // If adjustments already exist, load them into the local dictionary
        for (category, value) in exerciseAdjustment.equipmentAdjustments {
            adjustmentInputs["\(exerciseAdjustment.id)-\(category.rawValue)"] = value.displayValue
        }
    }
    
    func updateAdjustmentValue(for exerciseName: String, category: AdjustmentCategories, newValue: AdjustmentValue) {
        if let adjustment = adjustments[exerciseName] {
            var updatedAdjustment = adjustment
            updatedAdjustment.equipmentAdjustments[category] = newValue
            adjustments[exerciseName] = updatedAdjustment
            
            // Update adjustment input string for TextField
            adjustmentInputs["\(exerciseName)-\(category.rawValue)"] = newValue.displayValue
        } else {
            print("No adjustment found for exercise: \(exerciseName)")
        }
    }
    
    func saveAdjustmentsToFile() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    print("Instance was deinitialized before saving could complete.")
                }
                return
            }
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.adjustments) // Use 'self' safely as it is now weakly captured
                let url = self.getDocumentsDirectory().appendingPathComponent("adjustments.json")
                try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
                DispatchQueue.main.async {
                    print("Adjustments successfully saved to file.")
                }
            } catch {
                DispatchQueue.main.async {
                    print("Failed to save adjustments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    static func loadAdjustmentsFromFile() -> AdjustmentsViewModel? {
        do {
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("adjustments.json")
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let savedAdjustments = try decoder.decode([String: ExerciseEquipmentAdjustments].self, from: data)
            
            let viewModel = AdjustmentsViewModel()
            viewModel.adjustments = savedAdjustments
            return viewModel
        } catch {
            print("Failed to load adjustments: \(error)")
            return nil
        }
    }
    
    // Helper to get the documents directory
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}


