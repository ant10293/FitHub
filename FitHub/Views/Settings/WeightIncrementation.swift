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
    @State private var singlePegPlatedRounding: Double = 2.5
    @State private var pinLoadedRounding: Double = 2.5
    @State private var smallWeightsRounding: Double = 5
    @State private var equipSheet: EquipSheet? // nil ⇒ no sheet

    var body: some View {
        VStack(spacing: 30) {
            if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Preferences Saved Successfully!") }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Plated Equipment")
                            .font(.headline)
                            .padding(.leading)
                        Image(systemName: "info.circle")
                        
                    }
                    .onTapGesture {
                        equipSheet = EquipSheet(category: .plated, categories: [.barsPlates, .platedMachines])
                    }
                    
                    TextField("Rounding Increment", value: $platedRounding, formatter: decimalFormatter)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Single Peg Plated Equipment")
                            .font(.headline)
                            .padding(.leading)
                        Image(systemName: "info.circle")
                        
                    }
                    .onTapGesture {
                        equipSheet = EquipSheet(category: .platedSinglePeg, categories: [.barsPlates, .platedMachines])
                    }
                    
                    TextField("Rounding Increment", value: $singlePegPlatedRounding, formatter: decimalFormatter)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pin-loaded Equipment")
                            .font(.headline)
                            .padding(.leading)
                        Image(systemName: "info.circle")
                    }
                    .onTapGesture {
                        equipSheet = EquipSheet(category: .pinLoaded, categories: [.weightMachines, .cableMachines])
                    }
                    
                    TextField("Rounding Increment", value: $pinLoadedRounding, formatter: decimalFormatter)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Small Weights")
                            .font(.headline)
                            .padding(.leading)
                        Image(systemName: "info.circle")
                    }
                    .onTapGesture {
                        equipSheet = EquipSheet(category: .smallWeights, categories: [.smallWeights])
                    }
                    
                    TextField("Rounding Increment", value: $smallWeightsRounding, formatter: decimalFormatter)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
            }
            
            if !ctx.toast.showingSaveConfirmation && !kbd.isVisible {
                Button(action: saveChanges) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.vertical)
                }
                .padding(.horizontal)
            }
        }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { reset() }) {
                    Text("Reset")
                        .foregroundColor(isDefault ? Color.gray : Color.red)        // make the label red
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
    
    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private var isDefault: Bool {
        platedRounding == 5 && singlePegPlatedRounding == 2.5 && smallWeightsRounding == 5 && pinLoadedRounding == 2.5
    }
    
    private func initializeVariables() {
        platedRounding = ctx.userData.settings.roundingPreference.plated
        singlePegPlatedRounding = ctx.userData.settings.roundingPreference.platedSinglePeg
        pinLoadedRounding = ctx.userData.settings.roundingPreference.pinLoaded
        smallWeightsRounding = ctx.userData.settings.roundingPreference.smallWeights
    }
    
    private func reset() {
        platedRounding = 5
        singlePegPlatedRounding = 2.5
        pinLoadedRounding = 2.5
        smallWeightsRounding = 5
        saveChanges()
    }
    
    private func saveChanges() {        
        ctx.userData.settings.roundingPreference.plated = platedRounding
        ctx.userData.settings.roundingPreference.platedSinglePeg = singlePegPlatedRounding
        ctx.userData.settings.roundingPreference.pinLoaded = pinLoadedRounding
        ctx.userData.settings.roundingPreference.smallWeights = smallWeightsRounding
        
        ctx.userData.saveSingleStructToFile(\.settings, for: .settings)
        ctx.toast.showSaveConfirmation()  // Trigger the notification
    }
}
