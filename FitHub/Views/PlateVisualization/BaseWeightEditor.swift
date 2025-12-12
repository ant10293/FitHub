//
//  BaseWeightEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/1/25.
//

import SwiftUI

struct BaseWeightEditor: View {
    let exercise: Exercise
    let gymEquip: GymEquipment
    var onSave: (Double) -> Void
    var onExit: () -> Void

    var body: some View {
        GenericEditor(
            title: "Set Base Weight for \(gymEquip.name)",
            placeholder: "Enter weight (\(UnitSystem.current.weightUnit))",
            initialValue: gymEquip.baseWeight?.resolvedMass.displayString ?? "",
            onSave: onSave,
            onExit: onExit
        )
    }
}
