import SwiftUI



struct EquipmentSelection: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var selectedCategory: EquipmentCategory = .all
    @State private var equipToView: GymEquipment? // State to manage selected exercise for detail view
    @State private var showingSaveConfirmation: Bool = false
    @State private var showEquipmentCreation: Bool = false
    @State private var donePressed: Bool = false
    @State private var searchText: String = ""
    @State var selection: [GymEquipment]        // working list
    var forNewExercise: Bool = false
    var onDone: ([GymEquipment]) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            VStack {
                equipmentScrollView
                    .padding(.bottom, -5)
                
                SearchBar(text: $searchText, placeholder: "Search Equipment")
                    .padding(.horizontal)
                
                if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Equipment Saved Successfully!").zIndex(1) }
                
                List {
                    if filteredEquipment.isEmpty {
                        Text("No equipment found.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        Section {
                            ForEach(filteredEquipment, id: \.id) { gymEquip in
                                EquipmentRow(
                                    gymEquip: gymEquip,
                                    equipmentSelected: selection.contains(where: { $0.id == gymEquip.id }),
                                    onEquipmentSelected: { selectedEquip in
                                        self.equipToView = selectedEquip
                                    },
                                    toggleSelection: {
                                        toggleSelection(gymEquip: gymEquip)
                                    }
                                )
                            }
                        } footer: {
                            Text("\(filteredEquipment.count)/\(selectedInFiltered) equipment selected")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle(forNewExercise ? "Select Equipment" : "\(ctx.userData.profile.userName)'s Gym").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if ctx.userData.setup.isEquipmentSelected && !forNewExercise {
                        Button("Save") {
                            ctx.userData.evaluation.equipmentSelected = selection
                            ctx.userData.saveSingleStructToFile(\.evaluation, for: .evaluation)
                            ctx.toast.showSaveConfirmation()
                        }
                    } else if forNewExercise {
                        Button("Done") {
                            onDone(selection)
                            donePressed = true
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
        .navigationDestination(item: $equipToView) { equipment in
            if ctx.equipment.allEquipment.contains(where: { $0.id == equipment.id }) {
                EquipmentDetail(equipment: equipment, allExercises: ctx.exercises.allExercises, allEquipment: ctx.equipment.allEquipment)
            } else {
                Color.clear.onAppear { equipToView = nil }
            }
        }
        .overlay(
            Group {               
                if saveVisible {
                    FloatingButton(image: "checkmark", action: {
                        ctx.userData.evaluation.equipmentSelected = selection
                        ctx.userData.setup.isEquipmentSelected = true
                        ctx.userData.saveToFile()
                    })
                } else if actionVisible {
                    FloatingButton(image: "plus", action: {
                        showEquipmentCreation = true
                    })
                }
            },
            alignment: .bottomTrailing
        )
        .sheet(isPresented: $showEquipmentCreation) { NewEquipment() }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onDisappear(perform: disappearAction)
    }
    
    private func disappearAction() { if forNewExercise && !donePressed { onDone(selection) } }
    
    private var actionVisible: Bool { ctx.userData.setup.isEquipmentSelected && !forNewExercise && !kbd.isVisible }
    
    private var saveVisible: Bool { !ctx.userData.setup.isEquipmentSelected && !forNewExercise && !kbd.isVisible }
    
    private var filteredEquipment: [GymEquipment] {
        // If “All” is selected, pass nil for the category so the helper ignores category filtering.
        let categoryToFilter: EquipmentCategory? = (selectedCategory == .all ? nil : selectedCategory)
        return ctx.equipment.filteredEquipment(searchText: searchText, category: categoryToFilter)
    }
    
    private var selectedInFiltered: Int {
        filteredEquipment.filter { fe in
            selection.contains(where: { $0.id == fe.id })
        }.count
    }
    
    private func toggleSelection(gymEquip: GymEquipment) {
        if let index = selection.firstIndex(where: { $0.id == gymEquip.id }) {
            selection.remove(at: index)
        } else {
            selection.append(gymEquip)
        }
    }
    
    private var equipmentScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 10) {
                ForEach(EquipmentCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .padding(.all, 10)
                        .background(self.selectedCategory == category ? Color.blue : Color(UIColor.lightGray))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            self.selectedCategory = category
                        }
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    struct EquipmentRow: View {
        let gymEquip: GymEquipment
        let equipmentSelected: Bool
        var onEquipmentSelected: (GymEquipment) -> Void // Closure to pass selected equipment
        var toggleSelection: () -> Void // Closure to pass selected equipment
        
        var body: some View {
            HStack {
                ExEquipImage(gymEquip.fullImage, size: 0.2, imageScale: .small)
                .onTapGesture {
                    onEquipmentSelected(gymEquip)
                }
                
                Button {
                    toggleSelection()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(gymEquip.name)
                                .foregroundColor(.primary)
                                .font(.headline)
                                .lineLimit(2)
                                .minimumScaleFactor(0.65)

                            Text(gymEquip.equCategory.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }

                        Spacer()

                        Image(systemName: equipmentSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(equipmentSelected ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)  // stretch row to full width
                    .contentShape(Rectangle())                        // full-row hit test
                }
            }
            .padding(.vertical, 4)
        }
    }
}
