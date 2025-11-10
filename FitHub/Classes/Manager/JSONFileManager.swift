//
//  JSONFileManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/22/25.
//

import Foundation

/// Centralized JSON file management to prevent race conditions
final class JSONFileManager {
    static let shared = JSONFileManager()
    
    let saveQueue = DispatchQueue(label: "com.FitHubApp.JSONFileManager", qos: .userInitiated)
    private let fileManager = FileManager.default
    
    // MARK: - Debouncing support
    private let debounceQueue = DispatchQueue(label: "com.FitHubApp.JSONFileManager.debounce")
    private var pendingSingleSaves: [String: DispatchWorkItem] = [:]
    private var pendingFullSaves: [String: DispatchWorkItem] = [:]
    
    private init() {}
    
    // MARK: - Generic Save Method (ONE method for everything)
    
    func save<T: Encodable>(_ data: T, to filename: String, dateEncoding: Bool = false) {
        saveQueue.async {
            do {
                let url = getDocumentsDirectory().appendingPathComponent(filename)
                let encoder = JSONEncoder()
                if dateEncoding { encoder.dateEncodingStrategy = .iso8601 }
                let jsonData = try encoder.encode(data)
                try jsonData.write(to: url, options: [.atomicWrite, .completeFileProtection])
                print("✅ Saved \(filename) successfully")
            } catch {
                print("❌ Failed to save \(filename): \(error)")
            }
        }
    }
    
    private static func parseJSONArray<T>(
        from data: Data,
        filename: String,
        itemType: String,
        decoder: @escaping ([String: Any]) throws -> T
    ) -> [T] {
        // Parse JSON manually to handle individual entry failures
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("❌ Couldn't parse \(filename) as JSON array")
            return []
        }
        
        var validItems: [T] = []
        var skippedCount = 0
        
        for (index, jsonDict) in jsonArray.enumerated() {
            do {
                let item = try decoder(jsonDict)
                validItems.append(item)
            } catch {
                let name = jsonDict["name"] as? String ?? "<no name>"
                print("⚠️ Skipping \(itemType) '\(name)' at index \(index): \(error.localizedDescription)")
                skippedCount += 1
                continue
            }
        }
        
        if skippedCount > 0 {
            print("⚠️ Skipped \(skippedCount) invalid \(itemType) out of \(jsonArray.count) total")
        }
        
        if validItems.isEmpty {
            print("❌ No valid \(itemType) could be loaded from \(filename)")
        } else {
            print("✅ Successfully loaded \(validItems.count) \(itemType) from \(filename)")
        }
        
        return validItems
    }

    // MARK: - Generic Load Method for Bundle Data
    static func loadBundledData<T>(
        filename: String,
        itemType: String,
        decoder: @escaping ([String: Any]) throws -> T,
        validator: @escaping (T) -> Bool
    ) -> [T] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Couldn't read \(filename).json")
            return []
        }
        
        return parseJSONArray(
            from: data,
            filename: "\(filename).json",
            itemType: itemType,
            decoder: decoder
        )
    }
    
    func loadFromDocuments<T: Decodable>(
        _ type: T.Type,
        from filename: String,
        itemType: String? = nil,
        dateDecoding: Bool = false
    ) -> T? {
        do {
            let url = getDocumentsDirectory().appendingPathComponent(filename)
            
            guard fileManager.fileExists(atPath: url.path) else {
                print("⚠️ File \(filename) doesn't exist yet (first run)")
                return nil
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            if dateDecoding { decoder.dateDecodingStrategy = .iso8601 }
            let result = try decoder.decode(type, from: data)
            
            let itemDescription = itemType ?? String(describing: type)
            if let array = result as? [Any] {
                print("✅ Successfully loaded \(array.count) \(itemDescription) from \(filename)")
            } else if let dict = result as? [AnyHashable: Any] {
                print("✅ Successfully loaded \(dict.count) \(itemDescription) from \(filename)")
            } else {
                print("✅ Successfully loaded \(itemDescription) from \(filename)")
            }
            
            return result
            
        } catch {
            print("❌ Failed to load \(filename): \(error)")
            return nil
        }
    }
    
    // MARK: - Specific Load Methods for Different Data Types
    func loadUserExercises(from filename: String) -> [Exercise]? {
        return loadFromDocuments([Exercise].self, from: filename, itemType: "user exercises")
    }
        
    func loadAdjustments(from filename: String) -> [UUID: ExerciseEquipmentAdjustments]? {
        return loadFromDocuments([UUID: ExerciseEquipmentAdjustments].self, from: filename, itemType: "adjustments")
    }
    
    func loadEquipmentOverrides(from filename: String) -> [UUID: GymEquipment]? {
        return loadFromDocuments([UUID: GymEquipment].self, from: filename, itemType: "equipment overrides")
    }
    
    func loadExerciseOverrides(from filename: String) -> [UUID: Exercise]? {
        return loadFromDocuments([UUID: Exercise].self, from: filename, itemType: "exercise overrides")
    }
    
    func loadUserEquipment(from filename: String) -> [GymEquipment]? {
        return loadFromDocuments([GymEquipment].self, from: filename, itemType: "user equipment")
    }
    
    func loadUserData(from filename: String) -> UserData? {
        return loadFromDocuments(UserData.self, from: filename, itemType: "userData")
    }
        
    func loadPerformanceData(from filename: String) -> [UUID: ExercisePerformance]? {
        guard let array = loadFromDocuments(
            [ExercisePerformance].self,
            from: filename,
            itemType: "performance entries",
            dateDecoding: true
        ) else { return nil }
        
        return Dictionary(uniqueKeysWithValues: array.map { ($0.id, $0) })
    }
    
    // MARK: - Debounced Save Methods
    
    func debouncedSave<T: Encodable>(_ data: T, to filename: String, delay: TimeInterval = 0.8) {
        // Cancel previous save for this file
        pendingFullSaves[filename]?.cancel()
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.save(data, to: filename)
            self.pendingFullSaves[filename] = nil
        }
        
        pendingFullSaves[filename] = work
        debounceQueue.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    /*
    func debouncedSingleFieldSave<T: Encodable>(_ value: T, for key: String, in filename: String, delay: TimeInterval = 0.4) {
        let saveKey = "\(filename)-\(key)"
        
        // Cancel previous save for this key
        pendingSingleSaves[saveKey]?.cancel()
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.saveQueue.async {
                do {
                    let url = getDocumentsDirectory().appendingPathComponent(filename)
                    
                    // Read existing JSON
                    var jsonObject: [String: Any] = [:]
                    if self.fileManager.fileExists(atPath: url.path),
                       let data = try? Data(contentsOf: url),
                       let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        jsonObject = existing
                    }
                    
                    // Encode new value
                    let encoded = try JSONEncoder().encode([key: value])
                    if let partial = try JSONSerialization.jsonObject(with: encoded) as? [String: Any],
                       let updated = partial[key] {
                        jsonObject[key] = updated
                    }
                    
                    // Write back
                    let updatedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                    try updatedData.write(to: url, options: [.atomicWrite, .completeFileProtection])
                    print("✅ Debounced single field save successful for \(key) in \(filename)")
                } catch {
                    print("❌ Debounced single field save failed for \(key) in \(filename): \(error)")
                }
            }
            self.pendingSingleSaves[saveKey] = nil
        }
        
        pendingSingleSaves[saveKey] = work
        debounceQueue.asyncAfter(deadline: .now() + delay, execute: work)
    }
    */
}
