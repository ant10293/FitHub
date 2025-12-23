//
//  EquipmentPopUp.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EquipmentPopupView: View {
    @EnvironmentObject var ctx: AppContext
    @State private var showImplements: Bool = false
    @State private var selectedEquipment: GymEquipment?
    let equipment: [GymEquipment]
    var showingCategories: Bool = false
    var title: String = "Your Equipment"
    var onClose: () -> Void
    var onContinue: () -> Void = {}
    var onEdit: () -> Void = {}

    var body: some View {
        NavigationStack {
            VStack {
                // Filter and list only selected equipment
                VStack(spacing: 0) {
                    EquipmentList
                    if !showingCategories {
                        Divider()
                    }
                }
                if !showingCategories {
                    RectangularButton(title: "Save and Continue", width: .fit, action: onContinue)
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                }
                if !showingCategories {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { onEdit() }
                    }
                }
            }
            .navigationDestination(isPresented: $showImplements) {
                if let selected = selectedEquipment {
                    EquipmentImplements(
                        equipment: selected,
                        onImplementsChange: { newImplements in
                            if newImplements != selected.availableImplements {
                                var updated = selected
                                updated.availableImplements = newImplements
                                ctx.equipment.updateEquipment(equipment: updated)
                            }
                        }
                    )
                } else {
                    Color.clear.onAppear {
                        showImplements = false
                        selectedEquipment = nil
                    }
                }
            }
        }
    }

    private var EquipmentList: some View {
        List {
            Section {
                ForEach(equipment, id: \.id) { gymEquip in
                    equipmentRow(for: gymEquip)
                }
            } header: {
                if showingCategories, equipment.contains(where: { $0.availableImplements != nil }) {
                    Text("Checked: Use general rounding preferences\nUnchecked: Round to nearest available weight")
                        .font(.caption)
                        .textCase(.none)
                }
            }
        }
    }
    
    @ViewBuilder
    private func equipmentRow(for gymEquip: GymEquipment) -> some View {
        let available = gymEquip.availableImplements

        EquipmentRow(
            gymEquip: gymEquip,
            equipmentSelected: available?.shouldUseGeneralRounding ?? true,
            subtitle: showingCategories ? .implements : .none,
            viewImplements: {
                guard showingCategories else { return }
                selectedEquipment = gymEquip
                showImplements = true
            },
            toggleSelection: {
                guard let available, showingCategories else { return }
                var equip = gymEquip
                if available.shouldUseGeneralRounding {
                    equip.availableImplements?.useGeneralRounding = false
                } else {
                    equip.availableImplements?.useGeneralRounding = true
                }
                ctx.equipment.updateEquipment(equipment: equip)
            },
            size: 0.15,
            buttonOption: .none,
            showCheckbox: available != nil && showingCategories
        )
    }
}
