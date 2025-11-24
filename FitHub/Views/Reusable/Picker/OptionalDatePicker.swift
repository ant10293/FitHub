//
//  OptionalDatePicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/23/25.
//
import SwiftUI

/// uses compact picker style
struct OptionalDatePicker: View {
    @State private var showDatePicker: Bool
    @State private var date: Date?
    let label: String
    let useDateOnly: Bool
    let onDateChange: (Date?) -> Void

    init(
        initialDate: Date? = nil,
        label: String,
        useDateOnly: Bool,
        onDateChange: @escaping (Date?) -> Void
    ) {
        _showDatePicker = State(initialValue: initialDate != nil)
        _date = State(initialValue: initialDate)
        self.label = label
        self.useDateOnly = useDateOnly
        self.onDateChange = onDateChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: toggleDatePicker) {
                    Label(
                        label,
                        systemImage: showDatePicker ? "checkmark.square" : "square"
                    )
                    .font(.headline)
                }
                .foregroundStyle(showDatePicker ? .primary : .secondary)

                Spacer()
            }

            if showDatePicker {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { resolvedDate },
                        set: { newValue in
                            date = newValue
                            onDateChange(newValue)
                        }
                    ),
                    displayedComponents: useDateOnly ? .date : [.date, .hourAndMinute]
                )
                .datePickerStyle(CompactDatePickerStyle())
                .padding(.trailing)
            }
        }
    }

    private func toggleDatePicker() {
        showDatePicker.toggle()

        if showDatePicker {
            // turning ON: ensure we have a date, notify
            let newDate = resolvedDate
            date = newDate
            onDateChange(newDate)
        } else {
            // turning OFF: clear date, notify with nil
            date = nil
            onDateChange(nil)
        }
    }
    
    var resolvedDate: Date {
        let date = date ?? Date()
        if useDateOnly {
            return CalendarUtility.shared.startOfDay(for: date)
        }
        return date
    }
}
