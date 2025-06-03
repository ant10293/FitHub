//
//  WeightIncrementation.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct WeightIncrementation: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var equipmentData: EquipmentData
    @State private var platedRounding: Double
    @State private var pinLoadedRounding: Double
    @State private var smallWeightsRounding: Double
    @State private var isKeyboardVisible: Bool = false
    @State private var isShowingEquipmentList = false
    @State private var selectedEquipment: [EquipmentCategory]?
    
    // Initialize the state variables with the userData values
    init(userData: UserData) {
        self.userData = userData
        _platedRounding = State(initialValue: userData.roundingPreference[.platedMachines] ?? 5.0)
        _pinLoadedRounding = State(initialValue: userData.roundingPreference[.weightMachines] ?? 2.5)
        _smallWeightsRounding = State(initialValue: userData.roundingPreference[.smallWeights] ?? 5.0)
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                if toastManager.showingSaveConfirmation {
                    saveConfirmationView
                    //.zIndex(1)  // Ensures the overlay is above all other content
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            //  Text("Plated Exercises")
                            Text("Plated Equipment")
                                .font(.headline)
                                .padding(.leading)
                            //  Spacer()
                            Image(systemName: "info.circle")
                            
                        }
                        .onTapGesture {
                            if selectedEquipment == nil {
                                selectedEquipment = []
                            }
                            selectedEquipment?.append(contentsOf: [.barsPlates, .platedMachines])
                            isShowingEquipmentList.toggle()
                            
                        }
                        
                        TextField("Rounding Increment", value: $platedRounding, formatter: decimalFormatter)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Text("Pin-loaded Exercises")
                            Text("Pin-loaded Equipment")
                                .font(.headline)
                                .padding(.leading)
                            Image(systemName: "info.circle")
                        }
                        .onTapGesture {
                            if selectedEquipment == nil {
                                selectedEquipment = []
                            }
                            selectedEquipment?.append(contentsOf: [.weightMachines, .cableMachines])
                            isShowingEquipmentList.toggle()
                            
                        }
                        
                        TextField("Rounding Increment", value: $pinLoadedRounding, formatter: decimalFormatter)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Text("Small Weight Exercises")
                            Text("Small Weights")
                                .font(.headline)
                                .padding(.leading)
                            Image(systemName: "info.circle")
                        }
                        .onTapGesture {
                            if selectedEquipment == nil {
                                selectedEquipment = []
                            }
                            selectedEquipment?.append(contentsOf: [.smallWeights])
                            isShowingEquipmentList.toggle()
                        }
                        
                        TextField("Rounding Increment", value: $smallWeightsRounding, formatter: decimalFormatter)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                
                if !toastManager.showingSaveConfirmation && !isKeyboardVisible {
                    Button(action: saveChanges) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.vertical)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Rounding Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            Group {
                if isShowingEquipmentList, let equipment = selectedEquipment {
                    let equipmentForCategories = equipmentData.equipmentForCategories(equipment)
                    NavigationView {
                        VStack {
                            EquipmentList(equipment: equipmentForCategories, title: EquipmentCategory.concatenateEquipCategories(for: equipment))
                        }
                        .navigationBarItems(trailing: Button(action: {
                            selectedEquipment = nil
                            isShowingEquipmentList = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        })
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
        )
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
    }
    
    private var saveConfirmationView: some View {
        VStack {
            Text("Preferences Saved Successfully!")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .frame(width: 300, height: 100)
        .background(Color.clear)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale) // Smooth transition for showing/hiding
        .centerHorizontally()  // Extension method to center the view
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
    
    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private func saveChanges() {
        userData.roundingPreference[.platedMachines] = platedRounding
        userData.roundingPreference[.barsPlates] = platedRounding
        userData.roundingPreference[.weightMachines] = pinLoadedRounding
        userData.roundingPreference[.cableMachines] = pinLoadedRounding
        userData.roundingPreference[.smallWeights] = smallWeightsRounding
        userData.saveSingleVariableToFile(\.roundingPreference, for: .roundingPreference)
        toastManager.showSaveConfirmation()  // Trigger the notification
    }
}
