//
//  Asset.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation


enum AssetPath: String, CaseIterable, Codable {
    case detailedMuscle = "Detailed Muscle"
    case muscle = "Muscle"
    case split = "Split"
    case tap = "Tap"
    
    static let basePath: String = "FitHubAssets/Images/"
    static let pathMale: String = basePath + "Male/"
    static let pathFemale: String = basePath + "Female/"
    
    static func getImagePath(for asset: AssetPath, isfront: Bool, isBlank: Bool = false, isColored: Bool = false, gender: Gender) -> String {
        var front = "Front/"
        var rear = "Rear/"
        var fullPath: String = ""
        var component: String = ""
        switch asset {
        case .detailedMuscle:
            if isBlank {
                front = "Front_Blank/"
                rear = "Rear_Blank/"
            } else if isColored {
                front = "Front_Colored/"
                rear = "Rear_Colored/"
            }
            component = "Detailed_Muscle/" + (isfront ? front : rear)
            fullPath = combinePath(component: component)
            return fullPath
        case .muscle:
            let component = "Muscle/" + (isfront ? front : rear)
            fullPath = combinePath(component: component)
            return fullPath + (isBlank ? "blank": "")
        case .split:
            let component = "Split/" + (isfront ? front : rear)
            fullPath = combinePath(component: component)
            return fullPath + (isBlank ? "blank": "")
        case .tap:
            let component = "UI/Tap/" + (isfront ? front : rear)
            fullPath = combinePath(component: component)
            return fullPath
        }
        func combinePath(component: String) -> String {
            if gender == .male {
                fullPath = pathMale + component
            } else {
                fullPath = pathFemale + component
            }
            return fullPath
        }
    }
    
    static func getSplitImages(category: SplitCategory, isTarget: Bool = false, gender: Gender) -> [String] {
        let basePathFront = getImagePath(for: .split, isfront: true, gender: gender)
        let basePathRear = getImagePath(for: .split, isfront: false, gender: gender)
        
        let imageName = category.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        var images: [String] = []
        
        if SplitCategory.hasFrontImages.contains(category) {
            images.append(basePathFront + imageName + (isTarget ? "-target" : ""))
        }
        
        if SplitCategory.hasRearImages.contains(category) {
            images.append(basePathRear + imageName + (isTarget ? "-target" : ""))
        }
        return images
    }
    
    /*
    static func getMuscleImages(category: Muscle, gender: Gender) -> [String] {
        let basePathFront = getImagePath(for: .muscle, isfront: true, gender: gender)
        let basePathRear = getImagePath(for: .muscle, isfront: false, gender: gender)
        
        let imageName = category.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        var images: [String] = []
        
        if Muscle.hasFrontImages.contains(category) {
            images.append(basePathFront + imageName)
        }
        
        if Muscle.hasRearImages.contains(category) {
            images.append(basePathRear + imageName)
        }
        return images
    }
    
    static func getDetailedMuscleImages(category: SubMuscles, gender: Gender) -> [String] {
        let basePathFront = getImagePath(for: .detailedMuscle, isfront: true, gender: gender)
        let basePathRear = getImagePath(for: .detailedMuscle, isfront: false, gender: gender)
        
        let imageName = category.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        var images: [String] = []
        
        if SubMuscles.hasFrontImages.contains(category) {
            images.append(basePathFront + imageName)
        }
        
        if SubMuscles.hasRearImages.contains(category) {
            images.append(basePathRear + imageName)
        }
        return images
    }
    
    static func getTapImage(muscle: Muscle, showFrontView: Bool, gender: Gender) -> String? {
        let basePath = getImagePath(for: .tap, isfront: showFrontView, gender: gender)
        
        let imageName = muscle.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        
        if (showFrontView && Muscle.hasFrontImages.contains(muscle)) || (!showFrontView && Muscle.hasRearImages.contains(muscle)) {
            return basePath + imageName
        }
        // Return nil if no valid image exists for the current view
        return nil
    }
    */
}

