//
//  Implementation.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/17/25.
//

import Foundation

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

    func getMovementCount(for movementType: LimbMovementType) -> MovementCount {
        switch (self, movementType) {
        // MARK: – Unified
        case (.unified, .bilateralDependent), (.unified, .bilateralIndependent), (.unified, .unilateral):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 1, pegMultiplier: .none)

        // MARK: – Divided
        case (.divided, .bilateralDependent):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 1, pegMultiplier: .none)
        case (.divided, .unilateral):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 1, pegMultiplier: .half)
        case (.divided, .bilateralIndependent):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 2, pegMultiplier: .none)

        // MARK: – Individual
        case (.individual, .bilateralDependent), (.individual, .unilateral):
            return MovementCount(implementsUsed: 1, baseWeightMultiplier: 1, pegMultiplier: .none)
        case (.individual, .bilateralIndependent):
            return MovementCount(implementsUsed: 2, baseWeightMultiplier: 2, pegMultiplier: .none)
        }
    }
}

struct MovementCount: Codable, Equatable, Hashable {
    var implementsUsed: Int            // How many implements are actually used
    var baseWeightMultiplier: Int      // How many times to count the base weight
    var pegMultiplier: PegModifier
}

enum PegModifier: Double, Codable, CaseIterable {
    case none = 1
    case half = 0.5

    var count: Double { rawValue }
}

struct BaseWeight: Codable, Equatable, Hashable {
    // MARK: – Per Implement
    var lb: Double
    var kg: Double
    
    init(lb: Double, kg: Double) {
        self.lb = lb
        self.kg = kg
    }
    
    init(weight: Double) {
        let isImperial = UnitSystem.current == .imperial
        self.lb = isImperial ? weight : UnitSystem.KGtoLB(weight)
        self.kg = isImperial ? UnitSystem.LBtoKG(weight) : weight
    }

    var resolvedMass: Mass {
        switch UnitSystem.current {
        case .imperial: return .init(lb: lb)
        case .metric: return .init(kg: kg)
        }
    }

    mutating func setWeight(_ weight: Double) {
        switch UnitSystem.current {
        case .imperial:
            lb = weight
            kg = UnitSystem.LBtoKG(weight)
        case .metric:
            kg = weight
            lb = UnitSystem.KGtoLB(weight)
        }
    }
}

enum PegCountOption: Int, Codable, CaseIterable {
    case uses  = -1   // equipment uses a peg/receiver, doesn't "load" plates on it
    case none = 0      // No plates loaded
    case single = 1    // Plates loaded on one side
    case both = 2      // Plates loaded on both sides

    var count: Int { rawValue }

    static func getOption(for count: Int) -> PegCountOption {
        switch count {
        case -1: return .uses
        case 0: return .none
        case 1: return .single
        case 2: return .both
        default: return .both
        }
    }

    var label: String {
        switch self {
        case .uses:   return "Uses peg"
        case .none:   return "No plates"
        case .single: return "One side"
        case .both:   return "Both sides"
        }
    }

    var helpText: String {
        switch self {
        case .uses:
            return "This equipment uses a peg or receiver (e.g. landmine/t-bar base). You insert the bar into it."
        case .none:
            return "No plates are loaded. Use this for pin-stack or non-plated equipment."
        case .single:
            return "Plates load on a single peg (one side). Common on some lever machines or t-bar setups."
        case .both:
            return "Plates load on both sides (mirrored pegs). Typical barbell/plate-loaded setups."
        }
    }
}
