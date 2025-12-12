//
//  AccountDataStore.swift
//  FitHub
//
//  Created by GPT-5 Codex on 11/14/25.
//

import Foundation

/// Handles backing up and restoring per-account JSON data that normally lives in Documents/.
/// Thread-safe implementation with serial queue to prevent race conditions.
final class AccountDataStore {
    static let shared = AccountDataStore()

    private let fileManager = FileManager.default
    private let dataFilenames = [
        UserData.jsonKey,
        ExerciseData.bundledOverridesFilename,
        ExerciseData.userExercisesFileName,
        ExerciseData.performanceFileName,
        EquipmentData.bundledOverridesFilename,
        EquipmentData.userEquipmentFilename,
        AdjustmentsData.exerciseAdjustmentsKey,
        AdjustmentsData.equipmentAdjustmentsKey
    ]

    // Serial queue for all file operations to prevent race conditions
    private let operationQueue = DispatchQueue(
        label: "com.FitHub.AccountDataStore",
        qos: .userInitiated
    )

    // Track ongoing operations per account to prevent concurrent operations on same account
    private var activeOperations: Set<String> = []
    private let operationsLock = NSLock()

    private init() {}

    private var documentsDirectory: URL { getDocumentsDirectory() }

    private var accountsDirectory: URL {
        documentsDirectory.appendingPathComponent("Accounts", isDirectory: true)
    }

    private func directory(for accountID: String) -> URL {
        accountsDirectory.appendingPathComponent(accountID, isDirectory: true)
    }

    // MARK: - Public API

    /// Backs up active data for the given account ID.
    /// Thread-safe: Uses serial queue to prevent race conditions.
    /// - Parameter accountID: The account ID to backup data for
    /// - Throws: File system errors
    func backupActiveData(for accountID: String) throws {
        try performOperation(for: accountID) {
            try self.ensureBaseDirectories(accountID: accountID)
            let accountDir = self.directory(for: accountID)

            for filename in self.dataFilenames {
                let source = self.documentsDirectory.appendingPathComponent(filename)
                guard self.fileManager.fileExists(atPath: source.path) else { continue }

                let destination = accountDir.appendingPathComponent(filename)

                // Atomic operation: remove existing file if present, then copy
                if self.fileManager.fileExists(atPath: destination.path) {
                    try self.fileManager.removeItem(at: destination)
                }
                try self.fileManager.copyItem(at: source, to: destination)
            }
        }
    }

    /// Restores data for the given account ID if available.
    /// Thread-safe: Uses serial queue to prevent race conditions.
    /// - Parameter accountID: The account ID to restore data for
    /// - Returns: `true` if data was restored, `false` if no backup exists
    /// - Throws: File system errors
    func restoreDataIfAvailable(for accountID: String) throws -> Bool {
        return try performOperation(for: accountID) {
            let accountDir = self.directory(for: accountID)
            guard self.fileManager.fileExists(atPath: accountDir.path) else {
                return false
            }

            var restored = false
            for filename in self.dataFilenames {
                let source = accountDir.appendingPathComponent(filename)
                guard self.fileManager.fileExists(atPath: source.path) else { continue }

                let destination = self.documentsDirectory.appendingPathComponent(filename)

                // Atomic operation: remove existing file if present, then copy
                if self.fileManager.fileExists(atPath: destination.path) {
                    try self.fileManager.removeItem(at: destination)
                }
                try self.fileManager.copyItem(at: source, to: destination)
                restored = true
            }
            return restored
        }
    }

    /// Clears all active data files.
    /// Thread-safe: Uses serial queue to prevent race conditions.
    /// - Throws: File system errors
    func clearActiveData() throws {
        try performOperation(for: nil) {
            for filename in self.dataFilenames {
                let target = self.documentsDirectory.appendingPathComponent(filename)
                if self.fileManager.fileExists(atPath: target.path) {
                    try self.fileManager.removeItem(at: target)
                }
            }
        }
    }

    /// Deletes backup for the given account ID.
    /// Thread-safe: Uses serial queue to prevent race conditions.
    /// - Parameter accountID: The account ID to delete backup for
    /// - Throws: File system errors
    func deleteBackup(for accountID: String) throws {
        try performOperation(for: accountID) {
            let accountDir = self.directory(for: accountID)
            if self.fileManager.fileExists(atPath: accountDir.path) {
                try self.fileManager.removeItem(at: accountDir)
            }
        }
    }

    // MARK: - Thread Safety

    /// Performs an operation on the serial queue with account-level locking.
    /// Prevents concurrent operations on the same account.
    /// - Parameters:
    ///   - accountID: The account ID to lock (nil for global operations like clearActiveData)
    ///   - operation: The operation to perform
    /// - Returns: The result of the operation
    /// - Throws: Errors from the operation
    private func performOperation<T>(for accountID: String?, operation: @escaping () throws -> T) throws -> T {
        // If accountID is provided, check for concurrent operations on same account
        if let accountID = accountID {
            operationsLock.lock()
            if activeOperations.contains(accountID) {
                operationsLock.unlock()
                throw NSError(
                    domain: "AccountDataStore",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Operation already in progress for account: \(accountID)"]
                )
            }
            activeOperations.insert(accountID)
            operationsLock.unlock()
        }

        defer {
            if let accountID = accountID {
                operationsLock.lock()
                activeOperations.remove(accountID)
                operationsLock.unlock()
            }
        }

        // Perform operation on serial queue
        return try operationQueue.sync {
            try operation()
        }
    }

    /// Checks if a backup exists for the given account ID.
    /// Thread-safe: Uses serial queue to prevent race conditions.
    /// - Parameter accountID: The account ID to check
    /// - Returns: `true` if backup exists, `false` otherwise
    func hasBackup(for accountID: String) -> Bool {
        return operationQueue.sync {
            let accountDir = self.directory(for: accountID)
            return self.fileManager.fileExists(atPath: accountDir.path)
        }
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
