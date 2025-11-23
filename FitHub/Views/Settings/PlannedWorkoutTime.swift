//
//  PlannedWorkoutTime.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// TODO: we should separate the interval and time logic into separate views
// Date only? or Date and Hour
// Notify how long before planned Time or Notify at Beginning of Day
// Select Default Workout Time
struct PlannedWorkoutTime: View {
    @ObservedObject var notifications = NotificationManager.shared
    @ObservedObject var userData: UserData
    @State private var duration: TimeSpan = .hrMinToSec(hours: 1, minutes: 0)
    @State private var isPickerExpanded: Bool = false
    @State private var draftTime: Date = Date()     // temp value
    @State private var selectedWorkoutTime: Date
    
    init(userData: UserData) {
        self.userData = userData
        let base = Date()
        if let t = userData.settings.defaultWorkoutTime,
           let h = t.hour, let m = t.minute {
            _selectedWorkoutTime = State(initialValue:
                CalendarUtility.shared.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
            )
        } else {
            _selectedWorkoutTime = State(initialValue: base)
        }
    }

    var body: some View {
        List {
            generalSection
            if userData.settings.workoutReminders {
                notificationSection
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Workout Time Settings", displayMode: .inline)
    }
    
    private var generalSection: some View {
        Section {
            VStack {
                Toggle("Notify Before Workout", isOn: $userData.settings.workoutReminders)
                Text(userData.settings.workoutReminders ? "You will be notified before your workout." : "No workout reminders will be sent.")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                if !notifications.isAuthorized, userData.settings.workoutReminders {
                    WarningFooter(message: "Must allow Notifications in Device Settings.")
                }
            }
            
            VStack {
                Toggle("Date Only", isOn: $userData.settings.useDateOnly)
                Text(userData.settings.useDateOnly ? "Notifications will be based on the date only." : "Notifications will include time of day.")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
            }
            
            if !userData.settings.useDateOnly {
                 VStack {
                     DatePicker(
                         "Select Default Workout Time",
                         selection: Binding<Date>(
                             get: {
                                 // build a date for today with stored H/M (or fallback to now)
                                 let base = Date()
                                 if let t = userData.settings.defaultWorkoutTime, let h = t.hour, let m = t.minute {
                                     return CalendarUtility.shared.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
                                 }
                                 return base
                             },
                             set: { newDate in
                                 // store *only* hour/minute (no seconds)
                                 let comps = CalendarUtility.shared.dateComponents([.hour, .minute], from: newDate)
                                 userData.settings.defaultWorkoutTime = comps
                             }
                         ),
                         displayedComponents: .hourAndMinute
                     )
                     .padding(.vertical, 5)
                     
                     Text("When generating a new workout, this time will be used as the default. You can change this time later.")
                         .multilineTextAlignment(.leading)
                         .font(.caption)
                 }
            }
        } header: {
            Text("General Settings")
        }
    }
    
    @ViewBuilder private var notificationSection: some View {
        Section {
            if userData.settings.useDateOnly {
                pickerSection(
                    description: "Set a reminder for a time on the day of your workout.",
                    pickerContent: {
                        DatePicker("", selection: $draftTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                )
            } else {
                pickerSection(
                    description: "Set a reminder for an amount of time before your workout.",
                    pickerContent: {
                        DurationPicker(time: $duration)
                    }
                )
            }
        } header: {
            Text("Notification Settings")
        } footer: {
            HStack {
                // Footer button to toggle picker visibility
                RectangularButton(
                    title: isPickerExpanded ? "Hide Picker" : "Add Notification Time",
                    systemImage: isPickerExpanded ? "xmark" : "plus",
                    bgColor: isPickerExpanded ? .red : .blue,
                    width: .fill,
                    action: {
                        isPickerExpanded.toggle()
                    }
                )
                if isPickerExpanded {
                    RectangularButton(
                        title: "Add",
                        systemImage: "checkmark",
                        enabled: !buttonDisabled,
                        bgColor: buttonDisabled ? Color.gray : Color.green,
                        width: .fill,
                        action: {
                            userData.settings.useDateOnly ? addTime() : addInterval()
                        }
                    )
                }
            }
        }
        
        if userData.settings.useDateOnly {
            //  A)  Absolute time-of-day notifications
            timeOfDayList
        } else {
            //  B)  Relative notifications (seconds BEFORE workout)
            intervalList
        }
    }
    
    private var intervalList: some View {
        notificationSection(
            items: userData.settings.notifications.intervals,
            emptyText: "No Notification intervals set.",
            header: "Scheduled Notifications",
            label: { interval in
                Text(Format.formatDuration(Int(interval)))
            },
            onDelete: { interval in
                removeInterval(interval)
            }
        )
    }

    private var timeOfDayList: some View {
        notificationSection(
            items: userData.settings.notifications.times,
            emptyText: "No Notification times set.",
            header: "Scheduled Notifications",
            label: { time in
                Text(Format.formatTimeComponents(time))
            },
            onDelete: { time in
                removeTime(time)
            }
        )
    }
    
    private var totalSeconds: Int { duration.inSeconds }
        
    private var components: DateComponents {
        return CalendarUtility.shared.dateComponents([.hour, .minute], from: draftTime)
    }
    
    private var buttonDisabled: Bool {
        return userData.settings.useDateOnly
            ? userData.settings.notifications.contains(components)
            : totalSeconds == 0 || userData.settings.notifications.contains(TimeInterval(totalSeconds))
    }
    
    private func addInterval() {
        let added = userData.settings.notifications.addInterval(totalSeconds: totalSeconds)
        if added { duration = .hrMinToSec(hours: 1, minutes: 0) }
        isPickerExpanded = false
    }
    
    private func removeInterval(_ interval: TimeInterval) {
        _ = userData.settings.notifications.removeInterval(interval)
    }
    
    // MARK: - Time-of-day helpers
    private func addTime() {
        _ = userData.settings.notifications.addTime(components: components)
        isPickerExpanded = false
    }

    private func removeTime(_ comps: DateComponents) {
        _ = userData.settings.notifications.removeTime(comps)
    }
}

private extension PlannedWorkoutTime {
    // MARK: - Generic helpers
    @ViewBuilder private func pickerSection<Content: View>(
        description: String,
        @ViewBuilder pickerContent: () -> Content
    ) -> some View {
        Text(description)
            .multilineTextAlignment(.leading)
            .font(.subheadline)
        
        if isPickerExpanded {
            pickerContent()
                .padding(.vertical, 5)
        }
    }
    
    private func notificationSection<Item: Hashable, Label: View>(
        items: [Item],
        emptyText: String,
        header: String,
        @ViewBuilder label: @escaping (Item) -> Label,
        onDelete: @escaping (Item) -> Void
    ) -> some View {
        Section {
            if items.isEmpty {
                Text(emptyText)
                    .padding()
            } else {
                ForEach(items, id: \.self) { item in
                    HStack {
                        label(item)
                        Spacer()
                        Button {
                            onDelete(item)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        } header: {
            Text(header)
        }
    }
}
