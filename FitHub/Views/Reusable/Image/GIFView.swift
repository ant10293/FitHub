//
//  ExpandableGIFView.swift
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
    @State private var isLoading: Bool = true
    @State private var animatedImage: UIImage?
    
    private var imageWidth: CGFloat { screenWidth * size }
    
    var body: some View {
        ZStack {
            // Show f1 PNG immediately while loading, or placeholder if no image
            let baseName = gifName.replacingOccurrences(of: ".gif", with: "")
            let f1ImagePath = "Exercise_PNG(f1)/\(baseName)(f1)"
            
            // Check if f1 image exists, otherwise use placeholder
            if UIImage(named: f1ImagePath) != nil {
                Image(f1ImagePath)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth)
                    .opacity(isLoading ? 1.0 : 0.0)
            } else {
                // Fallback to placeholder if no image
                placeholderImage
            }
                        
            // Show progress overlay while loading
            if isLoading {
                ProgressView()
            }
            
            // Show animated GIF when loaded
            if let image = animatedImage {
                let imageSize = image.size
                let aspectRatio = imageSize.height / imageSize.width
                let imageHeight = imageWidth * aspectRatio
                
                AsyncGIFImageView(animatedImage: image)
                    .frame(width: imageWidth, height: imageHeight)
                    .opacity(isLoading ? 0.0 : 1.0)
            } else if !isLoading {
                // If loading failed and no image, show placeholder
                placeholderImage
            }
        }
        .task {
            await loadGIF()
        }
    }
        
    private var placeholderImage: some View {
        Image("placeholder_rectangle")
            .resizable()
            .scaledToFit()
            .frame(width: imageWidth)
            .opacity(isLoading ? 1.0 : 0.0)
    }
    
    @MainActor
    private func loadGIF() async {
        isLoading = true
        
        // Load on background thread
        let baseName = gifName.replacingOccurrences(of: ".gif", with: "")
        let fullName = "Exercise_GIF/\(baseName)"
        
        let gifData: Data? = NSDataAsset(name: fullName, bundle: .main)?.data
        
        guard let data = gifData else {
            isLoading = false
            return
        }
        
        // Process GIF on background thread
        let image = await Task.detached(priority: .userInitiated) {
            return await createAnimatedImage(from: data)
        }.value
        
        animatedImage = image
        isLoading = false
    }
    
    private func createAnimatedImage(from data: Data) -> UIImage? {
        guard !data.isEmpty else { return nil }
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let totalFrames = CGImageSourceGetCount(source)
        guard totalFrames > 0 else { return nil }
        
        // Single frame, return as static image
        guard totalFrames > 1 else {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                return UIImage(cgImage: cgImage)
            }
            return nil
        }
        
        // Limit to maximum 36 frames and 3 seconds
        let maxFrames = 36
        let maxDuration: Double = 3.0
        
        var totalDuration: Double = 0
        
        // First pass: calculate total duration from all frames to determine original FPS
        for i in 0..<totalFrames {
            autoreleasepool {
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any] {
                    let gifDictKey = kCGImagePropertyGIFDictionary as String
                    if let gifProperties = properties[gifDictKey] as? [String: Any] {
                        let unclampedKey = kCGImagePropertyGIFUnclampedDelayTime as String
                        let delayKey = kCGImagePropertyGIFDelayTime as String
                        
                        if let delayTime = gifProperties[unclampedKey] as? Double, delayTime > 0 {
                            totalDuration += delayTime
                        } else if let delayTime = gifProperties[delayKey] as? Double, delayTime > 0 {
                            totalDuration += delayTime
                        }
                    }
                }
            }
        }
        
        // Default to 0.1 seconds per frame if no duration found
        if totalDuration <= 0 {
            totalDuration = Double(totalFrames) * 0.1
        }
        
        // Calculate original FPS to maintain the same frame rate
        let originalFPS = Double(totalFrames) / totalDuration
        
        // Determine how many frames we can fit in 3 seconds at original FPS
        let targetFrames = min(maxFrames, Int(originalFPS * maxDuration))
        let actualFrames = min(targetFrames, totalFrames)
        
        // Calculate frame step to sample evenly across the GIF
        let frameStep = totalFrames > actualFrames ? max(1, totalFrames / actualFrames) : 1
        
        var images: [UIImage] = []
        
        // Sample frames evenly across the GIF
        for i in stride(from: 0, to: totalFrames, by: frameStep) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }
            images.append(UIImage(cgImage: cgImage))
            
            if images.count >= actualFrames {
                break
            }
        }
        
        guard !images.isEmpty else { return nil }
        
        // Calculate duration to maintain original FPS
        // duration = number_of_frames / fps
        var duration = Double(images.count) / originalFPS
        
        // Cap duration at 3 seconds
        if duration > maxDuration {
            duration = maxDuration
        }
        
        return UIImage.animatedImage(with: images, duration: duration)
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

