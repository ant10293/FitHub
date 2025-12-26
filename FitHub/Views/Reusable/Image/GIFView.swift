//
//  GIFView.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/23/25.
//

import SwiftUI
import UIKit
import ImageIO


struct GIFView: View {
    let gifName: String
    let size: CGFloat = 0.9 // Match ExEquipImage default size
    
    var body: some View {
        LazyAnimatedGIFView(gifName: gifName, size: size)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct LazyAnimatedGIFView: View {
    let gifName: String
    let size: CGFloat

    @State private var isLoadingGIF = false
    @State private var animatedImage: UIImage?

    private var imageWidth: CGFloat { screenWidth * size }

    private var baseName: String { gifName.replacingOccurrences(of: ".gif", with: "") }
    private var f1AssetName: String { "Exercise_PNG(f1)/\(baseName)(f1)" }
    private var gifAssetName: String { "Exercise_GIF/\(baseName)" }

    var body: some View {
        Group {
            if let image = animatedImage {
                let aspectRatio = image.size.height / max(image.size.width, 1)
                AsyncGIFImageView(animatedImage: image)
                    .frame(width: imageWidth, height: imageWidth * aspectRatio)

            } else if let f1 = UIImage(named: f1AssetName) {
                // ProgressView ONLY overlays the f1 image
                Image(uiImage: f1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth)
                    .overlay {
                        if isLoadingGIF {
                            ProgressView()
                        }
                    }

            } else {
                placeholderImage
                    .frame(width: imageWidth)
            }
        }
        .task(id: baseName) {
            await loadGIFIfAndOnlyIfF1Exists()
        }
    }

    private var placeholderImage: some View {
        Image("placeholder_rectangle_text")
            .resizable()
            .scaledToFit()
            .frame(width: imageWidth)
    }

    @MainActor
    private func loadGIFIfAndOnlyIfF1Exists() async {
        animatedImage = nil
        isLoadingGIF = false

        // If there's no f1, never attempt GIF and never show spinner.
        guard UIImage(named: f1AssetName) != nil else { return }

        // Optional: if the GIF asset doesn't exist, don't even show a spinner.
        guard let data = NSDataAsset(name: gifAssetName, bundle: .main)?.data else { return }

        isLoadingGIF = true
        defer { isLoadingGIF = false }

        let image = await Task.detached(priority: .userInitiated) {
            await createAnimatedImage(from: data)
        }.value

        if let image { animatedImage = image }
    }

    private func createAnimatedImage(from data: Data) -> UIImage? {
        guard !data.isEmpty else { return nil }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let totalFrames = CGImageSourceGetCount(source)
        guard totalFrames > 0 else { return nil }

        if totalFrames == 1, let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            return UIImage(cgImage: cgImage)
        }

        let maxFrames = 36
        let maxDuration: Double = 3.0

        var totalDuration: Double = 0
        for i in 0..<totalFrames {
            autoreleasepool {
                guard
                    let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                    let gifProps = props[kCGImagePropertyGIFDictionary as String] as? [String: Any]
                else { return }

                let unclamped = gifProps[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
                let clamped   = gifProps[kCGImagePropertyGIFDelayTime as String] as? Double
                let dt = (unclamped ?? clamped ?? 0)
                if dt > 0 { totalDuration += dt }
            }
        }

        if totalDuration <= 0 { totalDuration = Double(totalFrames) * 0.1 }
        let originalFPS = Double(totalFrames) / totalDuration

        // Calculate how many frames we can fit within maxDuration at original FPS
        let maxFramesByDuration = Int(originalFPS * maxDuration)
        // Cap at maxFrames (30) or totalFrames, whichever is smaller
        let actualFrames = min(maxFrames, min(maxFramesByDuration, totalFrames))
        let frameStep = totalFrames > actualFrames ? max(1, totalFrames / actualFrames) : 1

        var frames: [UIImage] = []
        frames.reserveCapacity(actualFrames)

        for i in stride(from: 0, to: totalFrames, by: frameStep) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            if frames.count >= actualFrames { break }
        }

        guard !frames.isEmpty else { return nil }

        // Calculate duration to maintain original FPS
        // This ensures the GIF plays at the same speed as the original
        let duration = Double(frames.count) / originalFPS

        return UIImage.animatedImage(with: frames, duration: duration)
    }
}

private struct AsyncGIFImageView: UIViewRepresentable {
    let animatedImage: UIImage
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = animatedImage
        
        // Set up constraints for proper sizing
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // Set up animation if we have multiple frames
        if let images = animatedImage.images, images.count > 1 {
            imageView.animationImages = images
            imageView.animationDuration = max(animatedImage.duration, 0.1)
            imageView.animationRepeatCount = 0
            imageView.startAnimating()
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Ensure content mode is maintained
        uiView.contentMode = .scaleAspectFit
    }
    
    static func dismantleUIView(_ uiView: UIImageView, coordinator: ()) {
        uiView.stopAnimating()
        uiView.animationImages = nil
    }
}

