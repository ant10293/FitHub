//
//  InitExercise.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import Foundation

// for saving jsons
struct InitExercise: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var aliases: [String]?
    var image: String
    var muscles: [MuscleEngagement]
    var instructions: ExerciseInstructions
    var equipmentRequired: [String]
    var effort: EffortType
    var resistance: ResistanceType
    var csvKey: String?
    var difficulty: StrengthLevel
    var limbMovementType: LimbMovementType?
    var implementCount: Int?
    var repsInstruction: RepsInstruction?
    var weightInstruction: WeightInstruction?
    var imageUrl: String?
}
extension InitExercise {
   init(from ex: Exercise) {
       self.id                   = ex.id
       self.name                 = ex.name
       self.aliases              = ex.aliases
       self.image                = ex.image
       self.muscles              = ex.muscles
       self.instructions         = ex.instructions
       self.resistance           = ex.resistance
       self.equipmentRequired    = ex.equipmentRequired
       self.effort               = ex.effort
       self.csvKey               = ex.csvKey
       self.difficulty           = ex.difficulty
       self.limbMovementType     = ex.limbMovementType
       self.implementCount       = ex.implementCount
       self.repsInstruction      = ex.repsInstruction
       self.weightInstruction    = ex.weightInstruction
       self.imageUrl             = ex.imageUrl
   }
}
