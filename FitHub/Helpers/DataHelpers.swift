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
    
    func partitioned(by predicate: (Element) -> Bool) -> ([Element], [Element]) {
        var matching: [Element] = []
        var nonMatching: [Element] = []
        for el in self {
            if predicate(el) {
                matching.append(el)
            } else {
                nonMatching.append(el)
            }
        }
        return (matching, nonMatching)
    }
}

extension Profile {
    enum NameStyle {
        case title   // e.g. "Anthony"
        case full    // e.g. "Anthony Smith"
    }

    func displayName(_ style: NameStyle) -> String {
        switch style {
        case .title:
            if !firstName.isEmpty { return firstName }
            // fall back to first part of userName
            let parts = userName.split(separator: " ")
            return parts.first.map(String.init) ?? userName

        case .full:
            if !userName.isEmpty { return userName }
            let combined = (firstName + " " + lastName).trimmed
            return combined
        }
    }
}

extension String {
    /// Returns a trimmed version of the string (whitespace removed)
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
    /// Returns `true` if the string is empty after trimming whitespace
    var isEmptyAfterTrim: Bool { trimmed.isEmpty }
    
    func formatName() -> String {
        return (self.prefix(1).uppercased()
                + self.dropFirst().lowercased())
        .trimmingCharacters(in: .whitespaces)
    }
    
    func trimmingTrailingSpaces() -> String {
        guard let range = range(of: "\\s+$", options: .regularExpression) else { return self }
        return replacingCharacters(in: range, with: "")
    }
    
    @inline(__always)
    func normalize() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    @inline(__always)
    func normalized(removing: CharacterSet) -> String {
        unicodeScalars
            .filter { !removing.contains($0) }
            .reduce(into: "") { $0.append(Character($1)) }
            .lowercased()
    }
    
    func capitalizeFirstLetter() -> String {
        guard let idx = self.firstIndex(where: { $0.isLetter }) else { return self }
        var result = self
        let upper = String(result[idx]).uppercased()
        result.replaceSubrange(idx...idx, with: upper)
        return result
    }
    
    var formattedRequirement: String {
        self.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
