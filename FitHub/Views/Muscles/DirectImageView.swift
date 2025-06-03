//
//  DirectImageView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/12/25.
//

import SwiftUI
import Foundation


struct DirectImageView: View {
    let imageName: String
    
    var body: some View {
        if let image = load(fullPath: imageName) {
            image.resizable().scaledToFit()
        } else {
            Text("Image not available")
                .foregroundColor(.red)
        }
    }
    
   /* private func loadImage(fileName: String) -> Image? {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "png"),
              let uiImage = UIImage(contentsOfFile: filePath) else {
            print("PNG file not found: \(fileName).png")
            return nil
        }
        return Image(uiImage: uiImage)
    }*/
    private func load(fullPath: String) -> Image? {
        guard let url = Bundle.main.resourceURL?
                           .appendingPathComponent(fullPath)
                           .appendingPathExtension("png"),
              let ui  = UIImage(contentsOfFile: url.path) else {
            print("🚫 PNG not found at \(fullPath).png")
            return nil
        }
        return Image(uiImage: ui)
    }
}

