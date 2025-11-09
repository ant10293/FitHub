//
//  WeightIncrementation.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct WeightIncrementation: View {
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var platedRounding: Double = 5
    @State private var independentPlatedRounding: Double = 2.5
    @State private var pinLoadedRounding: Double = 2.5
    @State private var smallWeightsRounding: Double = 5
    @State private var equipSheet: EquipSheet? // nil ⇒ no sheet

    var body: some View {
        VStack(spacing: 30) {
            if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Preferences Saved Successfully!") }
            
            EquipmentRoundingRow(
                value: $platedRounding,
                title: "Plated Equipment",
                onInfoTap: {
                    equipSheet = EquipSheet(category: .plated, categories: [.barsPlates, .platedMachines])
                }
            )

            EquipmentRoundingRow(
                value: $independentPlatedRounding,
                title: "Independent Peg Plated Equipment",
                onInfoTap: {
                    equipSheet = EquipSheet(category: .platedIndependentPeg, categories: [.barsPlates, .platedMachines])
                }
            )

            EquipmentRoundingRow(
                value: $pinLoadedRounding,
                title: "Pin-loaded Equipment",
                onInfoTap: {
                    equipSheet = EquipSheet(category: .pinLoaded, categories: [.weightMachines, .cableMachines])
                }
            )

            EquipmentRoundingRow(
                value: $smallWeightsRounding,
                title: "Small Weights",
                onInfoTap: {
                    equipSheet = EquipSheet(category: .smallWeights, categories: [.smallWeights])
                }
            )
            
            if !ctx.toast.showingSaveConfirmation && !kbd.isVisible {
                RectangularButton(title: "Save", action: saveChanges)
                    .padding(.top)
            }
        }
        .padding(.horizontal)
        .onAppear(perform: initializeVariables)
        .navigationBarTitle("Rounding Preferences", displayMode: .inline)
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .sheet(item: $equipSheet) { sheet in
            EquipmentPopupView(
                selectedEquipment: ctx.equipment.equipmentForCategory(for: sheet.category),
                showingCategories: true,
                title: EquipmentCategory.concatenateEquipCategories(for: sheet.categories),
                onClose: {
                    equipSheet = nil
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { reset() }) {
                    Text("Reset")
                        .foregroundStyle(isDefault ? Color.gray : Color.red)        // make the label red
                        .disabled(isDefault)       // disable when no items
                }
            }
        }
    }
    
    struct EquipSheet: Identifiable {
        let id = UUID()
        let category: RoundingCategory
        let categories: [EquipmentCategory]
    }
        
    private var isDefault: Bool {
        if UnitSystem.current == .imperial {
            platedRounding == 5 && independentPlatedRounding == 2.5 && smallWeightsRounding == 5 && pinLoadedRounding == 2.5
        } else {
            platedRounding == 2.5 && independentPlatedRounding == 1.25 && smallWeightsRounding == 2.5 && pinLoadedRounding == 1.25
        }
    }
    
    private func initializeVariables() {
        platedRounding = ctx.userData.settings.roundingPreference.getRounding(for: .plated)
        independentPlatedRounding = ctx.userData.settings.roundingPreference.getRounding(for: .platedIndependentPeg)
        pinLoadedRounding = ctx.userData.settings.roundingPreference.getRounding(for: .pinLoaded)
        smallWeightsRounding = ctx.userData.settings.roundingPreference.getRounding(for: .smallWeights)
    }
    
    private func reset() {
        let defaultRounding = RoundingPreference()
        platedRounding = defaultRounding.getRounding(for: .plated)
        independentPlatedRounding = defaultRounding.getRounding(for: .platedIndependentPeg)
        pinLoadedRounding = defaultRounding.getRounding(for: .pinLoaded)
        smallWeightsRounding = defaultRounding.getRounding(for: .smallWeights)
        saveChanges()
    }
    
    private func saveChanges() {
        ctx.userData.settings.roundingPreference.setRounding(weight: platedRounding, for: .plated)
        ctx.userData.settings.roundingPreference.setRounding(weight: independentPlatedRounding, for: .platedIndependentPeg)
        ctx.userData.settings.roundingPreference.setRounding(weight: pinLoadedRounding, for: .pinLoaded)
        ctx.userData.settings.roundingPreference.setRounding(weight: smallWeightsRounding, for: .smallWeights)
        
        ctx.toast.showSaveConfirmation()  // Trigger the notification
    }
    
    struct EquipmentRoundingRow: View {
        @Binding var value: Double
        let title: String
        let onInfoTap: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Image(systemName: "info.circle")
                }
                .onTapGesture(perform: onInfoTap)

                TextField("Rounding Increment", value: $value, formatter: formatter)
                    .keyboardType(.decimalPad)
                    .inputStyle()
            }
        }
        
        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 2
            return formatter
        }
    }
}

