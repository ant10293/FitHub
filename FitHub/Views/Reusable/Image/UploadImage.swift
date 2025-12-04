//
//  UploadImage.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/9/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct UploadImage: View {
    // ────────── Input
    var initialFilename: String? = nil
    var onImagePicked: (String) -> Void = { _ in }

    // ────────── State
    @State private var selectedImage: UIImage?
    @State private var savedFilename: String?

    @State private var showingSourceChooser = false
    @State private var showPhotoLibrary = false
    @State private var showCamera = false

    var body: some View {
        let height = screenHeight
        
        VStack(spacing: 20) {
            if let uiImage = selectedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: height * 0.25)
            } else {
                VStack {
                    Text("No image selected")
                        .foregroundStyle(Color.secondary)
                    
                    Button("Add Photo") {
                        showingSourceChooser = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }

            if selectedImage != nil {
                Button(role: .destructive) { removeCurrentPhoto() } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Choose Photo Source", isPresented: $showingSourceChooser, titleVisibility: .visible) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Library") { showPhotoLibrary = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showPhotoLibrary) { PhotoPicker(image: $selectedImage) }
        .sheet(isPresented: $showCamera) { CameraPicker(image: $selectedImage) }
        .onAppear(perform: loadInitialImage)
        .onChange(of: selectedImage) { _, newImage in
            saveOnChange(newImage)
        }
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

// MARK: - Photo library (your original)
private struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
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

// MARK: - Camera picker
private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
