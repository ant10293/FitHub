//
//  EquipmentManagement.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/22/25.
//

import SwiftUI

struct EquipmentManagement: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @StateObject private var toast = ToastManager()
    @State private var selectedCategory: EquipmentCategory = .all
    @State private var searchText: String = ""
    @State private var showEquipmentCreation: Bool = false
    @State private var selectedEquipmentId: UUID?
    @State private var showDetail: Bool = false
    @State private var showImplements: Bool = false

    var body: some View {
        EquipmentSelectionContent(
            selectedCategory: $selectedCategory,
            searchText: $searchText,
            isSelected: { ge in ctx.userData.evaluation.availableEquipment.contains(ge.id) },
            onToggle: { ge in toggle(ge) },
            onViewDetail: { id in
                selectedEquipmentId = id
                showDetail = true
            },
            onViewImplements: { id in
                selectedEquipmentId = id
                showImplements = true
            },
            subtitleType: .both,
            showSaveBanner: toast.showingSaveConfirmation
        )
        .navigationBarTitle("\(ctx.userData.profile.firstName)'s Gym", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if ctx.userData.setup.isEquipmentSelected {
                    Button("Save") {
                        ctx.userData.saveToFile()
                        toast.showSaveConfirmation()
                    }
                }
            }
        }
        .sheet(isPresented: $showEquipmentCreation) { NewEquipment() }
        .navigationDestination(isPresented: $showDetail) {
            if let equipment = selectedEquipment {
                EquipmentDetail(
                    equipment: equipment,
                    alternative: ctx.equipment.alternativesFor(equipment: [equipment]),
                    allExercises: ctx.exercises.allExercises,
                    allEquipment: ctx.equipment.allEquipment
                )
            } else {
                closeView
            }
        }
        .navigationDestination(isPresented: $showImplements) {
            if let equipment = selectedEquipment {
                EquipmentImplements(
                    equipment: equipment,
                    onImplementsChange: { newImplements in
                        if newImplements != equipment.availableImplements {
                            var updated = equipment
                            updated.availableImplements = newImplements
                            ctx.equipment.updateEquipment(equipment: updated)
                        }
                    }
                )
            } else {
                closeView
            }
        }
        .overlay(
            Group {
                if saveVisible {
                    FloatingButton(image: "checkmark") {
                        // First-time setup: persist and mark complete
                        ctx.userData.setup.isEquipmentSelected = true
                        ctx.userData.saveToFile()
                    }
                } else if actionVisible {
                    FloatingButton(image: "plus") {
                        showEquipmentCreation = true
                    }
                }
            },
            alignment: .bottomTrailing
        )
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }
    
    private var closeView: some View {
        Color.clear.onAppear {
            showDetail = false
            showImplements = false
            selectedEquipmentId = nil
        }
    }
    
    private var selectedEquipment: GymEquipment? {
        guard let id = selectedEquipmentId, let equipment = ctx.equipment.equipment(for: id) else { return nil }
        return equipment
    }

    private func toggle(_ ge: GymEquipment) {
        if ctx.userData.evaluation.availableEquipment.contains(ge.id) {
            ctx.userData.evaluation.availableEquipment.remove(ge.id)
        } else {
            ctx.userData.evaluation.availableEquipment.insert(ge.id)
        }
    }

    private var actionVisible: Bool {
        ctx.userData.setup.isEquipmentSelected && !kbd.isVisible
    }

    private var saveVisible: Bool {
        !ctx.userData.setup.isEquipmentSelected && !kbd.isVisible
    }
}

