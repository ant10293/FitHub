//
//  Equipment.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//
import Foundation
import SwiftUI


// dumbell, stack, handle, peg, etc

struct GymEquipment: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let aliases: [String]?
    let alternativeEquipment: [String]?
    let image: String
    let equCategory: EquipmentCategory // Ensure this includes a case for "All"
    let adjustments: [AdjustmentCategory]?
    var baseWeight: BaseWeight?
    let pegCount: PegCountOption? // weight pegs
    let implementation: ImplementationType?
    let description: String
}
extension GymEquipment {
    var fullImagePath: String { return "Equipment/\(image)" }
    
    var fullImage: Image { getFullImage(image, fullImagePath) }
    
    var fullImageView: some View {
        fullImage
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    /// Returns the rounding bucket for this piece of equipment.
    var roundingCategory: RoundingCategory? {
        switch equCategory {
        case .platedMachines, .barsPlates:
            return (implementation == .divided || pegCount == .single) ? .platedIndependentPeg : .plated
        case .weightMachines, .cableMachines:
            return .pinLoaded
        case .smallWeights:
            return .smallWeights
        default:
            return nil
        }
    }
    
    static var defaultEquipment: GymEquipment {
        return .init(
            id: UUID(),
            name: "",
            aliases: nil,
            alternativeEquipment: nil,
            image: "",
            equCategory: .all,
            adjustments: nil,
            pegCount: nil,
            implementation: nil,
            description: ""
        )
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
        self.pegCount             = initEquip.pegCount
        self.implementation       = initEquip.implementation
        self.description          = initEquip.description
    }
}

enum EquipmentCategory: String, CaseIterable, Identifiable, Codable {
    case all = "All Equipment"
    case smallWeights = "Small Weights" // dumbbells
    case barsPlates = "Bars & Plates"
    case benchesRacks = "Benches & Racks"
    case cableMachines = "Cable Machines"
    case platedMachines = "Plated Machines"
    case weightMachines = "Weight Machines"
    case resistanceBands = "Resistance Bands"
    case householdItems = "Household Items"
    case cardioMachines = "Cardio Machines"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    // Function to concatenate EquipmentCategory names
    static func concatenateEquipCategories(for categories: [EquipmentCategory]) -> String {
        return categories.map { $0.rawValue }.joined(separator: ", ")
    }
    
    static let machineCats: Set<EquipmentCategory> = [.platedMachines, .weightMachines, .cableMachines, .cardioMachines]
    static let freeWeightCats: Set<EquipmentCategory> = [.smallWeights, .barsPlates]
    static let platedCats: Set<EquipmentCategory> = [.platedMachines, .smallWeights, .barsPlates]
}


