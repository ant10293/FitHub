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
    @State private var selectedHours: Int = 1
    @State private var selectedMinutes: Int = 0
    @State private var isPickerExpanded: Bool = false
    @State private var draftTime       = Date()     // temp value
    @State private var selectedWorkoutTime: Date
    
    init(userData: UserData) {
        self.userData = userData
        // Initialize `selectedWorkoutTime` with `defaultWorkoutTime` or fallback to current date.
        _selectedWorkoutTime = State(initialValue: userData.settings.defaultWorkoutTime ?? Date())
    }
    
    var body: some View {
        List {
            generalSection
            
            notificationSection
            
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Workout Time Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var generalSection: some View {
        Section {
            VStack {
                Toggle("Date Only", isOn: $userData.settings.useDateOnly)
                    .onChange(of: userData.settings.useDateOnly) {
                        userData.saveSingleStructToFile(\.settings, for: .settings)
                    }
                Text(userData.settings.useDateOnly ? "Notifications will be based on the date only." : "Notifications will include time of day.")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    //.foregroundColor(.gray)
            }
            
            VStack {
                // should be workout reminders?
                Toggle("Notify Before Workout", isOn: $userData.settings.notifyBeforePlannedTime)
                    .onChange(of: userData.settings.notifyBeforePlannedTime) {
                        userData.saveSingleStructToFile(\.settings, for: .settings)
                    }
                
                Text(userData.settings.notifyBeforePlannedTime ? "You will be notified before the planned workout time." : "You will be dynamically notified the day of your workout.")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    //.foregroundColor(.gray)
            }
            
            if !userData.settings.useDateOnly {
                 VStack {
                     DatePicker("Select Default Workout Time", selection: Binding(
                        get: { selectedWorkoutTime },
                        set: { newDate in
                            selectedWorkoutTime = newDate
                            userData.settings.defaultWorkoutTime = newDate
                            userData.saveSingleStructToFile(\.settings, for: .settings)
                        }
                     ), displayedComponents: .hourAndMinute)
                     .padding(.vertical, 5)
                     
                     Text("When generating a new workout, this time will be used as the default. You can change this time later.")
                         .multilineTextAlignment(.leading)
                         .font(.subheadline)
                         .foregroundColor(.gray)
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
                ActionButton(
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
            //.foregroundColor(.gray)
        
        if isPickerExpanded {
            HStack {
                Picker("Hours", selection: $selectedHours) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour) hr").tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
                .clipped()
                
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
                .clipped()
                
                Button(action: addInterval) {
                    HStack {
                        Text("Add")
                        Image(systemName: "checkmark")
                    }
                    .padding()
                    .background(ButtonDisabled() ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(ButtonDisabled())
            }
            .padding(.vertical, 5)
        }
    }
    
    @ViewBuilder private var timeOfDaySection: some View {
        Text("Set a reminder for a time on the day of your workout.")
            .multilineTextAlignment(.leading)
            .font(.subheadline)
            .foregroundColor(.gray)
        
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
                            .background(ButtonDisabled() ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(ButtonDisabled())
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var intervalList: some View {
        Section {
            if userData.settings.notificationIntervals.isEmpty {
                Text("No Notification intervals set.")
                    .padding()
            }
            else {
                ForEach(userData.settings.notificationIntervals, id: \.self) { interval in
                    let hours = Int(interval) / 3600
                    let minutes = (Int(interval) % 3600) / 60
                    HStack {
                        if minutes == 0 {
                            Text("\(hours) hr Before Workout")
                        }
                        else if hours == 0 {
                            Text("\(minutes) min Before Workout")
                        }
                        else {
                            Text("\(hours) hr \(minutes) min Before Workout")
                        }
                        Spacer()
                        Button(action: {
                            removeInterval(interval)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
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
            if userData.settings.notificationTimes.isEmpty {
                Text("No Notification times set.")
                    .padding()
            }
            else {
                ForEach(userData.settings.notificationTimes, id: \.self) { time in
                    HStack {
                        Text("\(Format.formatTimeComponents(time))")
                        Spacer()
                        Button(action: {
                            removeTime(time)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        } header: {
            Text("Scheduled Notifications")
        }
    }
    
    var totalSeconds: Int { return (selectedHours * 3600) + (selectedMinutes * 60) }
    
    var components: DateComponents {
        return Calendar.current.dateComponents([.hour, .minute], from: draftTime)
    }
    
    private func ButtonDisabled() -> Bool {
        return userData.settings.useDateOnly
            ? userData.settings.notificationTimes.contains(components)
            : totalSeconds == 0 || userData.settings.notificationIntervals.contains(TimeInterval(totalSeconds))
    }
    
    private func addInterval() {
        guard !userData.settings.notificationIntervals.contains(TimeInterval(totalSeconds)) else {
            isPickerExpanded = false; return
        }
        if totalSeconds > 0 {
            userData.settings.notificationIntervals.append(TimeInterval(totalSeconds))
            userData.settings.notificationIntervals.sort() // Sort to ensure times are in ascending order
            selectedHours = 1 // Reset to default 1 hour
            selectedMinutes = 0 // Reset to 0 minutes
            isPickerExpanded = false // Collapse picker after adding
            userData.saveSingleStructToFile(\.settings, for: .settings)
        }
    }
    
    private func removeInterval(_ interval: TimeInterval) {
        if let index = userData.settings.notificationIntervals.firstIndex(of: interval) {
            userData.settings.notificationIntervals.remove(at: index)
            userData.saveSingleStructToFile(\.settings, for: .settings)
        }
    }
    
    // MARK: - Time-of-day helpers
    private func addTime() {
        guard !userData.settings.notificationTimes.contains(components) else {
            isPickerExpanded = false; return
        }
        userData.settings.notificationTimes.append(components)
        userData.settings.notificationTimes.sort { ($0.hour ?? 0, $0.minute ?? 0) < ($1.hour ?? 0, $1.minute ?? 0) }
        userData.saveSingleStructToFile(\.settings, for: .settings)
        isPickerExpanded = false
    }

    private func removeTime(_ comps: DateComponents) {
        userData.settings.notificationTimes.removeAll { $0 == comps }
        userData.saveSingleStructToFile(\.settings, for: .settings)
    }
}
