
import SwiftUI

struct DetailsView: View {
    @ObservedObject var userData: UserData
    @State private var userName: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender?
    @State private var dob: Date = Date()
    @State private var heightFeet: Int = 0
    @State private var heightInches: Int = 0
    @State private var currentWeight: CGFloat = 80
    @State private var isHeightPickerVisible = false
    @State private var isDatePickerVisible = false
    @State private var isWeightPickerVisible = false
    let heightRange = Array(48...96) // Height range from 4 feet (48 inches) to 8 feet (96 inches)
    let feetRange = 0...8 // Example range for feet
    let inchesRange = 0..<12 // Range for inches
    let weightRange = Array(80...400) // Weight range from 80 to 400 pounds

    init(userData: UserData) {
        self.userData = userData
        _userName = State(initialValue: userData.userName)
        _dob = State(initialValue: userData.dob)
        _currentWeight = State(initialValue: round(userData.currentMeasurementValue(for: .weight)))
        _heightFeet = State(initialValue: userData.heightFeet)
        _heightInches = State(initialValue: userData.heightInches)
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: 30) // Adds a little space at the top, adjust as needed
            Button(action: {
                disableExpanded()
                //This toggles the visibility of the picker
                self.isHeightPickerVisible.toggle()
            }) {
                HStack {
                    Text("Select Height")
                        .font(.headline)
                    Spacer()
                    Text("\(heightFeet) ft \(heightInches) in")
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isHeightPickerVisible ? 90 : 0))
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            if isHeightPickerVisible {
                HStack {
                    Picker("Feet", selection: $heightFeet) {
                        ForEach(feetRange, id: \.self) { feet in
                            Text("\(feet)").tag(feet)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        Text("ft").bold()
                            .foregroundColor(.gray)
                            .offset(x: -65),
                        alignment: .trailing
                    )
                    
                    Picker("Inches", selection: $heightInches) {
                        ForEach(inchesRange, id: \.self) { inches in
                            Text("\(inches)").tag(inches)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        Text("in").bold()
                            .foregroundColor(.gray)
                            .offset(x: -60),
                        alignment: .trailing
                    )
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                .compositingGroup()
                .clipped()
                
                floatingDoneButton(action: {
                    self.isHeightPickerVisible = false
                })
            }
            
            Button(action: {
                disableExpanded()
                // This toggles the visibility of the date picker
                self.isDatePickerVisible.toggle()
            }) {
                HStack {
                    Text("Select DOB")
                        .font(.headline)
                    Spacer()
                    Text("\(dob, formatter: dateFormatter)")
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isDatePickerVisible ? 90 : 0))
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            if isDatePickerVisible {
                DatePicker("", selection: $dob, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .frame(maxHeight: 150)
                    .compositingGroup()
                    .clipped()
                
                floatingDoneButton(action: {
                    self.isDatePickerVisible = false
                })
            }
        }
        
        Button(action: {
            disableExpanded()
            
            self.isWeightPickerVisible.toggle()
        }) {
            HStack {
                Text("Select Weight")
                    .font(.headline)
                Spacer()
                Text("\(Int(currentWeight)) lbs")
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isWeightPickerVisible ? 90 : 0))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        
        if isWeightPickerVisible {
            WeightSelectorView(value: $currentWeight)
                .transition(.slide)
            floatingDoneButton(action: {
                self.isWeightPickerVisible = false
            })
        }
        
        Spacer()
        VStack {
            if (!isDatePickerVisible && !isHeightPickerVisible && !isWeightPickerVisible) {
                Text("Select your Gender")
                    .font(.title2)
                    .padding(.vertical)
                
                HStack {
                    Button(action: {
                        selectedGender = .male
                    }) {
                        GenderSelectionButton(gender: .male, isSelected: selectedGender == .male)
                    }
                    
                    Button(action: {
                        selectedGender = .female
                    }) {
                        GenderSelectionButton(gender: .female, isSelected: selectedGender == .female)
                    }
                }
                Spacer() // Pushes everything to the top
                continueButton // Continue button at the bottom
                Spacer()
            }
        }
        .navigationTitle("Hello \(userName)")
        .navigationBarBackButtonHidden(true)
        /*.onAppear {
            dob = userData.dob
            currentWeight = CGFloat(round(userData.currentMeasurementValue(for: .weight)))
            heightFeet = userData.heightFeet
            heightInches = userData.heightInches
        }*/
    }
    private func disableExpanded() {
        isDatePickerVisible = false
        isHeightPickerVisible = false
        isWeightPickerVisible = false
    }
    
    func floatingDoneButton(action: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button(action: action) {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 10)
            }
            .padding(.top) // Add padding to position the button nicely below the picker
        }
        .padding(.trailing) // Adjust this padding to align with your layout
    }
    
    var continueButton: some View {
        Button(action: {
            if let gender = selectedGender {
                saveUserData(gender: gender)
            }
        }) {
            HStack {
                Spacer()
                Text("Continue")
                    .foregroundColor(.primary) // Ensure the text color remains unchanged
                Spacer()
            }
            .contentShape(Rectangle()) // Make the entire area tappable
            .padding()
            .frame(maxWidth: .infinity)
            .background(canContinue ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .disabled(!canContinue) // Disable button based on whether all conditions are met
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func saveUserData(gender: Gender) {
        let age = calculateAge(from: dob)

        // 1️⃣ Update everything in memory first
        userData.updateMeasurementValue(for: .weight, with: Double(currentWeight), shouldSave: false)
        userData.setupState    = .goalView
        userData.userName      = userName
        userData.heightFeet    = heightFeet
        userData.heightInches  = heightInches
        userData.dob           = dob
        userData.age           = Int(age)
        userData.gender        = gender

        // 2️⃣ Persist _all_ changes together
        userData.saveToFile()
    }
     
    var canContinue: Bool {
        // Ensure a gender is selected
        guard selectedGender != nil else {
            return false
        }
        
        // Check that height is selected and not at some default or invalid value
        // Assuming heightFeet or heightInches being > 0 is a valid selection
        guard heightFeet > 0 || heightInches > 0 else {
            return false
        }
        
        // Check that a weight is selected and not at some default or invalid value
        guard currentWeight > 0 else {
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
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    func calculateAge(from dob: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year ?? 0
    }
}

struct GenderSelectionButton: View {
    let gender: Gender
    var isSelected: Bool // Indicates if the button is selected
    
    var body: some View {
        GenderButtonView(imageName: gender == .male ? "Male" : "Female", isSelected: isSelected, frameWidth: 150)
    }
}

struct GenderButtonView: View {
    let imageName: String
    let isSelected: Bool
    let frameWidth: CGFloat
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: frameWidth, height: frameWidth)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear).clipShape(RoundedRectangle(cornerRadius: 8)) // Change background color if selected
    }
}





