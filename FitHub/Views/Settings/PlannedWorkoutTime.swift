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
    @State private var selectedWorkoutTime: Date
    
    init(userData: UserData) {
        self.userData = userData
        // Initialize `selectedWorkoutTime` with `defaultWorkoutTime` or fallback to current date.
        _selectedWorkoutTime = State(initialValue: userData.defaultWorkoutTime ?? Date())
    }
    
    var body: some View {
        List {
            Section(header: Text("General Settings")) {
                VStack {
                    Toggle("Date Only", isOn: $userData.useDateOnly)
                        .onChange(of: userData.useDateOnly) {
                            userData.saveSingleVariableToFile(\.useDateOnly, for: .useDateOnly)
                            // if useDateOnly, set defaultWorkoutTime to nil
                            /*if userData.useDateOnly {
                                userData.defaultWorkoutTime = nil
                                userData.saveSingleVariableToFile(\.defaultWorkoutTime, for: .defaultWorkoutTime)
                            }*/
                        }
                    Text(userData.useDateOnly ? "Notifications will be based on the date only." : "Notifications will include time of day.")
                        .multilineTextAlignment(.leading)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    // should be workout reminders?
                    Toggle("Notify Before Workout", isOn: $userData.notifyBeforePlannedTime)
                        .onChange(of: userData.notifyBeforePlannedTime) {
                            userData.saveSingleVariableToFile(\.notifyBeforePlannedTime, for: .notifyBeforePlannedTime)
                        }
                    
                    Text(userData.notifyBeforePlannedTime ? "You will be notified before the planned workout time." : "You will be dynamically notified the day of your workout.")
                        .multilineTextAlignment(.leading)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                /* if !userData.useDateOnly {
                 DatePicker("Select Default Workout Time", selection: Binding(
                 get: { selectedWorkoutTime },
                 set: { newDate in
                 selectedWorkoutTime = newDate
                 userData.defaultWorkoutTime = newDate
                 userData.saveSingleVariableToFile(\.defaultWorkoutTime, for: .defaultWorkoutTime)
                 }
                 ), displayedComponents: .hourAndMinute)
                 .padding(.vertical, 5)
                 }*/
            }
            
            if !userData.useDateOnly {
                Section(header: Text("Notification Settings")) {
                    Text("Set a reminder for an amount of time before your workout.")
                        .multilineTextAlignment(.leading)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        // withAnimation {
                        isPickerExpanded.toggle()
                        // }
                    }) {
                        HStack {
                            Text(isPickerExpanded ? "Hide Picker" : "Add Notification Time")
                            Image(systemName: isPickerExpanded ? "xmark" : "plus")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isPickerExpanded ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
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
                            
                            Button(action: addNotificationTime) {
                                HStack {
                                    Text("Add")
                                    Image(systemName: "checkmark")
                                }
                                .padding()
                                .background(ButtonDisabled() ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }.disabled(ButtonDisabled())
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                if !isPickerExpanded {
                    Section(header: Text("Scheduled Notifications")) {
                        if userData.notificationTimes.isEmpty {
                            List {
                                Text("No Notifications Scheduled.")
                                    .padding()
                            }
                            .frame(minHeight: 150)
                        }
                        else {
                            ForEach(userData.notificationTimes, id: \.self) { time in
                                let hours = Int(time) / 3600
                                let minutes = (Int(time) % 3600) / 60
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
                                        removeNotificationTime(time)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Workout Time Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func ButtonDisabled() -> Bool {
        return selectedHours == 0 && selectedMinutes == 0
    }
    
    private func addNotificationTime() {
        let totalSeconds = (selectedHours * 3600) + (selectedMinutes * 60)
        if totalSeconds > 0 && !userData.notificationTimes.contains(TimeInterval(totalSeconds)) {
            userData.notificationTimes.append(TimeInterval(totalSeconds))
            userData.notificationTimes.sort() // Sort to ensure times are in ascending order
            selectedHours = 1 // Reset to default 1 hour
            selectedMinutes = 0 // Reset to 0 minutes
            isPickerExpanded = false // Collapse picker after adding
            userData.saveSingleVariableToFile(\.notificationTimes, for: .notificationTimes)
        }
    }
    
    private func removeNotificationTime(_ time: TimeInterval) {
        if let index = userData.notificationTimes.firstIndex(of: time) {
            userData.notificationTimes.remove(at: index)
            userData.saveSingleVariableToFile(\.notificationTimes, for: .notificationTimes)
        }
    }
}
