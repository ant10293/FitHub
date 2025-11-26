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
    
    func description(hasExistingEquipmentImage: Bool, associatedEquipment: GymEquipment?) -> String {
        switch self {
        case .equipment:
            let equipmentLabel: String
            if let name = associatedEquipment?.name, !name.isEmpty {
                equipmentLabel = "the '\(name)' equipment"
            } else {
               equipmentLabel = "this equipment"
            }
            
            if hasExistingEquipmentImage {
                return "This will overwrite the existing equipment-level image shared across all exercises using \(equipmentLabel)."
            } else {
                return "This image will be shared across all exercises using \(equipmentLabel)."
            }
        case .exercise:
            return "This image will only apply to this specific exercise."
        }
    }
}

struct AdjustmentImageUpload: View {
    @State private var storageLevel: ImageStorageLevel = .equipment
    var initialFilename: String? = nil
    var hasExistingEquipmentImage: Bool = false
    let associatedEquipment: GymEquipment?
    var onImagePicked: (String, ImageStorageLevel) -> Void
        
    var body: some View {
        VStack(spacing: 20) {
            // Storage level picker
            if showStorageLevelPicker {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Storage Level", selection: $storageLevel) {
                        ForEach(ImageStorageLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    WarningFooter(
                        message: storageLevel.description(
                            hasExistingEquipmentImage: hasExistingEquipmentImage,
                            associatedEquipment: associatedEquipment
                        ),
                        color: isWarning ? .orange : .secondary,
                        showImage: isWarning
                    )
                    .centerHorizontally()
                }
                .padding(.horizontal)
            }
            
            // Wrapped UploadImage
            UploadImage(initialFilename: initialFilename) { filename in
                // if we aren't showing storage level equipment, its because theres no associated equipment
                let level = showStorageLevelPicker ? storageLevel : .exercise
                // Pass both filename and storage level to the callback
                onImagePicked(filename, level)
            }
        }
    }
    
    private var showStorageLevelPicker: Bool {
        associatedEquipment != nil
    }
    
    private var isWarning: Bool {
        hasExistingEquipmentImage && storageLevel == .equipment
    }
}

