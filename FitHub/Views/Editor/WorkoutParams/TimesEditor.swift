//
//  TimesEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/22/25.
//

import SwiftUI


struct TimesEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    let days: [DaysOfWeek]

    var body: some View {
        NavigationStack {
            List {
                ForEach(days, id: \.self) { day in
                    HStack {
                        Text(day.rawValue)
                        Spacer()
                        DatePicker(
                            "",
                            selection: binding(for: day),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitle("Workout Times", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        userData.workoutPrefs.customWorkoutTimes = nil
                    }
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Fallback time used when no custom is set yet
    private var defaultComponents: DateComponents {
        userData.settings.defaultWorkoutTime ?? DateComponents(hour: 11, minute: 0)
    }

    private func binding(for day: DaysOfWeek) -> Binding<Date> {
        Binding<Date>(
            get: {
                let comps = effectiveComponents(for: day)
                return date(from: comps)
            },
            set: { newDate in
                var custom = userData.workoutPrefs.customWorkoutTimes ?? WorkoutTimes(distribution: [:])
                let hm = CalendarUtility.shared.dateComponents([.hour, .minute], from: newDate)
                custom.modify(for: day, with: hm)
                userData.workoutPrefs.customWorkoutTimes = custom
            }
        )
    }

    // MARK: - Helpers

    private func effectiveComponents(for day: DaysOfWeek) -> DateComponents {
        if let custom = userData.workoutPrefs.customWorkoutTimes?.time(for: day) {
            return custom
        }
        return defaultComponents // use defaultWorkoutTime if available, else 00:00
    }

    private func date(from comps: DateComponents) -> Date {
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        let base = CalendarUtility.shared.startOfDay(for: Date())
        
        return CalendarUtility.shared.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
    }
}
