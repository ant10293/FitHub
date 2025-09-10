//
//  Equipment.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//
import Foundation
import SwiftUI


struct InitEquipment: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var aliases: [String]?
    var alternativeEquipment: [String]?
    var image: String
    var equCategory: EquipmentCategory // Ensure this includes a case for "All"
    var adjustments: [AdjustmentCategory]?
    var baseWeight: BaseWeight?
    var pegCount: PegCountOption?
    var implementation: ImplementationType?
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
        self.pegCount             = equip.pegCount
        self.implementation       = equip.implementation
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
            let pegs = pegCount?.count ?? 0
            return pegs == 1 ? .platedSinglePeg : .plated
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
        self.pegCount             = initEquip.pegCount
        self.implementation       = initEquip.implementation
        self.description          = initEquip.description
    }
}

enum PegCountOption: Int, Codable, CaseIterable {
    case none = 0      // No plates loaded
    case single = 1    // Plates loaded on one side
    case both = 2      // Plates loaded on both sides

    var count: Int { rawValue }

    var label: String {
        switch self {
        case .none:   return "No plates"
        case .single: return "One side"
        case .both:   return "Both sides"
        }
    }
    
    var helpText: String {
        switch self {
        case .none:
            return "No plates are loaded. Use this for pin-stack or non-plated equipment."
        case .single:
            return "Plates load on a single peg (one side). Common on some lever machines or t-bar setups."
        case .both:
            return "Plates load on both sides (mirrored pegs). Typical barbell/plate-loaded setups."
        }
    }
}

// should impact WeightPlates
struct RoundingPreference: Codable, Equatable {
    var lb: Rounding = Rounding(
        plated: Mass(lb: 5),
        platedSinglePeg: Mass(lb: 2.5),
        pinLoaded: Mass(lb: 2.5),
        smallWeights: Mass(lb: 5)
    )
    var kg: Rounding = Rounding(
        plated: Mass(kg: 2.5),
        platedSinglePeg: Mass(kg: 1.25),
        pinLoaded: Mass(kg: 1.25),
        smallWeights: Mass(kg: 2.5)
    )
}

struct Rounding: Codable, Equatable {
    var plated: Mass
    var platedSinglePeg: Mass
    var pinLoaded: Mass
    var smallWeights: Mass
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

enum ImplementationType: String, Codable, Hashable, CaseIterable {
    case unified = "Unified"         // One implement, shared load (barbell, pin-loaded machines)
    case divided = "Divided"         // One implement, load divided per limb (lever machines)
    case individual = "Individual"   // Individual implements per limb (dumbbells, kettlebells)
    
    var helpText: String {
        switch self {
        case .unified:
            return "One implement with shared load. Both limbs work together on the same implement (barbell, pin-loaded machines)."
        case .divided:
            return "One implement with load divided per limb. Each limb has its own handle/arm on the same machine (lever machines)."
        case .individual:
            return "Individual implements per limb. Each limb works with its own separate implement (dumbbells, kettlebells)."
        }
    }
    
    func movementCount(for movementType: LimbMovementType) -> MovementCount {
        switch (self, movementType) {
        // MARK: – Unified
        case (.unified, .bilateralDependent), (.unified, .bilateralIndependent), (.unified, .unilateral):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 1)
        
        // MARK: – Divided
        case (.divided, .bilateralDependent), (.divided, .unilateral):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 1)
        case (.divided, .bilateralIndependent):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 2)
            
        // MARK: – Individual
        case (.individual, .bilateralDependent), (.individual, .unilateral):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 1)
        case (.individual, .bilateralIndependent):
            return MovementCount(implementsUsed: 2, baseWeightMultiplier: 2)
        }
    }
}

struct MovementCount: Codable, Equatable, Hashable {
    var implementsUsed: Int            // How many implements are actually used
    var baseWeightMultiplier: Int      // How many times to count the base weight
}

struct BaseWeight: Codable, Equatable, Hashable {
    // MARK: – Per Implement
    var lb: Double
    var kg: Double
    
    var resolvedMass: Mass {
        switch UnitSystem.current {
        case .imperial: return .init(lb: lb)
        case .metric: return .init(kg: kg)
        }
    }
    
    mutating func setWeight(_ weight: Double) {
        switch UnitSystem.current {
        case .imperial: lb = weight
        case .metric: kg = weight
        }
    }
}

// should impact RoundingPreference
// TODO: Add sorting here
struct WeightPlates: Hashable, Codable {
    // default options (lb, kg)
    var lb: [Mass] = .init(WeightPlates.defaultLbPlates)
    var kg: [Mass] = .init(WeightPlates.defaultKgPlates)
    
    var resolvedPlates: [Mass] {
        switch UnitSystem.current {
        case .imperial: return lb
        case .metric: return kg
        }
    }
    
    /// Fixed color palette by index (shared across lb + kg)
    private static let plateColors: [Color] = [
        .gray,    // index 0 (2.5 lb / 1.25 kg)
        .orange,   // index 1 (5 lb / 2.5 kg)
        .purple,   // index 2 (10 lb / 5 kg)
        .green,   // index 3 (25 lb / 10 kg)
        .yellow,  // index 4 (35 lb / 15 kg)
        .blue,    // index 5 (45 lb / 20 kg)
        .red      // index 6 (100 lb / 25 kg)
    ]
     
     /// Get the fixed color for a given plate
    static func color(for mass: Mass, in plates: [Mass]) -> Color {
        if let idx = plates.firstIndex(of: mass), idx < plateColors.count {
            return plateColors[idx]
        }
        return .secondary
    }
    
    static func defaultOptions() -> [Mass] {
        UnitSystem.current == .imperial ?
        defaultLbPlates
        : defaultKgPlates
    }
    
    private static let defaultLbPlates: [Mass] = [
        Mass(lb: 2.5), Mass(lb: 5), Mass(lb: 10), Mass(lb: 25), Mass(lb: 45)
    ]
    
    private static let defaultKgPlates: [Mass] = [
        Mass(kg: 1.25), Mass(kg: 2.5), Mass(kg: 5), Mass(kg: 10), Mass(kg: 15), Mass(kg: 20), Mass(kg: 25)
    ]
    
    static func allOptions() -> [Mass] {
        UnitSystem.current == .imperial ?
        allLbPlates
        : allKgPlates
    }
    
    private static let allLbPlates: [Mass] = [
        Mass(lb: 2.5), Mass(lb: 5), Mass(lb: 10), Mass(lb: 25), Mass(lb: 35), Mass(lb: 45), Mass(lb: 100)
    ]
    
    private static let allKgPlates: [Mass] = [
        Mass(kg: 1.25), Mass(kg: 2.5), Mass(kg: 5), Mass(kg: 10), Mass(kg: 15), Mass(kg: 20), Mass(kg: 25)
    ]
    
    mutating func setPlates(_ plates: [Mass]) {
        switch UnitSystem.current {
        case .imperial: self.lb = plates
        case .metric: self.kg = plates
        }
    }
}
