//
//  PlannedWorkoutTime.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


// Date only? or Date and Hour
// Notify how long before planned Time or Notify at Beginning of Day
// Select Default Workout Time
struct PlannedWorkoutTime: View {
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
            
            notificationSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Workout Time Settings", displayMode: .inline)
    }
    
    private var generalSection: some View {
        Section {
            VStack {
                Toggle("Date Only", isOn: $userData.settings.useDateOnly)
                    .onChange(of: userData.settings.useDateOnly) {
                        //userData.saveSingleStructToFile(\.settings, for: .settings)
                    }
                Text(userData.settings.useDateOnly ? "Notifications will be based on the date only." : "Notifications will include time of day.")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
            }
            
            VStack {
                // should be workout reminders?
                Toggle("Notify Before Workout", isOn: $userData.settings.notifyBeforePlannedTime)
                    .onChange(of: userData.settings.notifyBeforePlannedTime) {
                        //userData.saveSingleStructToFile(\.settings, for: .settings)
                    }
                
                Text(userData.settings.notifyBeforePlannedTime ? "You will be notified before the planned workout time." : "You will be dynamically notified the day of your workout.")
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
                                 //userData.saveSingleStructToFile(\.settings, for: .settings)
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
        Section(
            header: Text("Notification Settings"),
            footer:
                // Footer button to toggle picker visibility
                RectangularButton(
                    title: isPickerExpanded ? "Hide Picker" : "Add Notification Time",
                    systemImage: isPickerExpanded ? "xmark" : "plus",
                    color: isPickerExpanded ? .red : .blue,
                    action: {
                        isPickerExpanded.toggle()
                    }
                )
        ) {
            if userData.settings.useDateOnly {
                timeOfDaySection
            } else {
                intervalSection
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
    
    @ViewBuilder private var intervalSection: some View {
        Text("Set a reminder for an amount of time before your workout.")
            .multilineTextAlignment(.leading)
            .font(.subheadline)
        
        if isPickerExpanded {
            HStack {
                DurationPicker(time: $duration)
                Button(action: addInterval) {
                    HStack {
                        Text("Add")
                        Image(systemName: "checkmark")
                    }
                    .padding()
                    .background(buttonDisabled ? Color.gray : Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(buttonDisabled)
            }
            .padding(.vertical, 5)
        }
    }
    
    @ViewBuilder private var timeOfDaySection: some View {
        Text("Set a reminder for a time on the day of your workout.")
            .multilineTextAlignment(.leading)
            .font(.subheadline)
        
        if isPickerExpanded {
            ZStack {
                HStack {
                    DatePicker("Choose Time", selection: $draftTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.leading, -50)
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: addTime) {
                            HStack {
                                Text("Add")
                                Image(systemName: "checkmark")
                            }
                            .padding()
                            .background(buttonDisabled ? Color.gray : Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(buttonDisabled)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var intervalList: some View {
        Section {
            if userData.settings.notifications.intervals.isEmpty {
                Text("No Notification intervals set.")
                    .padding()
            }
            else {
                ForEach(userData.settings.notifications.intervals, id: \.self) { interval in
                    HStack {
                        Text(Format.formatDuration(Int(interval)))
                        Spacer()
                        Button(action: {
                            removeInterval(interval)
                        }) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        } header: {
            Text("Scheduled Notifications")
        }
    }
    
    private var timeOfDayList: some View {
        Section {
            if userData.settings.notifications.times.isEmpty {
                Text("No Notification times set.")
                    .padding()
            }
            else {
                ForEach(userData.settings.notifications.times, id: \.self) { time in
                    HStack {
                        Text("\(Format.formatTimeComponents(time))")
                        Spacer()
                        Button(action: {
                            removeTime(time)
                        }) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        } header: {
            Text("Scheduled Notifications")
        }
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
        save(shouldSave: added)
    }
    
    private func removeInterval(_ interval: TimeInterval) {
        let removed = userData.settings.notifications.removeInterval(interval)
        save(shouldSave: removed)
    }
    
    // MARK: - Time-of-day helpers
    private func addTime() {
        let added = userData.settings.notifications.addTime(components: components)
        isPickerExpanded = false
        save(shouldSave: added)
    }

    private func removeTime(_ comps: DateComponents) {
        let removed = userData.settings.notifications.removeTime(comps)
        save(shouldSave: removed)
    }
    
    private func save(shouldSave: Bool) {
        //if shouldSave { userData.saveSingleStructToFile(\.settings, for: .settings) }
    }
}
