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

    @State private var selectedCategory: EquipmentCategory = .all
    @State private var searchText: String = ""
    @State private var viewDetail: Bool = false
    @State private var showEquipmentCreation: Bool = false
    @State private var selectedEquipmentId: UUID?

    var body: some View {
        EquipmentSelectionContent(
            selectedCategory: $selectedCategory,
            searchText: $searchText,
            isSelected: { ge in ctx.userData.evaluation.availableEquipment.contains(ge.id) },
            onToggle: { ge in toggle(ge) },
            onViewDetail: { id in selectedEquipmentId = id; viewDetail = true },
            showSaveBanner: ctx.toast.showingSaveConfirmation
        )
        .navigationBarTitle("\(ctx.userData.profile.userName)'s Gym", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if ctx.userData.setup.isEquipmentSelected {
                    Button("Save") {
                        ctx.userData.saveToFile()
                        ctx.toast.showSaveConfirmation()
                    }
                }
            }
        }
        .sheet(isPresented: $showEquipmentCreation) { NewEquipment() }
        .navigationDestination(isPresented: $viewDetail) {
            if let id = selectedEquipmentId,
               let equipment = ctx.equipment.equipment(for: id) {
                EquipmentDetail(equipment: equipment,
                                alternative: ctx.equipment.alternativesFor(equipment: Array(arrayLiteral: equipment)),
                                allExercises: ctx.exercises.allExercises,
                                allEquipment: ctx.equipment.allEquipment)
            } else {
                Color.clear.onAppear { selectedEquipmentId = nil; viewDetail = false }
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

