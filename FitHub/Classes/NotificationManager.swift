import Foundation
import SwiftUI
import Combine
import UserNotifications


final class NotificationManager: ObservableObject {
    // ── singleton (easy to inject) ──────────────────────────────────
    @MainActor static let shared = NotificationManager()
    private init() { refreshStatus() }

    // published so UI toggles can bind to it
    @Published private(set) var isAuthorized: Bool = false

    static func scheduleNotification(for workoutTemplate: WorkoutTemplate, user: UserData) -> [String] {
        var notificationIDs: [String] = []
        let calendar = Calendar.current
        let now = Date() // Get the current date and time
        let categories: String = SplitCategory.concatenateCategories(for: workoutTemplate.categories)
        
        // Safely unwrap workoutTemplate.date
        guard let workoutDate = workoutTemplate.date else { return notificationIDs }
        
        // Check if notifications are allowed and if they should be scheduled before the planned time
        if !user.settings.allowedNotifications || !user.settings.notifyBeforePlannedTime { return notificationIDs }
        
        if user.settings.useDateOnly {
            if user.settings.notificationTimes.isEmpty {
                // Schedule notifications at 9 AM and 6 PM
                if let morningDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: workoutDate), morningDate > now {
                    notificationIDs.append(schedule(noti: Notification(
                        title: "You have a Workout Today!",
                        body: "You have a \(categories) workout today. Don't forget!",
                        triggerDate: morningDate,
                        workoutName: workoutTemplate.name)
                    ))
                } else {
                    print("🕒 Skipped 9 AM notification for \(workoutTemplate.name) – date has passed.")
                }
                
                if let eveningDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: workoutDate), eveningDate > now {
                    notificationIDs.append(schedule(noti: Notification(
                        title: "Workout Incomplete",
                        body: "There's still time to complete your \(categories) workout. You got this!",
                        triggerDate: eveningDate,
                        workoutName: workoutTemplate.name)
                    ))
                } else {
                    print("🕒 Skipped 6 PM notification for \(workoutTemplate.name) – date has passed.")
                }
            } else {
                for components in user.settings.notificationTimes {
                    var merged = calendar.dateComponents([.year, .month, .day], from: workoutDate)
                    merged.hour = components.hour
                    merged.minute = components.minute

                    if let scheduledDate = calendar.date(from: merged), scheduledDate > now {
                        notificationIDs.append(schedule(noti: Notification(
                            title: "Workout Reminder",
                            body: "You have a \(categories) workout today at \(Format.formatDate(scheduledDate, dateStyle: .none, timeStyle: .short)).",
                            triggerDate: scheduledDate,
                            workoutName: workoutTemplate.name
                        )))
                    } else {
                        print("🕒 Skipped \(Format.formatTimeComponents(components)) for \(workoutTemplate.name) – date has passed.")
                    }
                }
            }
        } else {
            if user.settings.notificationIntervals.isEmpty {
                // Default notifications (Workout time + 1 hour before)
                if workoutDate > now {
                    notificationIDs.append(schedule(noti: Notification(
                        title: "It's Workout Time!",
                        body: "Your \(categories) workout is now!",
                        triggerDate: workoutDate,
                        workoutName: workoutTemplate.name)
                    ))
                } else {
                    print("🕒 Skipped \(Format.formatDate(workoutDate, dateStyle: .none, timeStyle: .short)) notification for \(workoutTemplate.name) – date has passed.")
                }
                
                if let oneHourBeforeDate = calendar.date(byAdding: .hour, value: -1, to: workoutDate) {
                    if oneHourBeforeDate > now {
                        notificationIDs.append(schedule(noti: Notification(
                            title: "Upcoming Workout Reminder",
                            body: "Your \(categories) workout is in one hour. Get ready!",
                            triggerDate: oneHourBeforeDate,
                            workoutName: workoutTemplate.name)
                        ))
                    } else {
                        print("🕒 Skipped \(Format.formatDate(oneHourBeforeDate, dateStyle: .none, timeStyle: .short)) notification for \(workoutTemplate.name) – date has passed.")
                    }
                }
            } else {
                // Schedule notifications based on user's `notificationIntervals`
                for timeInterval in user.settings.notificationIntervals {
                    let notificationDate = workoutDate.addingTimeInterval(-timeInterval) // Subtract user-defined time
                    if notificationDate > now {
                        let formattedTime = Format.formatTimeInterval(timeInterval) // Helper function for formatting
                        notificationIDs.append(schedule(noti: Notification(
                            title: "Upcoming Workout Reminder",
                            body: "Your \(categories) workout is in \(formattedTime). Get ready!",
                            triggerDate: notificationDate,
                            workoutName: workoutTemplate.name)
                        ))
                    } else {
                        print("🕒 Skipped \(Format.formatDate(notificationDate, dateStyle: .none, timeStyle: .short)) notification for \(workoutTemplate.name) – date has passed.")
                    }
                }
            }
        }
        return notificationIDs
    }
    
    // MARK: – Writable binding for Toggle
    var toggleBinding: Binding<Bool> {
        Binding(
            get: { self.isAuthorized },
            set: { newVal in
                if newVal {
                    self.requestIfNeeded()
                } else {
                    self._removeAllPending()
                    Task { @MainActor in self.isAuthorized = false }
                }
            }
        )
    }
    
    // MARK: – Public API ––––––––––––––––––––––––––––––––––––––––––––
    
    static func printAllPendingNotifications() {
        MainActor.assumeIsolated {
            shared._printAllPendingNotifications()
        }
    }

    /// Ask only if the user hasn’t made a choice yet.
    func requestIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.requestPermission()
            } else {
                Task { @MainActor in
                    self.isAuthorized = settings.authorizationStatus == .authorized
                }
            }
        }
    }

    /// Force the system prompt.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in self.isAuthorized = granted }
            if let error { print("⚠️ Notification request failed:", error.localizedDescription) }
        }
    }

    static func schedule(noti: Notification) -> String {
        MainActor.assumeIsolated {
            return shared._schedule(noti: noti)
        }
    }

    static func remove(ids: [String]) {
        MainActor.assumeIsolated { shared._remove(ids: ids) }
    }

    static func removeAllPending() {
        MainActor.assumeIsolated { shared._removeAllPending() }
    }

    // ── INSTANCE HELPERS (no UI touches) ─────────────────────────
    // keep them private so the rest of the app must go through
    // the static wrappers
    private func _schedule(noti: Notification) -> String {
        let id  = noti.id
        let cal = Calendar.current
        let trg = UNCalendarNotificationTrigger(dateMatching: cal.dateComponents([.year,.month,.day,.hour,.minute], from: noti.triggerDate), repeats: false)

        let content = UNMutableNotificationContent()
        content.title = noti.title
        content.body  = noti.body
        content.sound = .default

        let req = UNNotificationRequest(identifier: id, content: content, trigger: trg)
        UNUserNotificationCenter.current().add(req) { err in
            if let err {
                print("⚠️ Couldn’t schedule:", err.localizedDescription)
            } else {
                print("✅ Scheduled '\(noti.title)' →", Format.formatDate(noti.triggerDate))
            }
        }
        return id
    }

    private func _remove(ids: [String]) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func _removeAllPending() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }
    
    /// Prints every pending UNNotificationRequest identifier to Xcode’s console.
    func _printAllPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier)
            Task { @MainActor in
                print("🔔 Pending notifications (\(ids.count)):", ids)
            }
        }
    }

    // MARK: – Private ––––––––––––––––––––––––––––––––––––––––––––––––
    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}

