//
//  DataHelpers.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/23/25.
//

import Foundation
import SwiftUI

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
    
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

@inline(__always)
func normalize(_ s: String) -> String {
    s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}


extension Collection {
    /// Return `nil` if empty; otherwise the collection.
    var nilIfEmpty: Self? { isEmpty ? nil : self }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
// Extension for safe array indexing
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
// Splits an array into chunks of a given size.
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
// A safe subscript to prevent out of range errors.
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Small safety helpers
extension Array {
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
}
