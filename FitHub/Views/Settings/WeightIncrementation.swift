//
//  WeightIncrementation.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct WeightIncrementation: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var kbd = KeyboardManager.shared
    @State private var platedRounding: Mass = .init(kg: 0)
    @State private var independentPlatedRounding: Mass = .init(kg: 0)
    @State private var pinLoadedRounding: Mass = .init(kg: 0)
    @State private var smallWeightsRounding: Mass = .init(kg: 0)
    @State private var equipSheet: EquipSheet? // nil ⇒ no sheet

    var body: some View {
        NavigationStack {
            Form {
                RoundingSection(
                    value: $platedRounding,
                    title: "Plated Equipment",
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .plated)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .plated, categories: [.barsPlates, .platedMachines])
                    }
                )

                RoundingSection(
                    value: $independentPlatedRounding,
                    title: "Independent Peg Plated Equipment",
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .platedIndependentPeg)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .platedIndependentPeg, categories: [.barsPlates, .platedMachines])
                    }
                )

                RoundingSection(
                    value: $pinLoadedRounding,
                    title: "Pin-loaded Equipment",
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .pinLoaded)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .pinLoaded, categories: [.weightMachines, .cableMachines])
                    }
                )

                RoundingSection(
                    value: $smallWeightsRounding,
                    title: "Small Weights",
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .smallWeights)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .smallWeights, categories: [.smallWeights])
                    }
                )
            }
            .padding(.top)
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
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    struct EquipSheet: Identifiable {
        let id = UUID()
        let category: RoundingCategory
        let categories: [EquipmentCategory]
    }
    
    private func initializeVariables() {
        let rounding = ctx.userData.workoutPrefs.roundingPreference
        platedRounding.set(rounding.getRounding(for: .plated))
        independentPlatedRounding.set(rounding.getRounding(for: .platedIndependentPeg))
        pinLoadedRounding.set(rounding.getRounding(for: .pinLoaded))
        smallWeightsRounding.set(rounding.getRounding(for: .smallWeights))
    }
}

private struct RoundingSection: View {
    @FocusState private var isFocused: Bool
    @Binding var value: Mass
    let title: String
    let onUpdate: (Double) -> Void
    let onInfoTap: () -> Void
    
    var body: some View {
        Section {
            TextField("Rounding Increment", text: $value.asText())
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        onUpdate(value.displayValue)
                    }
                }
        } header: {
            HStack {
                Text(title)
                    .textCase(.none)
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .font(.headline)
        }
    }
}
