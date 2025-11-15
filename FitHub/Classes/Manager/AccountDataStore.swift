//
//  AccountDataStore.swift
//  FitHub
//
//  Created by GPT-5 Codex on 11/14/25.
//

import Foundation

/// Handles backing up and restoring per-account JSON data that normally lives in Documents/.
struct AccountDataStore {
    static let shared = AccountDataStore()
    
    private let fileManager = FileManager.default
    private let dataFilenames = [
        UserData.jsonKey,
        ExerciseData.bundledOverridesFilename,
        ExerciseData.userExercisesFileName,
        ExerciseData.performanceFileName,
        EquipmentData.bundledOverridesFilename,
        EquipmentData.userEquipmentFilename,
        AdjustmentsData.jsonKey
    ]
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var accountsDirectory: URL {
        documentsDirectory.appendingPathComponent("Accounts", isDirectory: true)
    }
    
    private func directory(for accountID: String) -> URL {
        accountsDirectory.appendingPathComponent(accountID, isDirectory: true)
    }
    
    // MARK: - Public API
    
    func backupActiveData(for accountID: String) throws {
        try ensureBaseDirectories(accountID: accountID)
        let accountDir = directory(for: accountID)
        
        for filename in dataFilenames {
            let source = documentsDirectory.appendingPathComponent(filename)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            
            let destination = accountDir.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
        }
    }
    
    func restoreDataIfAvailable(for accountID: String) throws -> Bool {
        let accountDir = directory(for: accountID)
        guard fileManager.fileExists(atPath: accountDir.path) else {
            return false
        }
        
        var restored = false
        for filename in dataFilenames {
            let source = accountDir.appendingPathComponent(filename)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            
            let destination = documentsDirectory.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
            restored = true
        }
        return restored
    }
    
    func clearActiveData() throws {
        for filename in dataFilenames {
            let target = documentsDirectory.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: target.path) {
                try fileManager.removeItem(at: target)
            }
        }
    }
    
    func deleteBackup(for accountID: String) throws {
        let accountDir = directory(for: accountID)
        if fileManager.fileExists(atPath: accountDir.path) {
            try fileManager.removeItem(at: accountDir)
        }
    }
    
    private func hasBackup(for accountID: String) -> Bool {
        let accountDir = directory(for: accountID)
        return fileManager.fileExists(atPath: accountDir.path)
    }
    
    // MARK: - Helpers
    
    private func ensureBaseDirectories(accountID: String) throws {
        if !fileManager.fileExists(atPath: accountsDirectory.path) {
            try fileManager.createDirectory(at: accountsDirectory, withIntermediateDirectories: true)
        }
        let accountDir = directory(for: accountID)
        if !fileManager.fileExists(atPath: accountDir.path) {
            try fileManager.createDirectory(at: accountDir, withIntermediateDirectories: true)
        }
    }
}



