//
//  RestPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct RestPicker: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    var frameWidth: CGFloat
    
    var body: some View {
        HStack {
            Picker(selection: $minutes, label: Text("")) {
                ForEach(0..<60, id: \.self) { i in
                    Text("\(i)")
                        .monospacedDigit()
                        .tag(i)
                        .frame(maxWidth: .infinity, alignment: .center) // Center-align each value
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: frameWidth)
            .overlay(
                Text("min").bold()
                    .foregroundColor(.gray)
                    .offset(x: -15), // Adjust the vertical offset to align with the picker
                alignment: .trailing
            )
            
            Picker(selection: $seconds, label: Text("")) {
                ForEach(0..<60, id: \.self) { i in
                    Text("\(i)")
                        .monospacedDigit()
                        .tag(i)
                        .frame(maxWidth: .infinity, alignment: .center) // Center-align each value
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: frameWidth)
            .overlay(
                Text("sec").bold()
                    .foregroundColor(.gray)
                    .offset(x: -15), // Adjust the vertical offset to align with the picker
                alignment: .trailing
            )
        }
    }
}
