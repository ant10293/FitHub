//
//  AdjustmentImageUpload.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/9/25.
//

import SwiftUI

enum ImageStorageLevel: String, CaseIterable {
    case equipment = "Equipment Level"
    case exercise = "Exercise Level"
    
    func description(hasExistingEquipmentImage: Bool) -> String {
        switch self {
        case .equipment:
            if hasExistingEquipmentImage {
                return "This will overwrite the existing equipment-level image shared across all exercises using this equipment."
            } else {
                return "This image will be shared across all exercises using this equipment."
            }
        case .exercise:
            return "This image will only apply to this specific exercise."
        }
    }
}

struct AdjustmentImageUpload: View {
    var initialFilename: String? = nil
    var hasExistingEquipmentImage: Bool = false
    var onImagePicked: (String, ImageStorageLevel) -> Void
    
    @State private var storageLevel: ImageStorageLevel = .equipment
    
    var body: some View {
        VStack(spacing: 20) {
            // Storage level picker
            VStack(alignment: .leading, spacing: 8) {
                Picker("Storage Level", selection: $storageLevel) {
                    ForEach(ImageStorageLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                
                WarningFooter(
                    message: storageLevel.description(hasExistingEquipmentImage: hasExistingEquipmentImage),
                    color: isWarning ? .orange : .secondary,
                    showImage: isWarning
                )
            }
            .padding(.horizontal)
            
            // Wrapped UploadImage
            UploadImage(initialFilename: initialFilename) { filename in
                // Pass both filename and storage level to the callback
                onImagePicked(filename, storageLevel)
            }
        }
    }
    
    private var isWarning: Bool {
        hasExistingEquipmentImage && storageLevel == .equipment
    }
}

