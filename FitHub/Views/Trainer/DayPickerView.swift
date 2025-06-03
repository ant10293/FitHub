//
//  DayPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// must change to account for more day options
struct DayPickerView: View {
    @Binding var selectedDays: [daysOfWeek]
    @Binding var numDays: Int
   // var startDay: daysOfWeek
    @Environment(\.presentationMode) var presentationMode // Access to the presentation mode
    @State private var showingAlert = false // State variable for showing the alert
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Days of the Week")
                    .font(.subheadline) // Explicitly set the font style
                    .foregroundColor(.gray) // Ensure the color is consistent
                ) {
                    ForEach(daysOfWeek.allCases, id: \.self) { day in
                        Button(action: {
                            if let index = selectedDays.firstIndex(of: day) {
                                selectedDays.remove(at: index)
                            } else if selectedDays.count < 6 {
                                selectedDays.append(day)
                                selectedDays.sort() // Sort after adding a new day
                               /* selectedDays.sort(by: { lhs, rhs in
                                    sortDays(lhs, rhs, startDay: .monday)
                                                       })*/
                            }
                        }) {
                            HStack {
                                Text(day.rawValue)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                
                                Spacer()
                                if selectedDays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Select Days", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Deselect All") {
                        selectedDays.removeAll() // Clear all selected days
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if selectedDays.count != numDays, selectedDays.count >= 3 {
                            numDays = selectedDays.count
                        }
                        // Closes the view
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    }
                }
            }
        }
    }
    // Compare two days based on a user-dependent startDay
    /*func sortDays(_ lhs: daysOfWeek, _ rhs: daysOfWeek, startDay: daysOfWeek) -> Bool {
           // Rotate the base array so that 'startDay' is first
           let reordered = daysOfWeek.orderedDays(startingOn: startDay)
           guard let li = reordered.firstIndex(of: lhs),
                 let ri = reordered.firstIndex(of: rhs) else {
               return false
           }
           return li < ri
       }*/
}
