//
//  Equipment.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//
import Foundation
import SwiftUI


struct InitEquipment: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var aliases: [String]?
    var alternativeEquipment: [String]?
    var image: String
    var equCategory: EquipmentCategory // Ensure this includes a case for "All"
    var adjustments: [AdjustmentCategory]?
    var baseWeight: Int?
    var singlePeg: Bool?
    var description: String
}
extension InitEquipment {
    /// Convenience init that copies matching properties from a GymEquipment.
    init(from equip: GymEquipment) {
        self.id                   = equip.id
        self.name                 = equip.name
        self.aliases              = equip.aliases
        self.alternativeEquipment = equip.alternativeEquipment
        self.image                = equip.image
        self.equCategory          = equip.equCategory
        self.adjustments          = equip.adjustments
        self.baseWeight           = equip.baseWeight
        self.singlePeg            = equip.singlePeg
        self.description          = equip.description
    }
}


struct GymEquipment: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let aliases: [String]?
    let alternativeEquipment: [String]?
    let image: String
    let equCategory: EquipmentCategory // Ensure this includes a case for "All"
    let adjustments: [AdjustmentCategory]?
    let baseWeight: Int?
    let singlePeg: Bool?
    let description: String
}
extension GymEquipment {
    var fullImagePath: String { return "Equipment/\(image)" }
    
    var fullImage: Image { getFullImage(image, fullImagePath) }
    
    /// Returns the rounding bucket for this piece of equipment.
    var roundingCategory: RoundingCategory? {
        switch equCategory {
        case .platedMachines, .barsPlates:
            return singlePeg == true ? .platedSinglePeg : .plated
        case .weightMachines, .cableMachines:
            return .pinLoaded
        case .smallWeights:
            return .smallWeights
        default:
            return nil
        }
    }
}
extension GymEquipment {
    /// Convenience initialiser that copies everything static
    /// and leaves the live-session fields at their defaults.
    init(from initEquip: InitEquipment) {
        self.id                   = initEquip.id
        self.name                 = initEquip.name
        self.aliases              = initEquip.aliases
        self.alternativeEquipment = initEquip.alternativeEquipment
        self.image                = initEquip.image
        self.equCategory          = initEquip.equCategory
        self.adjustments          = initEquip.adjustments
        self.baseWeight           = initEquip.baseWeight
        self.singlePeg            = initEquip.singlePeg
        self.description          = initEquip.description
        // everything else already has a default
    }
}

struct RoundingPreference: Codable, Equatable {
    var plated: Double = 5
    var platedSinglePeg : Double = 2.5
    var pinLoaded: Double = 2.5
    var smallWeights: Double = 5
}

enum RoundingCategory: String, Codable, Equatable {
    case plated = "Plated"
    case platedSinglePeg = "Plated Single Peg"
    case pinLoaded = "Pin Loaded"
    case smallWeights = "Small Weights"
}

enum EquipmentCategory: String, CaseIterable, Identifiable, Codable {
    case all = "All Equipment"
    case smallWeights = "Small Weights" // dumbbells
    case barsPlates = "Bars & Plates"
    case benchesRacks = "Benches & Racks"
    case cableMachines = "Cable Machines" //
    case platedMachines = "Plated Machines" //
    case weightMachines = "Weight Machines" //
    case resistanceBands = "Resistance Bands"
    case householdItems = "Household Items"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    // Function to concatenate EquipmentCategory names
    static func concatenateEquipCategories(for categories: [EquipmentCategory]) -> String {
        return categories.map { $0.rawValue }.joined(separator: ", ")
    }
    
    static let machineCats: Set<EquipmentCategory> = [.platedMachines, .weightMachines, .cableMachines]
    static let freeWeightCats: Set<EquipmentCategory> = [.smallWeights, .barsPlates]
    static let baseWeightCats: Set<EquipmentCategory> = [.barsPlates, .cableMachines, .platedMachines, .weightMachines, .other]
}
