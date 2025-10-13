//
//  DaysEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// must change to account for more day options
struct DaysEditor: View {
    @Environment(\.dismiss) private var dismiss 
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @Binding var selectedDays: [DaysOfWeek]
    @Binding var numDays: Int
    @State private var showingAlert = false // State variable for showing the alert
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(DaysOfWeek.allCases, id: \.self) { day in
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
                                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                
                                Spacer()
                                if selectedDays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Deselect All") {
                        selectedDays.removeAll() // Clear all selected days
                    }
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        if selectedDays.count != numDays, selectedDays.count >= 3 {
                            numDays = selectedDays.count
                        }
                        // Closes the view
                        dismiss() // Dismiss the view
                    }
                }
            }
        }
    }
}
