
import SwiftUI


struct DetailsView: View {
    @AppStorage(UnitSystem.storageKey) private var unit: UnitSystem = .metric
    @ObservedObject var userData: UserData
    @State private var userName: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender?
    @State private var dob: Date = Date()

    @State private var height: Length
    @State private var weight: Mass
    
    @State private var activePicker: ActivePicker = .none

    init(userData: UserData) {
        self.userData = userData
        _userName = State(initialValue: userData.profile.userName)
        _dob = State(initialValue: userData.profile.dob)
        _height = State(initialValue: userData.physical.height)
        _weight = State(initialValue: Mass(kg: userData.currentMeasurementValue(for: .weight).actualValue))
        _selectedGender = State(initialValue: userData.physical.gender)
    }
    
    var body: some View {
        VStack {
            heightSection
                .padding(.top)
            weightSection
            
            dobSection
            genderSection
            
            Spacer()
            continueButton
            Spacer()
        }
        .navigationTitle("Hello \(userName)")
        .navigationBarBackButtonHidden(true)
    }
    
    private var unitPicker: some View {
        VStack {
            Text(unit.desc)
                .font(.subheadline)
            
            Picker("Unit of Measurement", selection: $unit) {
                ForEach(UnitSystem.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Height
    private var heightSection: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                activePicker = .height
            } label: {
                HStack {
                    Text("Select Height").font(.headline)
                    Spacer()

                    height.heightFormatted
                        .foregroundStyle(.gray)

                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(activePicker == .height ? 90 : 0))
                }
                .padding()
            }
            .contentShape(Rectangle())
            
            // Picker
            if activePicker == .height {
                HeightSelectorRow(height: $height)
                
                floatingDoneButton
                    .padding(.top, 6)
                
                unitPicker
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    // MARK: – Body-weight
    private var weightSection: some View {
        VStack(spacing: 0) {
            Button {
                activePicker = .weight
            } label: {
                HStack {
                    Text("Select Weight").font(.headline)
                    Spacer()
                    
                    weight.formattedText(asInteger: true)
                        .foregroundStyle(.gray)

                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(activePicker == .weight ? 90 : 0))
                }
                .padding()
            }
            .contentShape(Rectangle())
            
            if activePicker == .weight {
                WeightSelectorRow(weight: $weight)
                .padding(.top)

                floatingDoneButton
                    .padding(.top, 6)
                
                unitPicker
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    // MARK: - Date of Birth
    private var dobSection: some View {
        VStack(spacing: 0) {
            Button {
                activePicker = .dob
            } label: {
                HStack {
                    Text("Select DOB").font(.headline)
                    Spacer()
                    Text(Format.formatDate(dob, dateStyle: .long, timeStyle: .none))
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(activePicker == .dob ? 90 : 0))
                }
                .padding()
            }
            .contentShape(Rectangle())
            
            if activePicker == .dob {
                DatePicker("", selection: $dob, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: UIScreen.main.bounds.height * 0.2)
                    .padding(.top)
                
                floatingDoneButton
                    .padding(.vertical, 6)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    private var genderSection: some View {
        VStack {
            if activePicker == .none {
                Text("Select your Gender")
                    .font(.title2)
                    .padding(.vertical)
                
                HStack {
                    Button(action: { selectedGender = .male }) {
                        GenderButton(gender: .male, isSelected: selectedGender == .male)
                    }
                    .padding(.trailing)
                    
                    Button(action: { selectedGender = .female }) {
                        GenderButton(gender: .female, isSelected: selectedGender == .female)
                    }
                    .padding(.leading)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }

    private var floatingDoneButton: some View {
        HStack {
            Spacer()
            FloatingButton(image: "checkmark", action: { activePicker = .none })
                .padding()
        }
    }
    
    private var continueButton: some View {
        ActionButton(title: "Continue", enabled: canContinue, action: {
            if let gender = selectedGender {
                saveUserData(gender: gender)
            }
        })
        .clipShape(Capsule())
        .padding(.horizontal)
    }
    
    private func GenderButton(gender: Gender, isSelected: Bool) -> some View {
        Image(gender == .male ? "Male" : "Female")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.33)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: -5)
                    .fill(Color.blue.opacity(0.4))
            }
        }
    }
    
    private enum ActivePicker { case none, height, dob, weight }
    
    private func saveUserData(gender: Gender) {
        userData.checkAndUpdateAge()
        // 1️⃣ Update everything in memory first
        userData.updateMeasurementValue(for: .weight, with: weight.inKg, shouldSave: false)
        userData.setup.setupState = .goalView
        userData.profile.userName = userName
        userData.profile.dob      = dob
        userData.physical.height  = height
        userData.physical.gender  = gender

        // 2️⃣ Persist _all_ changes together
        userData.saveToFile()
    }
     
    private var canContinue: Bool {
        // Ensure a gender is selected
        guard selectedGender != nil else {
            return false
        }
        
        // Check that height is selected and not at some default or invalid value
        // Assuming heightFeet or heightInches being > 0 is a valid selection

        guard height.displayValue > 0 else {
            return false
        }
        
        
        // Check that a weight is selected and not at some default or invalid value
        guard weight.displayValue > 0 else {
            return false
        }
        
        // Check DOB is selected and not the default value if applicable
        // This is a simplistic check; you might need a more sophisticated check for validity
        guard dob != Date() else {
            return false
        }
        
        // If all conditions are met, return true
        return true
    }
}

