
import SwiftUI


struct DetailsView: View {
    @AppStorage(UnitSystem.storageKey) private var unit: UnitSystem = .metric
    @ObservedObject var userData: UserData
    @State private var selectedGender: Gender?
    @State private var dob: Date = Date()
    @State private var height: Length
    @State private var weight: Mass
    @State private var activePicker: ActivePicker = .none

    init(userData: UserData) {
        self.userData = userData
        _dob = State(initialValue: userData.profile.dob ?? Date())
        _height = State(initialValue: userData.physical.height)
        _weight = State(initialValue: Mass(kg: userData.currentMeasurementValue(for: .weight).actualValue))
        _selectedGender = State(initialValue: userData.physical.gender)
    }
    
    var body: some View {
        VStack {
            heightCard
            weightCard
            dobCard
            genderSection
                
            Spacer()
            continueButton
            Spacer()
        }
        .padding(.top)
        .navigationTitle("Hello \(userData.profile.firstName)")
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
        }
    }
    
    // MARK: - Height
    private var heightCard: some View {
        MeasurementCard(
            title: "Select Height",
            isActive: activePicker == .height,
            onTap: { toggle(.height) },
            onClose: closePicker,
            valueView: {
                height.heightFormatted
                    .foregroundStyle(.gray)
            },
            content: {
                HeightSelectorRow(height: $height)
            },
            extraView: {
                unitPicker
            }
        )
    }

    // MARK: – Body-weight
    private var weightCard: some View {
        MeasurementCard(
            title: "Select Weight",
            isActive: activePicker == .weight,
            onTap: { toggle(.weight) },
            onClose: closePicker,
            valueView: {
                weight.formattedText(asInteger: true)
                    .foregroundStyle(.gray)
            },
            content: {
                WeightSelectorRow(weight: $weight)
            },
            extraView: {
                unitPicker
            }
        )
    }

    // MARK: - Date of Birth
    private var dobCard: some View {
        MeasurementCard(
            title: "Select DOB",
            isActive: activePicker == .dob,
            onTap: { toggle(.dob) },
            onClose: closePicker,
            valueView: {
                Text(Format.formatDate(dob, dateStyle: .long, timeStyle: .none))
            },
            content: {
                DatePicker("", selection: $dob, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: screenHeight * 0.2)
            }
        )
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

    private var continueButton: some View {
        RectangularButton(title: "Continue", enabled: canContinue, action: {
            saveUserData()
        })
        .clipShape(Capsule())
        .padding(.horizontal)
    }
    
    private func GenderButton(gender: Gender, isSelected: Bool) -> some View {
        Image(gender == .male ? "Male" : "Female")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: screenWidth * 0.33)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: -5)
                    .fill(Color.blue.opacity(0.4))
            }
        }
    }

    private func toggle(_ picker: ActivePicker) {
        activePicker = activePicker == picker ? .none : picker
    }
    
    private func closePicker() { activePicker = .none }
    
    private enum ActivePicker { case none, height, dob, weight }
    
    private func saveUserData() {
        userData.checkAndUpdateAge()
        // 1️⃣ Update everything in memory first
        userData.updateMeasurementValue(for: .weight, with: weight.inKg)
        userData.setup.setupState = .goalView
        userData.profile.dob      = dob
        userData.physical.height  = height
        if let gender = selectedGender {
            userData.physical.gender = gender
        }
        
        userData.saveToFile()
    }
     
    private var canContinue: Bool {
        // Ensure a gender is selected
        guard let gender = selectedGender, gender != .notSet else {
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
        guard !CalendarUtility.shared.isDate(dob, inSameDayAs: Date()) else {
            return false
        }
        
        // If all conditions are met, return true
        return true
    }
}

