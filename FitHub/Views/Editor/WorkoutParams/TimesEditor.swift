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
    var days: [DaysOfWeek]
    @Environment(\.calendar) private var calendar

    // Fallback time used when no custom is set yet
    private var defaultComponents: DateComponents {
        userData.settings.defaultWorkoutTime ?? DateComponents(hour: 11, minute: 0)
    }

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
            .onDisappear { persist() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        userData.workoutPrefs.customWorkoutTimes = nil
                        persist()
                    }
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Bindings

    private func binding(for day: DaysOfWeek) -> Binding<Date> {
        Binding<Date>(
            get: {
                let comps = effectiveComponents(for: day)
                return date(from: comps)
            },
            set: { newDate in
                var custom = userData.workoutPrefs.customWorkoutTimes ?? WorkoutTimes(distribution: [:])
                let hm = calendar.dateComponents([.hour, .minute], from: newDate)
                custom.modify(for: day, with: hm)
                userData.workoutPrefs.customWorkoutTimes = custom
                persist()
            }
        )
    }

    // MARK: - Helpers

    private func effectiveComponents(for day: DaysOfWeek) -> DateComponents {
        if let custom = userData.workoutPrefs.customWorkoutTimes?.time(for: day) {
            return custom
        }
        // use defaultWorkoutTime if available, else 00:00
        return defaultComponents
    }

    private func date(from comps: DateComponents) -> Date {
        let base = calendar.startOfDay(for: Date())
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        return calendar.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
    }

    private func persist() {
        //userData.saveToFile()
    }
}
