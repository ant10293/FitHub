//
//  SchemaVersioned.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/15/25.
//

import Foundation

/// Schema version registry - tracks current version for each file type
enum SchemaVersion {
    private static let versions: [String: Int] = [
        ExerciseData.bundledOverridesFilename: 1,
        ExerciseData.userExercisesFileName: 1,
        ExerciseData.performanceFileName: 1,
        EquipmentData.userEquipmentFilename: 1,
        EquipmentData.bundledOverridesFilename: 1,
        AdjustmentsData.exerciseAdjustmentsKey: 1,
        AdjustmentsData.equipmentAdjustmentsKey: 1
    ]
    
    static func version(for filename: String) -> Int {
        return versions[filename] ?? 1
    }
    
    static func isVersioned(_ filename: String) -> Bool {
        return versions[filename] != nil
    }
}

/// Wrapper for JSON data that includes schema version for future migration support
struct SchemaVersioned<T: Codable>: Codable {
    let schemaVersion: Int
    let data: T
    
    init(schemaVersion: Int, data: T) {
        self.schemaVersion = schemaVersion
        self.data = data
    }
    
    /// Convenience initializer that looks up version by filename
    init(filename: String, data: T) {
        self.schemaVersion = SchemaVersion.version(for: filename)
        self.data = data
    }
}

