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
                    title: "\(RoundingCategory.plated.displayName) Equipment",
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .plated)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .plated)
                    }
                )

                RoundingSection(
                    value: $independentPlatedRounding,
                    title: "\(RoundingCategory.platedIndependentPeg.displayName) Equipment",
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .platedIndependentPeg)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .platedIndependentPeg)
                    }
                )

                RoundingSection(
                    value: $pinLoadedRounding,
                    title: "\(RoundingCategory.pinLoaded.displayName) Equipment",
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .pinLoaded)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .pinLoaded)
                    }
                )

                RoundingSection(
                    value: $smallWeightsRounding,
                    title: RoundingCategory.smallWeights.displayName,
                    onUpdate: { newValue in
                        ctx.userData.workoutPrefs.roundingPreference.setRounding(weight: newValue, for: .smallWeights)
                    },
                    onInfoTap: {
                        equipSheet = EquipSheet(category: .smallWeights)
                    }
                )
            }
            .padding(.top)
            .onAppear(perform: initializeVariables)
            .navigationBarTitle("Rounding Preferences", displayMode: .inline)
            .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
            .sheet(item: $equipSheet) { sheet in
                EquipmentPopupView(
                    equipment: ctx.equipment.equipmentForCategory(for: sheet.category),
                    showingCategories: true,
                    title: sheet.category.displayName,
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
            Button(action: onInfoTap) {
                HStack {
                    Text(title)
                        .textCase(.none)
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                }
                .font(.headline)
            }
            .buttonStyle(.plain)
        }
    }
}
