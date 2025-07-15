//
//  Helpers.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/9/25.
//

import Foundation
import SwiftUI

//    .frame(maxHeight: UIScreen.main.bounds.height * 0.33)  // ≈ 1/3 screen

func getFullImage(_ imageName: String, _ fullPath: String) -> Image {
    // 1️⃣ Asset catalog check
    if UIImage(named: fullPath) != nil {
        return Image(fullPath)
    }
    // 2️⃣ Fallback to file in Documents
    let url = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(imageName)
    if let uiImg = UIImage(contentsOfFile: url.path) {
        return Image(uiImage: uiImg)
    }
    // 3️⃣ Final fallback
    return Image(systemName: "photo")
}

func ExEquipImage(_ image: Image, size: CGFloat = 0.44, imageScale: Image.Scale = .large, infoCircle: Bool = true) -> some View {
    image
    .resizable()
    .scaledToFit()
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .overlay(alignment: .bottomTrailing, content: {
        if infoCircle {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
                .imageScale(imageScale)
        }
    })
    .frame(width: UIScreen.main.bounds.width * size)
}

var dismissKeyboardButton: some View {
    Button(action: {
        // Move any potential non-UI related work off the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Perform I/O or any non-UI operations here if needed in the future

            // UI work should remain on the main thread
            DispatchQueue.main.async {
                // Dismiss the keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }) {
        Image(systemName: "keyboard.chevron.compact.down")
            .resizable()
            .frame(width: 24, height: 24)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .clipShape(Circle())
            .shadow(radius: 10)
            .padding()
    }
    .transition(.scale) // Add a transition effect when the button appears/disappears
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
        return Double(truncating: sum as! NSNumber) / Double(count)
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

extension View {
    func centerHorizontally() -> some View {
        self.frame(maxWidth: .infinity, alignment: .center)
    }
}

struct CenterVerticallyModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            content
                .padding(.top, 1)
                .padding(.bottom, 1)
        }
    }
}

extension View {
    func centerVertically() -> some View {
        self.modifier(CenterVerticallyModifier())
    }
}

extension Color {
    static let darkGreen = Color(UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0))
    static let darkBlue = Color(UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0))
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

extension Bundle {
    /// Throws instead of `fatalError` so callers can decide how to handle failure.
    func decode<T: Decodable>(_ file: String,
                              dateStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                              keyStrategy:  JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) throws -> T {
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

