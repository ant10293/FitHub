//
//  DataHelpers.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/23/25.
//

import Foundation
import SwiftUI
    
func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    guard let firstPath = paths.first else {
        // Fallback to a default documents directory if the array is empty
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
    }
    return firstPath
}

extension Bundle {
    /// Throws instead of `fatalError` so callers can decide how to handle failure.
    func decode<T: Decodable>(
        _ file: String,
        dateStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        keyStrategy:  JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys
    ) throws -> T {
        guard let url = url(forResource: file, withExtension: nil) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: file])
        }
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateStrategy
        decoder.keyDecodingStrategy  = keyStrategy
        return try decoder.decode(T.self, from: data)
    }
}

extension Collection {
    /// Return `nil` if empty; otherwise the collection.
    var nilIfEmpty: Self? { isEmpty ? nil : self }
    
    // A safe subscript to prevent out of range errors.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// Helper extension for averaging an array
extension Array where Element: Numeric {
    var average: Double? {
        guard !isEmpty else { return nil }
        let sum = reduce(0, +)
        if let nsNumber = sum as? NSNumber {
            return Double(truncating: nsNumber) / Double(count)
        }
        return nil
    }
}

extension Array {
    // Extension for safe array indexing
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    // Small safety helpers
    subscript(safeEdit index: Index) -> Element? {
        get { indices.contains(index) ? self[index] : nil }
        set {
            guard let new = newValue else { return }
            if indices.contains(index) {
                self[index] = new
            } else if index == endIndex {
                self.append(new)
            }
        }
    }
    
    // Splits an array into chunks of a given size.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
    
    // MARK: - Array Extension for Shuffling with RNG - ExerciseSelector()
    func shuffled<T: RandomNumberGenerator>(using generator: inout T) -> [Element] {
        var array = self
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i, using: &generator)
            array.swapAt(i, j)
        }
        return array
    }
}


