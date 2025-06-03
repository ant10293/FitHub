//
//  UnitSelection.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct UnitSelection: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack {
            Picker("Unit of Measurement", selection: $userData.measurementUnit) {
                ForEach(UnitOfMeasurement.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            Text(userData.measurementUnit.desc)
                .foregroundColor(.gray)
        }
        .navigationTitle("Unit Selection").navigationBarTitleDisplayMode(.inline)
    }
}
