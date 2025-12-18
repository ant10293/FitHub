//
//  InitEquipment.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/17/25.
//

import Foundation

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
    var weightInstruction: WeightInstruction?
    var description: String
    var availableImplements: Implements?
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
        self.weightInstruction    = equip.weightInstruction
        self.description          = equip.description
        self.availableImplements  = equip.availableImplements
    }
}
