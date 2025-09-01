//
//  PhotoPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/9/25.
//

import SwiftUI
import PhotosUI   // PHPicker

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?               // selected image
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1              // single image
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController,
                    didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}


struct UploadImageDemo: View {
    // ────────── Input
    /// Pass a previously-saved filename (e.g. `"pickedPhoto-XYZ.jpg"`).
    /// Leave `nil` to start with “No image selected”.
    var initialFilename: String? = nil
    
    /// Called after the user explicitly saves or deletes the photo.
    var onImagePicked: (String) -> Void = { _ in }
    
    // ────────── State
    @State private var selectedImage: UIImage?
    @State private var showingPicker = false
    @State private var savedFilename: String?
    
    // ────────── View
    var body: some View {
        VStack(spacing: 20) {
            if let uiImage = selectedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
            } else {
                Text("No image selected")
                    .foregroundStyle(Color.secondary)
            }
            
            Button("Choose Photo") { showingPicker = true }
                .buttonStyle(.borderedProminent)
            
            if selectedImage != nil {
                Button(role: .destructive) { removeCurrentPhoto() } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingPicker) { PhotoPicker(image: $selectedImage) }
        .onAppear(perform: loadInitialImage)
        .onChange(of: selectedImage) { saveOnChange(selectedImage) }
        .padding()
    }
    
    // MARK: – Initial load
    private func loadInitialImage() {
        guard let file = initialFilename else { return }
        let url = getDocumentsDirectory().appendingPathComponent(file)
        if let uiImg = UIImage(contentsOfFile: url.path) {
            selectedImage = uiImg
            savedFilename = file
        }
    }
    
    // MARK: – Save whenever `selectedImage` changes
    private func saveOnChange(_ newImage: UIImage?) {
        guard let image = newImage else { return }
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filename = "pickedPhoto-\(UUID().uuidString).jpg"
        let url      = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
            savedFilename = filename
            onImagePicked(filename)
        } catch {
            print("Failed to save image:", error)
        }
    }
    
    // MARK: – Remove
    private func removeCurrentPhoto() {
        if let file = savedFilename {
            let url = getDocumentsDirectory().appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }
        selectedImage  = nil
        savedFilename  = nil
        onImagePicked("") // notify removal
    }
}
