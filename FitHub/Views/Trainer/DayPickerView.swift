//
//  DayPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// must change to account for more day options
struct DayPickerView: View {
    @Environment(\.presentationMode) var presentationMode // Access to the presentation mode
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @Binding var selectedDays: [daysOfWeek]
    @Binding var numDays: Int
    @State private var showingAlert = false // State variable for showing the alert
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(daysOfWeek.allCases, id: \.self) { day in
                        Button(action: {
                            if let index = selectedDays.firstIndex(of: day) {
                                selectedDays.remove(at: index)
                            } else if selectedDays.count < 6 {
                                selectedDays.append(day)
                                selectedDays.sort() // Sort after adding a new day
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
                } header: {
                    Text("Days of the Week")
                        .font(.subheadline)
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
}
