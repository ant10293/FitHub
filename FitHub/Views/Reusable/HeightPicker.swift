//
//  HeightPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct HeightPicker: View {
    @Binding var feet: Int
    @Binding var inches: Int
    
    // Provide default ranges for feet and inches,
    // but you could make these parameters if you want extra configurability.
    let feetRange: ClosedRange<Int> = 4...7
    let inchRange: Range<Int> = 0..<12

    var body: some View {
        HStack {
            Picker("Feet", selection: $feet) {
                ForEach(feetRange, id: \.self) { footValue in
                    Text("\(footValue)").tag(footValue)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .overlay(
                Text("ft").bold()
                    .foregroundColor(.gray)
                    .offset(x: -50),
                alignment: .trailing
            )
            
            Picker("Inches", selection: $inches) {
                ForEach(inchRange, id: \.self) { inchValue in
                    Text("\(inchValue)").tag(inchValue)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .overlay(
                Text("in").bold()
                    .foregroundColor(.gray)
                    .offset(x: -45),
                alignment: .trailing
            )
        }
    }
}
