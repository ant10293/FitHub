import SwiftUI


struct EquipmentSelection: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var selectedCategory: EquipmentCategory = .all
    @State private var searchText: String = ""
    @State private var viewDetail = false
    @State private var selectedEquipmentId: UUID?
    @State private var donePressed = false
    @State var selection: [GymEquipment]
    var onDone: ([GymEquipment]) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            EquipmentSelectionContent(
                selectedCategory: $selectedCategory,
                searchText: $searchText,
                isSelected: { ge in isSelected(ge) },
                onToggle: { ge in toggle(ge) },
                onViewDetail: { id in selectedEquipmentId = id; viewDetail = true },
                showSaveBanner: false
            )
            .navigationBarTitle("Select Equipment", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        onDone(selection)
                        donePressed = true
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $viewDetail) {
                if let id = selectedEquipmentId,
                    let equipment = ctx.equipment.equipment(for: id) {
                    EquipmentDetail(
                        equipment: equipment,
                        allExercises: ctx.exercises.allExercises,
                        allEquipment: ctx.equipment.allEquipment
                    )
                } else {
                    Color.clear.onAppear { selectedEquipmentId = nil; viewDetail = false }
                }
            }
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onDisappear { if !donePressed { onDone(selection) } }
    }

    private func isSelected(_ ge: GymEquipment) -> Bool {
        selection.contains(where: { $0.id == ge.id })
    }

    private func toggle(_ ge: GymEquipment) {
        if let idx = selection.firstIndex(where: { $0.id == ge.id }) {
            selection.remove(at: idx)
        } else {
            selection.append(ge)
        }
    }
}
