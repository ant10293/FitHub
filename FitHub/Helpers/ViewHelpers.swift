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
    guard let documentsURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first else {
        return Image(systemName: "photo")
    }
    let url = documentsURL.appendingPathComponent(imageName)
    if let uiImg = UIImage(contentsOfFile: url.path) {
        return Image(uiImage: uiImg)
    }
    // 3️⃣ Final fallback
    return Image(systemName: "photo")
}

enum WidthStyle { case fit, fill }

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
            .foregroundStyle(.white)
            .background(Color.blue)
            .clipShape(Circle())
            .shadow(radius: 10)
            .padding()
    }
    .transition(.scale) // Add a transition effect when the button appears/disappears
}

// MARK: – thin separator line
struct Line: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(Color.secondary)
    }
}

struct LazyDestination<Content: View>: View {
    let destination: () -> Content
    var body: some View {
        destination()
    }
}

private struct CenterVerticallyModifier: ViewModifier {
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
    
    func centerHorizontally() -> some View {
        self.frame(maxWidth: .infinity, alignment: .center)
    }
}

extension Color {
    static let darkGreen = Color(UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0))
    static let darkBlue = Color(UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0))
    static let gold = Color(red: 212/255, green: 175/255, blue: 55/255)   // #D4AF37
}

func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    content()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
}

func calculateTextWidth(text: String, minWidth: CGFloat, maxWidth: CGFloat) -> CGFloat {
    let font = UIFont.systemFont(ofSize: 17)
    let measured = (text as NSString).size(withAttributes: [.font: font]).width + 20 // padding
    return min(max(measured, minWidth), maxWidth)
}
