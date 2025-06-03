import SwiftUI


struct EquipmentSelection: View {
    @ObservedObject var userData: UserData
    @ObservedObject var equipmentData: EquipmentData
    @EnvironmentObject var toast: ToastManager 
    @State private var selectedCategory: EquipmentCategory = .all
    @State private var selectedEquipment: GymEquipment? // State to manage selected exercise for detail view
    @State private var showingSaveConfirmation: Bool = false
    @State private var isKeyboardVisible: Bool = false
    @State private var searchText = ""
    
    var filteredEquipment: [GymEquipment] {
        equipmentData.allEquipment.filter { gymEquip in
            (selectedCategory == .all || gymEquip.equCategory == selectedCategory) &&
            (searchText.isEmpty || gymEquip.name.rawValue.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 10) {
                        ForEach(EquipmentCategory.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .padding(.all, 10)
                                .background(self.selectedCategory == category ? Color.blue : Color(UIColor.lightGray))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .onTapGesture {
                                    self.selectedCategory = category
                                }
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.bottom, -5)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search Equipment", text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = "" // Clear the search text
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .frame(alignment: .trailing)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            if toast.showingSaveConfirmation {
                saveConfirmationView
                    .zIndex(1)
            }
            List(filteredEquipment, id: \.id) { gymEquip in
                EquipmentRow(
                    userData: userData,
                    gymEquip: $equipmentData.allEquipment[equipmentData.allEquipment.firstIndex(where: { $0.id == gymEquip.id })!],
                    onEquipmentSelected: { selectedEquip in
                        self.selectedEquipment = selectedEquip // Set selectedEquipment
                    }
                )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Group {
                if !userData.isEquipmentSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: saveEquipment) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .background(Circle().fill(isAnyEquipmentSelected() ? Color.blue : Color.gray))
                            .padding(.vertical)
                            .padding(.trailing, 2.5)
                            .shadow(radius: 10)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedEquipment) { equipment in
            EquipmentDetail(
                equipment: equipment,
                onClose: {
                    self.selectedEquipment = nil
                }
            )
        }
        .navigationTitle("\(userData.userName)'s Gym").navigationBarTitleDisplayMode(.inline)
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
        .toolbar {
            if userData.isEquipmentSelected {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userData.saveSingleVariableToFile(\.equipmentSelected, for: .equipmentSelected)
                        toast.showingSaveConfirmation = true
                       /* showingSaveConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showingSaveConfirmation = false
                        }*/
                    }
                }
            }
        }
    }
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    struct Line: View {
        var body: some View {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
        }
    }
    
    private var saveConfirmationView: some View {
        VStack {
            Text("Equipment Saved Successfully!")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .frame(width: 300, height: 100)
        .background(Color.clear)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale)
    }
    
    func saveEquipment() {
        // Iterate over all equipment to ensure the full selection is considered
        for gymEquip in equipmentData.allEquipment where gymEquip.isSelected {
            if !userData.equipmentSelected.contains(where: { $0.name == gymEquip.name }) {
                userData.equipmentSelected.append(gymEquip)
            }
        }
        userData.isEquipmentSelected = true
        userData.saveToFile()
    }
    
    private func isAnyEquipmentSelected() -> Bool {
        filteredEquipment.contains(where: { $0.isSelected })
    }
    
    // images are rectangular but framed as square causing the corners not to be rounded properly
    // need new images anyways
    struct EquipmentRow: View {
        @ObservedObject var userData: UserData
        @Binding var gymEquip: GymEquipment
        var onEquipmentSelected: (GymEquipment) -> Void // Closure to pass selected equipment
        
        var body: some View {
            HStack {
                HStack {
                    Image(gymEquip.fullImagePath)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6)) // Apply rounded rectangle shape
                    
                    VStack(alignment: .leading) {
                        Text(gymEquip.name.rawValue)
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
                }
                .contentShape(Rectangle()) // Ensure the entire button area is tappable
                .onTapGesture {
                    onEquipmentSelected(gymEquip)
                }
                
                Spacer()
                
                HStack {
                    if userData.isEquipmentSelected {
                        Image(systemName: userData.equipmentSelected.contains(where: { $0.name == gymEquip.name }) ? "checkmark.square.fill" : "square")
                            .contentShape(RoundedRectangle(cornerRadius: 20))
                            .foregroundColor(userData.equipmentSelected.contains(where: { $0.name == gymEquip.name }) ? .blue : .gray)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: gymEquip.isSelected ? "checkmark.square.fill" : "square")
                            .contentShape(RoundedRectangle(cornerRadius: 20))
                            .foregroundColor(gymEquip.isSelected ? .blue : .gray)
                            .frame(width: 40, height: 40)
                    }
                }
                .contentShape(Rectangle()) // Ensure the entire button area is tappable
                .padding(.vertical, 4)
                .onTapGesture(count: 1) {
                    toggleSelection()
                }
            }
            .frame(height: 80)
        }
        private func toggleSelection() {
            if userData.isEquipmentSelected {
                if let index = userData.equipmentSelected.firstIndex(where: { $0.name == gymEquip.name }) {
                    userData.equipmentSelected.remove(at: index)
                    gymEquip.isSelected = false // Update isSelected to reflect changes
                } else {
                    userData.equipmentSelected.append(gymEquip)
                    gymEquip.isSelected = true // Update isSelected to reflect changes
                }
            } else {
                gymEquip.isSelected.toggle()
            }
        }
    }
}
